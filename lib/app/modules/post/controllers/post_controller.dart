import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/pet_ownership_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as th;

import '../../../services/short_message_utils.dart';
import '../../adored_posts/controller/controller.dart';

class PostController extends GetxController {
  // Constants for better maintainability
  static const int MAX_MEDIA_FILES = 5;
  static const int MAX_VIDEO_DURATION_SECONDS = 30;
  static const int MAX_FILE_SIZE_MB = 100;
  
  final CustomApiService _apiService = Get.put(CustomApiService());
  final descriptionController = TextEditingController();
  final selectedMedia = <File>[].obs;
  final isLoading = false.obs;
  RxString selectedType = "Post".obs;
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
  
  // Progress tracking variables
  RxDouble uploadProgress = 0.0.obs;
  RxString uploadStatus = "".obs;
  RxBool isUploading = false.obs;
  RxInt totalFiles = 0.obs;
  RxInt processedFiles = 0.obs;

  int get mediaCount => selectedMedia.length;
  bool get canAddMoreMedia => mediaCount < MAX_MEDIA_FILES;

  void setType(String type) {
    selectedType.value = type;
  }

  void resetType() {
    log("Come here");
    selectedType.value = "Post";
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
      rethrow;
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
      _navigateToNewPostPreview();
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
      _navigateToNewPostPreview();
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
        _navigateToNewPostPreview();
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
      _navigateToNewPostPreview();
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
        _navigateToNewPostPreview();
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
    const maxSize = MAX_FILE_SIZE_MB * 1024 * 1024; // 100MB limit

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
        Get.find<LoadingController>().show();
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

        log('Video compressed successfully. Original: ${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB, Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(1)}MB, Saved: $compressionRatio%');
        ShortMessageUtils.showSuccess(
            "Video compressed ($compressionRatio% smaller)");

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

  Future<void> createPost() async {
    log("Selected media is $selectedMedia");
    
    // Check pet ownership first
    final petService = PetOwnershipService.instance;
    if (!petService.canCreatePosts) {
      //petService.showPostRestriction();
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
      uploadStatus.value = "Post created successfully!";
      
      log("Post creation result: $result");
      
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
      
      // Clear cache and refresh posts with proper error handling
      try {
        final postsController = Get.find<AddoredPostsController>(tag: 'home');
        postsController.clearAllCache(); // Clear all cache
        await postsController.fetchAdoredPosts(forceRefresh: true); // Force refresh
      } catch (e) {
        log("AddoredPostsController not found, skipping refresh: $e");
        // Try without tag as fallback
        try {
          final postsController = Get.find<AddoredPostsController>();
          postsController.clearAllCache(); // Clear all cache
          await postsController.fetchAdoredPosts(forceRefresh: true); // Force refresh
        } catch (e2) {
          log("AddoredPostsController not found without tag either: $e2");
        }
      }
      
      await ShortMessageUtils.showSuccess("Post created successfully!");
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

  Future<void> editPost(String postId) async {
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
      
      log("Selected media are $selectedMedia");
      for (var file in selectedMedia) {
        log("📁 Selected file: ${file.path}");
      }
      
      final result = await _apiService.uploadImage(
        endpoint: "posts/$postId",
        imageFiles: selectedMedia.toList(),
        fields: {'description': descriptionController.text},
        method: 'PATCH',
      );
      
      log("Post edit result: $result");
      
      // Dismiss loading immediately after successful API response
      Get.find<LoadingController>().hide();
      
      descriptionController.clear();
      selectedMedia.clear();
      videoThumbnails.clear();
      Get.back();
      
      // Clear cache and refresh posts with proper error handling
      try {
        final postsController = Get.find<AddoredPostsController>(tag: 'home');
        postsController.clearAllCache(); // Clear all cache
        await postsController.fetchAdoredPosts(
            userId: Get.find<ProfileController>().profile.value!.id,
            forceRefresh: true); // Force refresh
      } catch (e) {
        log("AddoredPostsController not found, skipping refresh: $e");
        // Try without tag as fallback
        try {
          final postsController = Get.find<AddoredPostsController>();
          postsController.clearAllCache(); // Clear all cache
          await postsController.fetchAdoredPosts(
              userId: Get.find<ProfileController>().profile.value!.id,
              forceRefresh: true); // Force refresh
        } catch (e2) {
          log("AddoredPostsController not found without tag either: $e2");
        }
      }
      
      await ShortMessageUtils.showSuccess("Post updated successfully!");
    } catch (e) {
      isLoading.value = false;
      
      // Dismiss loading immediately when there's an error
      Get.find<LoadingController>().hide();
      
      log("Error while editing post: $e");
      await ShortMessageUtils.showError('Failed to update post: $e');
    }
  }

  void _navigateToNewPostPreview() {
    Get.toNamed('/new-post-preview');
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
