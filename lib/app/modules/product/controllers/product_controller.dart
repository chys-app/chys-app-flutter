import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/payment_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as th;

import '../../../services/short_message_utils.dart';

class ProductController extends GetxController {
  // Constants for better maintainability
  static const int MAX_MEDIA_FILES = 5;
  static const int MAX_VIDEO_DURATION_SECONDS = 30;
  static const int MAX_FILE_SIZE_MB = 100;
  
  final CustomApiService _apiService = Get.put(CustomApiService());
  final descriptionController = TextEditingController();
  final selectedMedia = <File>[].obs;
  final isLoading = false.obs;
  RxString selectedType = "Product".obs;
  RxBool showEmojiPicker = false.obs;
  CameraController? cameraController;
  RxBool isCameraInitialized = false.obs;
  RxBool isRecording = false.obs;
  Rx<File?> cameraPreviewFile = Rx<File?>(null);
  List<CameraDescription> cameras = [];
  RxInt selectedCameraIndex = 0.obs;
  final Map<File, String?> videoThumbnails = {};
  Subscription? _compressionSubscription;
  Timer? _recordingTimer;
  RxInt recordingDuration = 0.obs;
  final MapController mapController = Get.find<MapController>();

  // Single product preview state
  final Rxn<Products> singleProduct = Rxn<Products>();
  final RxBool isSingleProductLoading = false.obs;
  final RxInt currentIndex = 0.obs;
  final RxMap<String, VideoPlayerController> videoControllers =
      <String, VideoPlayerController>{}.obs;
  final RxMap<String, bool> isVideoInitialized = <String, bool>{}.obs;

  final TextEditingController commentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final Map<String, Products> _singleProductCache = {};
  final Map<String, DateTime> _singleProductCacheTimestamps = {};
  static const Duration _singleProductCacheDuration = Duration(minutes: 5);
  
  // Progress tracking variables
  RxDouble uploadProgress = 0.0.obs;
  RxString uploadStatus = "".obs;
  RxBool isUploading = false.obs;
  RxInt totalFiles = 0.obs;
  RxInt processedFiles = 0.obs;

  int get mediaCount => selectedMedia.length;
  bool get canAddMoreMedia => mediaCount < MAX_MEDIA_FILES;

  bool _isSingleProductCacheValid(String key) {
    if (!_singleProductCacheTimestamps.containsKey(key)) {
      return false;
    }
    final timestamp = _singleProductCacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _singleProductCacheDuration;
  }

  Future<void> fetchSingleProduct(String productId, {bool forceRefresh = false}) async {
    final cacheKey = 'single_product_$productId';

    try {
      if (!forceRefresh && _isSingleProductCacheValid(cacheKey)) {
        final cached = _singleProductCache[cacheKey];
        if (cached != null) {
          singleProduct.value = cached;
          return;
        }
      }

      isSingleProductLoading.value = true;
      final response = await _apiService.getRequest('products/$productId');
      if (response == null) {
        singleProduct.value = null;
        return;
      }

      final product = Products.fromMap(response);
      singleProduct.value = product;
      _singleProductCache[cacheKey] = product;
      _singleProductCacheTimestamps[cacheKey] = DateTime.now();
    } catch (e) {
      log('Error fetching product $productId: $e');
      final cached = _singleProductCache[cacheKey];
      if (cached != null) {
        singleProduct.value = cached;
      } else {
        singleProduct.value = null;
      }
    } finally {
      isSingleProductLoading.value = false;
    }
  }

  Future<void> refreshSingleProduct(String productId) async {
    await fetchSingleProduct(productId, forceRefresh: true);
  }

  Future<void> addProductView(String productId) async {
    try {
      await _apiService.postRequest('products/$productId/view', {});
    } catch (e) {
      log('Error adding product view: $e');
    }
  }

  Future<void> likeSingleProduct() async {
    final product = singleProduct.value;
    if (product == null) return;

    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }

    final profile = Get.find<ProfileController>().profile.value;
    final userId = profile?.id;
    if (userId == null) return;

    final normalizedLikes = product.likes.map((like) {
      if (like is Map && like.containsKey('_id')) {
        return like['_id'];
      }
      return like;
    }).toList();

    product.likes.value = normalizedLikes;

    final wasLiked = product.likes.contains(userId);
    product.isCurrentUserLiked = !wasLiked;

    if (wasLiked) {
      product.likes.remove(userId);
    } else {
      product.likes.add(userId);
    }

    singleProduct.refresh();

    try {
      await _apiService.postRequest('products/${product.id}/like', {});
    } catch (e) {
      // revert
      product.isCurrentUserLiked = wasLiked;
      if (wasLiked) {
        product.likes.add(userId);
      } else {
        product.likes.remove(userId);
      }
      singleProduct.refresh();
      log('Error liking product: $e');
    }
  }

  Future<void> shareProduct(Products product) async {
    try {
      final String description = product.description;
      final mediaUrl = product.media.isNotEmpty ? product.media.first : null;

      String content = description;
      if (product.creator.name.isNotEmpty) {
        content += '\n\nShared from ${product.creator.name} on CHYS';
      }

      XFile? previewFile;
      if (mediaUrl != null) {
        final response = await http.get(Uri.parse(mediaUrl));
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/product_preview_share.jpg');
        await file.writeAsBytes(bytes);
        previewFile = XFile(file.path);
      }

      await Share.shareXFiles(
        previewFile != null ? [previewFile] : [],
        text: content,
      );
    } catch (e) {
      log('Error sharing product: $e');
      ShortMessageUtils.showError('Failed to share product');
    }
  }

  Future<void> fundProduct(Products product, BuildContext context) async {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      ShortMessageUtils.showError('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ShortMessageUtils.showError('Enter a valid amount');
      return;
    }

    try {
      Get.find<LoadingController>().show();
      await PaymentServices.stripePayment(amountText, 'product_${product.id}', context,
          onSuccess: () async {
        try {
          await _apiService.postRequest('products/${product.id}/fund', {
            'amount': amountText,
          });
          product.isFunded.value = true;
          product.fundCount.value += amount.toInt();
          singleProduct.refresh();
          ShortMessageUtils.showSuccess('Thank you for funding!');
        } catch (apiError) {
          log('Error updating fund status: $apiError');
          ShortMessageUtils.showError('Failed to complete funding.');
        }
      });
    } catch (e) {
      log('Error during funding: $e');
      ShortMessageUtils.showError('Failed to process funding');
    } finally {
      Get.find<LoadingController>().hide();
    }
  }

  void showCommentsBottomSheet(Products product) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: Get.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () => Get.back(),
                  child: const Icon(Icons.cancel, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(() {
                if (product.comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet.'),
                  );
                }
                return ListView.separated(
                  itemCount: product.comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, index) {
                    final comment = product.comments[index];
                    final user = comment['user'] ?? {};
                    final username = (user['name'] ?? 'User').toString();
                    final message = (comment['message'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(message),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) {
                        final text = v.trim();
                        if (text.isEmpty) return;
                        commentOnProduct(product, text);
                        commentController.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: () {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;
                      commentOnProduct(product, text);
                      commentController.clear();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> commentOnProduct(Products product, String message) async {
    if (message.trim().isEmpty) {
      return;
    }

    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }

    final profile = Get.find<ProfileController>().profile.value;
    final comment = {
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
      'user': {
        '_id': profile?.id ?? '',
        'name': profile?.name ?? 'Unknown',
        'profilePic': profile?.profilePic ?? '',
      },
      '_id': UniqueKey().toString(),
    };

    product.comments.add(comment);
    singleProduct.refresh();

    try {
      await _apiService.postRequest('products/${product.id}/comment', {
        'message': message,
      });
    } catch (e) {
      log('Error adding comment: $e');
      product.comments.remove(comment);
      singleProduct.refresh();
      ShortMessageUtils.showError('Failed to add comment');
    }
  }

  Future<void> initializeVideoController(String url) async {
    if (videoControllers.containsKey(url)) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    videoControllers[url] = controller;
    isVideoInitialized[url] = true;
    controller.addListener(() {
      isVideoInitialized[url] = controller.value.isInitialized;
    });
  }

  void disposeVideoController(String url) {
    videoControllers[url]?.dispose();
    videoControllers.remove(url);
    isVideoInitialized.remove(url);
  }

  void pauseAllVideos() {
    for (final controller in videoControllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void setType(String type) {
    selectedType.value = type;
  }

  void resetType() {
    log("Come here");
    selectedType.value = "Product";
  }

  Future<void> flipCamera() async {
    log("Flip camera called. Available cameras: ${cameras.length}");

    if (cameras.length <= 1) {
      log("No additional cameras available for flipping");
      ShortMessageUtils.showError('No additional cameras available');
      return;
    }

    try {
      log("Starting camera flip from index ${selectedCameraIndex.value}");

      // Set camera as not initialized during transition
      isCameraInitialized.value = false;

      // Increment the index and wrap around if needed
      selectedCameraIndex.value =
          (selectedCameraIndex.value + 1) % cameras.length;

      log("Switching to camera index: ${selectedCameraIndex.value}");

      // Dispose current camera controller
      await cameraController?.dispose();
      log("Previous camera controller disposed");

      // Create new camera controller
      cameraController = CameraController(
        cameras[selectedCameraIndex.value],
        ResolutionPreset.medium,
        enableAudio: true,
      );

      log("New camera controller created for camera: ${cameras[selectedCameraIndex.value].name}");

      // Initialize the new camera
      await cameraController!.initialize();
      isCameraInitialized.value = true;

      log("Camera flipped successfully to index: ${selectedCameraIndex.value}");
    } catch (e) {
      log("Error during camera flip: $e");
      isCameraInitialized.value = false;
      ShortMessageUtils.showError('Failed to switch camera: $e');

      // Try to reinitialize with the previous camera
      try {
        log("Attempting to reinitialize with previous camera");
        selectedCameraIndex.value = (selectedCameraIndex.value - 1) % cameras.length;
        await initializeCamera(selectedCameraIndex.value);
      } catch (reinitError) {
        log("Failed to reinitialize camera: $reinitError");
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      cameras = await availableCameras();
      log("Available cameras: ${cameras.length}");

      // Log camera details for debugging
      for (int i = 0; i < cameras.length; i++) {
        log("Camera $i: ${cameras[i].name} (${cameras[i].lensDirection})");
      }

      if (cameras.isNotEmpty) {
        log("Initializing camera at index: ${selectedCameraIndex.value}");
        await initializeCamera(selectedCameraIndex.value);
      } else {
        log("No cameras available");
        ShortMessageUtils.showError('No cameras available on this device');
      }
    } catch (e) {
      log("Error initializing cameras: $e");
      ShortMessageUtils.showError('Failed to initialize camera: $e');
    }
  }

  Future<void> initializeCamera(int cameraIndex) async {
    try {
      // Set camera as not initialized during transition
      isCameraInitialized.value = false;

      // Dispose current camera controller
      await cameraController?.dispose();

      // Create new camera controller
      cameraController = CameraController(
        cameras[cameraIndex],
        ResolutionPreset.medium,
        enableAudio: true,
      );

      // Initialize the new camera
      await cameraController!.initialize();
      isCameraInitialized.value = true;

      log("Camera initialized successfully for index: $cameraIndex");
    } catch (e) {
      log("Error initializing camera: $e");
      isCameraInitialized.value = false;
      throw e;
    }
  }

  Future<void> switchCamera() async {
    if (cameras.length > 1) {
      log("Switching camera from index ${selectedCameraIndex.value}");
      selectedCameraIndex.value =
          (selectedCameraIndex.value + 1) % cameras.length;
      log("Switching camera to index ${selectedCameraIndex.value}");
      await initializeCamera(selectedCameraIndex.value);
    } else {
      log("No additional cameras available for switching");
    }
  }

  Future<void> captureImage() async {
    if (!canAddMoreMedia) {
      ShortMessageUtils.showError('Maximum $MAX_MEDIA_FILES media files allowed');
      return;
    }

    if (cameraController == null || !cameraController!.value.isInitialized) {
      ShortMessageUtils.showError('Camera not ready. Please wait...');
      return;
    }

    try {
      final XFile image = await cameraController!.takePicture();
      final file = File(image.path);
      
      // Check file size
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      if (fileSizeMB > MAX_FILE_SIZE_MB) {
        ShortMessageUtils.showError('File too large (max ${MAX_FILE_SIZE_MB}MB)');
        return;
      }

      selectedMedia.add(file);
      log('✅ Image captured: ${file.path}');
      
      // Navigate to new post preview
      _navigateToNewProductPreview();
    } catch (e) {
      ShortMessageUtils.showError('Failed to capture image');
      log('❌ Error capturing image: $e');
    }
  }

  Future<void> startVideoRecording() async {
    if (!canAddMoreMedia) {
      ShortMessageUtils.showError('Maximum $MAX_MEDIA_FILES media files allowed');
      return;
    }

    if (cameraController == null || !cameraController!.value.isInitialized) {
      ShortMessageUtils.showError('Camera not ready. Please wait...');
      return;
    }

    if (isRecording.value) {
      log('Already recording, stopping...');
      await stopVideoRecording();
      return;
    }

    try {
      await cameraController!.startVideoRecording();
      isRecording.value = true;
      recordingDuration.value = 0;
      
      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        recordingDuration.value++;
        
        // Auto-stop at max duration
        if (recordingDuration.value >= MAX_VIDEO_DURATION_SECONDS) {
          timer.cancel();
          stopVideoRecording();
        }
      });
      
      log('✅ Recording started');
    } catch (e) {
      ShortMessageUtils.showError('Failed to start recording: $e');
      log('❌ Error starting recording: $e');
    }
  }

  Future<void> stopVideoRecording() async {
    if (!isRecording.value) {
      log('Not recording, ignoring stop request');
      return;
    }

    try {
      Get.find<LoadingController>().show();
      
      final XFile videoFile = await cameraController!.stopVideoRecording();
      isRecording.value = false;
      _recordingTimer?.cancel();
      
      final file = File(videoFile.path);
      
      // Check file size
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      if (fileSizeMB > MAX_FILE_SIZE_MB) {
        ShortMessageUtils.showError('File too large (max ${MAX_FILE_SIZE_MB}MB)');
        Get.find<LoadingController>().hide();
        return;
      }

      // Compress video if it's large
      File? compressedVideo;
      if (fileSizeMB > 10) { // Compress if larger than 10MB
        compressedVideo = await _compressVideo(file);
        if (compressedVideo != null) {
          selectedMedia.add(compressedVideo);
          log('✅ Video recorded and compressed: ${compressedVideo.path} (${recordingDuration.value}s)');
        } else {
          selectedMedia.add(file);
          log('✅ Video recorded: ${file.path} (${recordingDuration.value}s)');
        }
      } else {
        selectedMedia.add(file);
        log('✅ Video recorded: ${file.path} (${recordingDuration.value}s)');
      }
      
      Get.find<LoadingController>().hide();
      
      // Navigate to new post preview
      _navigateToNewProductPreview();
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Failed to save video: $e');
      log('❌ Error stopping recording: $e');
    }
  }

  // New method for tap-to-record functionality
  Future<void> toggleVideoRecording() async {
    if (isRecording.value) {
      await stopVideoRecording();
    } else {
      await startVideoRecording();
    }
  }

  void clearCameraPreview() {
    cameraPreviewFile.value = null;
  }

  Future<void> pickImages() async {
    if (!canAddMoreMedia) {
      ShortMessageUtils.showError('Maximum $MAX_MEDIA_FILES media files allowed');
      return;
    }

    try {
      Get.find<LoadingController>().show();
      
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isEmpty) {
        Get.find<LoadingController>().hide();
        return;
      }

      final int remainingSlots = MAX_MEDIA_FILES - selectedMedia.length;
      final int addedCount = images.length > remainingSlots ? remainingSlots : images.length;
      
      int processedCount = 0;
      for (int i = 0; i < addedCount; i++) {
        try {
          final file = File(images[i].path);
          
          if (!await file.exists()) {
            log('⚠️ File not found: ${images[i].path}');
            continue;
          }
          
          // Check file size
          final fileSize = await file.length();
          final fileSizeMB = fileSize / (1024 * 1024);
          if (fileSizeMB > MAX_FILE_SIZE_MB) {
            log('⚠️ File too large: ${images[i].path} (${fileSizeMB.toStringAsFixed(1)}MB)');
            continue;
          }
          
          selectedMedia.add(file);
          processedCount++;
        } catch (e) {
          log('❌ Error processing image ${i + 1}: $e');
        }
      }
      
      Get.find<LoadingController>().hide();
      log('✅ Added $processedCount images');
      
      // Navigate to new post preview if images were added
      if (processedCount > 0) {
        _navigateToNewProductPreview();
      }
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Failed to pick images: $e');
      log('❌ Error picking images: $e');
    }
  }

  Future<void> pickVideos() async {
    if (!canAddMoreMedia) {
      ShortMessageUtils.showError('Maximum $MAX_MEDIA_FILES media files allowed');
      return;
    }

    try {
      Get.find<LoadingController>().show();
      
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video == null) {
        Get.find<LoadingController>().hide();
        return;
      }

      final file = File(video.path);
      
      if (!await file.exists()) {
        Get.find<LoadingController>().hide();
        ShortMessageUtils.showError('Selected video file not found');
        return;
      }
      
      // Check video duration
      final duration = await _getVideoDuration(file);
      if (duration != null && duration.inSeconds > MAX_VIDEO_DURATION_SECONDS) {
        Get.find<LoadingController>().hide();
        ShortMessageUtils.showError('Video must be $MAX_VIDEO_DURATION_SECONDS seconds or less');
        return;
      }
      
      // Check file size
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);
      if (fileSizeMB > MAX_FILE_SIZE_MB) {
        Get.find<LoadingController>().hide();
        ShortMessageUtils.showError('File too large (max ${MAX_FILE_SIZE_MB}MB)');
        return;
      }
      
      selectedMedia.add(file);
      Get.find<LoadingController>().hide();
      log('✅ Video selected: ${file.path}');
      
      // Navigate to new post preview
      _navigateToNewProductPreview();
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Failed to process video: $e');
      log('❌ Error processing video: $e');
    }
  }

  Future<void> pickMedia() async {
    if (!canAddMoreMedia) {
      ShortMessageUtils.showError('Maximum $MAX_MEDIA_FILES media files allowed');
      return;
    }

    try {
      Get.find<LoadingController>().show();
      
      final ImagePicker picker = ImagePicker();
      final List<XFile> media = await picker.pickMultiImage();
      
      if (media.isEmpty) {
        Get.find<LoadingController>().hide();
        return;
      }

      final int remainingSlots = MAX_MEDIA_FILES - selectedMedia.length;
      final int addedCount = media.length > remainingSlots ? remainingSlots : media.length;
      
      int processedCount = 0;
      for (int i = 0; i < addedCount; i++) {
        try {
          final file = File(media[i].path);
          
          if (!await file.exists()) {
            log('⚠️ File not found: ${media[i].path}');
            continue;
          }
          
          // Check if it's a video file
          final isVideo = media[i].path.toLowerCase().contains('.mp4') ||
              media[i].path.toLowerCase().contains('.mov') ||
              media[i].path.toLowerCase().contains('.avi');
          
          if (isVideo) {
            // Check video duration
            final duration = await _getVideoDuration(file);
            if (duration != null && duration.inSeconds > MAX_VIDEO_DURATION_SECONDS) {
              log('⚠️ Video too long: ${media[i].path}');
              continue;
            }
          }
          
          // Check file size
          final fileSize = await file.length();
          final fileSizeMB = fileSize / (1024 * 1024);
          if (fileSizeMB > MAX_FILE_SIZE_MB) {
            log('⚠️ File too large: ${media[i].path} (${fileSizeMB.toStringAsFixed(1)}MB)');
            continue;
          }
          
          selectedMedia.add(file);
          processedCount++;
        } catch (e) {
          log('❌ Error processing media ${i + 1}: $e');
        }
      }
      
      Get.find<LoadingController>().hide();
      log('✅ Added $processedCount files');
      
      // Navigate to new post preview if files were added
      if (processedCount > 0) {
        _navigateToNewProductPreview();
      }
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Failed to pick media: $e');
      log('❌ Error picking media: $e');
    }
  }

  Future<ImageSource?> _showMediaPickerOptions() async {
    return await Get.bottomSheet<ImageSource>(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<String?> _showCameraOptions() async {
    return await Get.bottomSheet<String>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () => Get.back(result: 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blue),
                title: const Text('Record Video'),
                subtitle: const Text('Max 30 seconds'),
                onTap: () => Get.back(result: 'video'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void removeMedia(int index) {
    if (index >= 0 && index < selectedMedia.length) {
      selectedMedia.removeAt(index);
      log('✅ Media removed at index $index');
    }
  }

  bool isVideoFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.webm');
  }

  Future<Duration?> _getVideoDuration(File videoFile) async {
    try {
      final controller = VideoPlayerController.file(videoFile);
      
      // Add timeout to prevent hanging
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          log('Video duration check timed out');
          throw Exception('Video duration check timed out');
        },
      );
      
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      log('Error getting video duration: $e');
      return null;
    }
  }

  Future<bool> _checkFileSize(File file) async {
    final fileSize = await file.length();
    final maxSize = MAX_FILE_SIZE_MB * 1024 * 1024; // 100MB limit

    if (fileSize > maxSize) {
      ShortMessageUtils.showError('File too large (max ${MAX_FILE_SIZE_MB}MB)');
      return false;
    }
    return true;
  }

  Future<File?> _compressVideo(File videoFile) async {
    try {
      Get.find<LoadingController>().show();

      // Cancel previous subscription if any
      _compressionSubscription?.unsubscribe();

      // Subscribe to progress stream
      _compressionSubscription =
          VideoCompress.compressProgress$.subscribe((progress) {
        if (progress != null) {
          Get.find<LoadingController>().show();
        }
      });

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      Get.find<LoadingController>().hide();

      // Unsubscribe after compression
      _compressionSubscription?.unsubscribe();
      _compressionSubscription = null;

      if (mediaInfo?.file != null) {
        final originalSize = await videoFile.length();
        final compressedSize = await mediaInfo!.file!.length();
        final compressionRatio =
        ((originalSize - compressedSize) / originalSize * 100)
            .toStringAsFixed(1);

        log('Video compressed successfully. Original: ${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB, Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(1)}MB, Saved: ${compressionRatio}%');
        ShortMessageUtils.showSuccess(
            "Video compressed (${compressionRatio}% smaller)");

        return mediaInfo.file;
      } else {
        ShortMessageUtils.showError('Failed to compress video');
        return null;
      }
    } catch (e) {
      Get.find<LoadingController>().hide();
      log('Error compressing video: $e');
      ShortMessageUtils.showError('Failed to compress video');
      return null;
    } finally {
      // Ensure cleanup
      _compressionSubscription?.unsubscribe();
      _compressionSubscription = null;
    }
  }

  Future<void> _generateVideoThumbnail(File videoFile) async {
    if (!isVideoFile(videoFile)) return;
    if (videoThumbnails.containsKey(videoFile)) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await th.VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: th.ImageFormat.JPEG,
        quality: 75,
        maxWidth: 300,
        maxHeight: 300,
      );
      log("Thumbnail path is $thumbPath");
      videoThumbnails[videoFile] = thumbPath;
    } catch (e) {
      videoThumbnails[videoFile] = null;
      log('Error generating video thumbnail: $e');
    }
  }

  String? getVideoThumbnail(File videoFile) {
    return videoThumbnails[videoFile];
  }

  Future<void> createProduct() async {
    log("Selected media is $selectedMedia");
    
    final isBusiness = mapController.isBusinessUser.value;
    if (!isBusiness) {
      return;
    }
    
    // Check if media is selected
    if (selectedMedia.isEmpty) {
      ShortMessageUtils.showError('Please select at least one photo or video to create a post');
      return;
    }
    
    // Check if description is provided
    if (descriptionController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please add a description to your post');
      return;
    }

    try {
      isLoading.value = true;
      isUploading.value = true;
      uploadProgress.value = 0.0;
      uploadStatus.value = "Preparing upload...";
      totalFiles.value = selectedMedia.length;
      processedFiles.value = 0;
      
      Get.find<LoadingController>().show();

      // Simulate progress for file processing
      for (int i = 0; i < selectedMedia.length; i++) {
        uploadStatus.value = "Processing file ${i + 1}/${selectedMedia.length}...";
        uploadProgress.value = (i + 1) / selectedMedia.length * 0.3; // 30% for processing
        processedFiles.value = i + 1;
        await Future.delayed(const Duration(milliseconds: 200));
      }

      uploadStatus.value = "Uploading to server...";
      uploadProgress.value = 0.3;

      // Use the injected API service for better consistency
      final result = await _apiService.uploadImage(
        endpoint: "posts",
        imageFiles: selectedMedia.toList(),
        fields: {'description': descriptionController.text},
        method: 'POST',
      );

      uploadProgress.value = 1.0;
      uploadStatus.value = "Product created successfully!";
      
      log("Product creation result: $result");
      
      // Dismiss loading immediately after successful API response
      Get.find<LoadingController>().hide();
      
      descriptionController.clear();
      selectedMedia.clear();
      videoThumbnails.clear();
      
      // Reset progress
      uploadProgress.value = 0.0;
      uploadStatus.value = "";
      isUploading.value = false;
      
      Get.back();
      
      
      await ShortMessageUtils.showSuccess("Product created successfully!");
    } catch (e) {
      uploadProgress.value = 0.0;
      uploadStatus.value = "Upload failed";
      isUploading.value = false;
      isLoading.value = false;
      
      // Dismiss loading immediately when there's an error
      Get.find<LoadingController>().hide();
      
      log("Error while creating post $e");
      
      // Provide user-friendly error messages
      String errorMessage = 'Failed to create post';
      if (e.toString().contains('At least one media file is required')) {
        errorMessage = 'Please select at least one photo or video to create a post';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Invalid post data. Please check your content and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      }
      
      await ShortMessageUtils.showError(errorMessage);
    }
  }

  Future<void> editProduct(String postId) async {
    // Check if media is selected
    if (selectedMedia.isEmpty) {
      ShortMessageUtils.showError('Please select at least one photo or video to update your post');
      return;
    }
    
    // Check if description is provided
    if (descriptionController.text.trim().isEmpty) {
      ShortMessageUtils.showError('Please add a description to your post');
      return;
    }
    
    try {
      isLoading.value = true;
      Get.find<LoadingController>().show();
      
      log("Selected media are ${selectedMedia}");
      for (var file in selectedMedia) {
        log("📁 Selected file: ${file.path}");
      }
      
      final result = await _apiService.uploadImage(
        endpoint: "posts/$postId",
        imageFiles: selectedMedia.toList(),
        fields: {'description': descriptionController.text},
        method: 'PATCH',
      );
      
      log("Product edit result: $result");
      
      // Dismiss loading immediately after successful API response
      Get.find<LoadingController>().hide();
      
      descriptionController.clear();
      selectedMedia.clear();
      videoThumbnails.clear();
      Get.back();
      
      
      
      await ShortMessageUtils.showSuccess("Product updated successfully!");
    } catch (e) {
      isLoading.value = false;
      
      // Dismiss loading immediately when there's an error
      Get.find<LoadingController>().hide();
      
      log("Error while editing post: $e");
      await ShortMessageUtils.showError('Failed to update post: $e');
    }
  }

  void _navigateToNewProductPreview() {
    Get.toNamed('/new-post-preview');
  }

  /// Create a product/service from the simple form (name, description, price, image)
  Future<void> createProductFromForm({
    required String name,
    required String description,
    required String price,
    required String type,
    required File imageFile,
  }) async {
    try {
      isLoading.value = true;
      Get.find<LoadingController>().show();

      final result = await _apiService.uploadImage(
        endpoint: 'products',
        imageFiles: [imageFile],
        fields: {
          'name': name,
          'description': description,
          'price': price,
          'type': type,
        },
        imageField: 'media',
        method: 'POST',
      );

      log("Product creation result: $result");
      
      Get.find<LoadingController>().hide();
      
      // Refresh the products list in ProductsController if it exists
      if (Get.isRegistered<ProductsController>()) {
        await Get.find<ProductsController>().refreshProducts();
      }
      
      await ShortMessageUtils.showSuccess('${type.capitalize} created successfully!');
    } catch (e) {
      isLoading.value = false;
      Get.find<LoadingController>().hide();
      
      log("Error creating product: $e");
      
      String errorMessage = 'Failed to create ${type.toLowerCase()}';
      if (e.toString().contains('400')) {
        errorMessage = 'Invalid product data. Please check your information.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection.';
      }
      
      await ShortMessageUtils.showError(errorMessage);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _compressionSubscription?.unsubscribe();
    _compressionSubscription = null;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    cameraController?.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
