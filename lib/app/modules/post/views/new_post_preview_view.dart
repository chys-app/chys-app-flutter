import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../controllers/post_controller.dart';

class NewPostPreviewView extends StatefulWidget {
  const NewPostPreviewView({Key? key}) : super(key: key);

  @override
  State<NewPostPreviewView> createState() => _NewPostPreviewViewState();
}

class _NewPostPreviewViewState extends State<NewPostPreviewView> {
  final ScrollController _scrollController = ScrollController();
  
  PostController get controller {
    try {
      return Get.find<PostController>();
    } catch (e) {
      // If controller not found, create a new one
      return Get.put(PostController());
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
        ),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        'New Post',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside text field
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        resizeToAvoidBottomInset: true,
        body: Obx(() {
          // Safety check for controller and selectedMedia
          if (controller.selectedMedia.isEmpty) {
            return _buildEmptyState();
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Media preview section - flexible height
                  Flexible(
                    flex: 3,
                    child: _buildMediaPreview(),
                  ),
                  
                  // Description input section with tabs
                  Flexible(
                    flex: 2,
                    child: _buildDescriptionSection(),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No media selected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go back to capture or select media',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Obx(() {
        if (controller.selectedMedia.length == 1) {
          // Single media - full screen
          return _buildSingleMediaPreview(controller.selectedMedia.first);
        } else {
          // Multiple media - page view
          return _buildMultipleMediaPreview();
        }
      }),
    );
  }

  Widget _buildSingleMediaPreview(File media) {
    final isVideo = controller.isVideoFile(media);
    final mediaIndex = controller.selectedMedia.indexOf(media);
    
    return Stack(
      children: [
        // Media content
        if (isVideo)
          _buildVideoPlayer(media)
        else
          Center(
            child: Image.file(
              media,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        
        // Remove button
        Positioned(
          top: 20,
          right: 20,
          child: GestureDetector(
            onTap: () => _removeMedia(mediaIndex),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(File videoFile) {
    return _VideoPlayerWidget(videoFile: videoFile);
  }

  Widget _buildMultipleMediaPreview() {
    return Stack(
      children: [
        PageView.builder(
          itemCount: controller.selectedMedia.length,
          itemBuilder: (context, index) {
            final media = controller.selectedMedia[index];
            return _buildSingleMediaPreview(media);
          },
        ),
        
        // Page indicator for multiple media
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                controller.selectedMedia.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.3), width: 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description input
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TextField(
                controller: controller.descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Post button
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : () {
                controller.createPost();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description input
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: TextField(
              controller: controller.descriptionController,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              ),
              onTap: () {
                // Scroll to bottom when keyboard appears
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
              },
            ),
          ),

          const SizedBox(height: 20),
          
          // Post button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.createPost(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Bottom padding to ensure button is visible above keyboard
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFundraiserTab() {
    final TextEditingController fundraiserDescriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final RxString selectedDeadline = ''.obs;

    Future<void> _selectDeadline(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue[600]!,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        selectedDeadline.value = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description input
          Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: TextField(
              controller: fundraiserDescriptionController,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Describe your fundraiser...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              ),
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
              },
            ),
          ),

          const SizedBox(height: 20),

          // Amount input
          Text(
            'Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Enter target amount',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: Icon(Icons.attach_money, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              ),
              onSubmitted: (value) {
                FocusScope.of(context).unfocus();
              },
            ),
          ),

          const SizedBox(height: 20),

          // Deadline input
          Text(
            'Deadline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => GestureDetector(
            onTap: () => _selectDeadline(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDeadline.value.isEmpty
                          ? 'Select deadline date'
                          : selectedDeadline.value,
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedDeadline.value.isEmpty
                            ? Colors.grey[500]
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          )),

          const SizedBox(height: 20),
          
          // Create Fundraiser button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement fundraiser creation logic
                if (fundraiserDescriptionController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please enter a description',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red[600],
                    colorText: Colors.white,
                  );
                  return;
                }
                if (amountController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please enter an amount',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red[600],
                    colorText: Colors.white,
                  );
                  return;
                }
                if (selectedDeadline.value.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please select a deadline',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red[600],
                    colorText: Colors.white,
                  );
                  return;
                }
                // Fundraiser creation logic here
                Get.snackbar(
                  'Coming Soon',
                  'Fundraiser creation will be implemented soon',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.blue[600],
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.green.withOpacity(0.3),
              ),
              child: const Text(
                'Create Fundraiser',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Bottom padding to ensure button is visible above keyboard
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _removeMedia(int index) {
    if (index >= 0 && index < controller.selectedMedia.length) {
      // Show confirmation dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Remove Media'),
          content: const Text('Are you sure you want to remove this media?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
                controller.removeMedia(index);
                
                // If no media left, go back to camera
                if (controller.selectedMedia.isEmpty) {
                  Get.back();
                }
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }
  }

  Future<String?> _getVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      log('Error generating video thumbnail: $e');
      return null;
    }
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final File videoFile;

  const _VideoPlayerWidget({required this.videoFile});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(
        widget.videoFile,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Add listener to sync with actual video state
        _controller!.addListener(_videoListener);
      }
    } catch (e) {
      log('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      final actualIsPlaying = _controller!.value.isPlaying;
      if (actualIsPlaying != _isPlaying) {
        setState(() {
          _isPlaying = actualIsPlaying;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading video',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _initializeVideo();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
          // Single overlay that changes based on state
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
