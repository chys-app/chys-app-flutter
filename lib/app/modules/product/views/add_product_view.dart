import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart' hide ImageFormat;
import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../controllers/product_controller.dart';

class AddProductView extends StatelessWidget {
  AddProductView({Key? key}) : super(key: key);
  final ProductController controller = Get.put(ProductController());

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
        'Create Product',
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
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return _buildLoadingScreen();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final screenHeight = constraints.maxHeight;
            final availableHeight = screenHeight - keyboardHeight;

            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: availableHeight,
              child: Stack(
                children: [
                  // Full screen camera - takes entire screen
                  _buildFullScreenCamera(context),

                  // Bottom overlay - controls
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomOverlay(context),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Initializing Camera...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return Obx(() {
      final media = controller.selectedMedia;
      if (media.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Media',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${media.length}/${ProductController.MAX_MEDIA_FILES}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final file = media[index];
                  final isVideo = controller.isVideoFile(file);
                  return _buildMediaThumbnail(file, isVideo, index);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMediaThumbnail(File file, bool isVideo, int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[400]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: isVideo
                ? _buildVideoThumbnail(file)
                : Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image,
                                color: Colors.grey[600], size: 32),
                            const SizedBox(height: 4),
                            Text(
                              'Image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        // Remove button
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => controller.removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[600],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red[300]!.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
        // Video indicator
        if (isVideo)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Image indicator
        if (!isVideo)
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[600]!.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[300]!.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'IMAGE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // File number indicator
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[300]!.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail(File file) {
    final thumbnailPath = controller.getVideoThumbnail(file);
    if (thumbnailPath != null) {
      return Image.file(
        File(thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.videocam, color: Colors.grey),
          );
        },
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.videocam, color: Colors.grey),
    );
  }

  Widget _buildFullScreenCamera(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final screenHeight = constraints.maxHeight;
        final availableHeight = screenHeight - keyboardHeight;

        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: availableHeight,
          child: Obx(() {
            if (controller.isCameraInitialized.value &&
                controller.cameraController != null &&
                controller.cameraController!.value.isInitialized) {
              return Stack(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: availableHeight - 120,
                    child: CameraPreview(controller.cameraController!),
                  ),
                  _buildCameraOverlay(),
                ],
              );
            } else {
              return Container(
                width: MediaQuery.of(context).size.width,
                height: availableHeight,
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Initializing camera...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
          }),
        );
      },
    );
  }

  Widget _buildBottomOverlay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.05),
            Colors.black.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          Obx(() {
            if (controller.isRecording.value) {
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recording... ${controller.recordingDuration.value}s / ${ProductController.MAX_VIDEO_DURATION_SECONDS}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Action buttons only
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildProductButton() {
    return Obx(() => controller.isLoading.value
        ? Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed:
                  controller.isLoading.value ? null : controller.createProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
              ),
              child: const Text(
                'Create Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ));
  }

  Widget _buildProgressIndicator() {
    return Obx(() {
      if (!controller.isUploading.value) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.uploadStatus.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Text(
                  '${(controller.uploadProgress.value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: controller.uploadProgress.value,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
            if (controller.totalFiles.value > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Files processed:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${controller.processedFiles.value}/${controller.totalFiles.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildDescriptionInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onTap: () {
                controller.showEmojiPicker.value = false;
              },
              onTapOutside: (event) {
                FocusScope.of(context).unfocus();
              },
              controller: controller.descriptionController,
              maxLines: 2,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Share your thoughts...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
              ),
              onChanged: (_) => controller.descriptionController.text,
            ),
          ),
          IconButton(
            icon: Icon(
              controller.showEmojiPicker.value
                  ? Icons.keyboard
                  : Icons.emoji_emotions_outlined,
              color: Colors.grey[600],
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
              controller.showEmojiPicker.value =
                  !controller.showEmojiPicker.value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMediaPreview() {
    return Obx(() {
      if (controller.selectedMedia.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: 100,
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library,
                      color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.selectedMedia.length}/${ProductController.MAX_MEDIA_FILES}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable media items
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: controller.selectedMedia.length,
                itemBuilder: (context, index) {
                  final media = controller.selectedMedia[index];
                  final isVideo = media.path.toLowerCase().contains('.mp4') ||
                      media.path.toLowerCase().contains('.mov') ||
                      media.path.toLowerCase().contains('.avi');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Stack(
                      children: [
                        // Media thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: isVideo
                                ? FutureBuilder<String?>(
                                    future: _getVideoThumbnail(media.path),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return Image.file(
                                          File(snapshot.data!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.videocam,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.videocam,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(media.path),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        // Video indicator
                        if (isVideo)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VID',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // File number badge
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Remove button
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => controller.removeMedia(index),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.red[600],
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLeftSideButtons() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSideButton(
            icon: Icons.photo_camera,
            label: 'Photo',
            onTap: () => controller.captureImage(),
            onLongPress: () => controller.startVideoRecording(),
            onLongPressEnd: (details) => controller.stopVideoRecording(),
            color: Colors.black87,
            isRecording: false,
          ),
          const SizedBox(height: 20),
          _buildSideButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: () => controller.pickImages(),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildRightSideButtons() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSideButton(
            icon: Icons.videocam,
            label: 'Record',
            onTap: () => controller.toggleVideoRecording(),
            onLongPress: () => controller.startVideoRecording(),
            onLongPressEnd: (details) => controller.stopVideoRecording(),
            color: Colors.red,
            isRecording: controller.isRecording.value,
          ),
          const SizedBox(height: 20),
          _buildSideButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: () => controller.flipCamera(),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    VoidCallback? onLongPress,
    GestureLongPressEndCallback? onLongPressEnd,
    bool isRecording = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          onLongPressEnd: onLongPressEnd,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isRecording ? Colors.red : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording ? Colors.red : Colors.grey[600]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRecording ? Colors.red : Colors.grey).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop : icon,
              color: isRecording ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isRecording ? 'Recording...' : label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: isRecording ? FontWeight.bold : FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.photo_camera,
            label: 'Photo',
            onTap: () => controller.captureImage(),
            onLongPress: () => controller.startVideoRecording(),
            onLongPressEnd: (details) => controller.stopVideoRecording(),
            color: Colors.black87,
            isRecording: false,
          ),
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: () => controller.pickImages(),
            color: Colors.black87,
          ),
          _buildActionButton(
            icon: Icons.videocam,
            label: 'Record',
            onTap: () => controller.toggleVideoRecording(),
            onLongPress: () => controller.startVideoRecording(),
            onLongPressEnd: (details) => controller.stopVideoRecording(),
            color: Colors.red,
            isRecording: controller.isRecording.value,
          ),
          _buildActionButton(
            icon: Icons.flip_camera_ios,
            label: 'Flip',
            onTap: () => controller.flipCamera(),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    VoidCallback? onLongPress,
    GestureLongPressEndCallback? onLongPressEnd,
    bool isRecording = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          onLongPressEnd: onLongPressEnd,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isRecording ? Colors.red : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording ? Colors.red : Colors.grey[600]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isRecording ? Colors.red : Colors.grey).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isRecording ? Icons.stop : icon,
              color: isRecording ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isRecording ? 'Recording...' : label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black87,
            fontWeight: isRecording ? FontWeight.bold : FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Close button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 50), // Spacer
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[700]),
                  onPressed: () {
                    controller.showEmojiPicker.value = false;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                final text =
                    controller.descriptionController.text + emoji.emoji;
                controller.descriptionController.text = text;
                controller.descriptionController.selection =
                    TextSelection.fromPosition(
                  TextPosition(offset: text.length),
                );
              },
              config: Config(
                checkPlatformCompatibility: true,
                emojiTextStyle: const TextStyle(fontSize: 24),
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: Colors.transparent,
                ),
                categoryViewConfig: CategoryViewConfig(
                  iconColor: Colors.grey[600]!,
                  iconColorSelected: Colors.blue[600]!,
                  backgroundColor: Colors.transparent,
                  indicatorColor: Colors.blue[600]!,
                ),
                skinToneConfig: SkinToneConfig(
                  dialogBackgroundColor: Colors.white,
                  indicatorColor: Colors.blue[600]!,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  backgroundColor: Colors.transparent,
                  buttonColor: Colors.grey[200]!,
                  buttonIconColor: Colors.grey[700]!,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Positioned(
      top: 120, // Below app bar
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Tap for photo • Hold for video',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<String?> _getVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 60,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      log('Error generating video thumbnail: $e');
      return null;
    }
  }
}
