import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import '../../../core/const/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/live_video_controller.dart';

class LiveVideoView extends StatefulWidget {
  const LiveVideoView({Key? key}) : super(key: key);

  @override
  State<LiveVideoView> createState() => _LiveVideoViewState();
}

class _LiveVideoViewState extends State<LiveVideoView> {
  final LiveVideoController controller = Get.put(LiveVideoController());
  Timer? _liveTimer;
  int _liveDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeLiveStream();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _initializeLiveStream() {
    // Start live timer
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _liveDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final type = args?['type'] ?? 'story';
    final title = args?['title'] ?? 'Live Stream';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(title),
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return _buildLoadingScreen();
        }

        return Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),
            
            // Live indicator
            _buildLiveIndicator(),
            
            // Viewer count
            _buildViewerCount(),
            
            // Live duration
            _buildLiveDuration(),
            
            // Bottom controls
            _buildBottomControls(type),
            
            // Side controls
            _buildSideControls(),
            
            // Comments overlay (if enabled)
            if (controller.showComments.value)
              _buildCommentsOverlay(),
          ],
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
        onPressed: () => _endLiveStream(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 20),
          ),
          onPressed: () => _showSettings(),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Starting Live Stream...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Positioned.fill(
      child: Obx(() {
        if (controller.isInitialized.value &&
            controller.cameraController != null &&
            controller.cameraController!.value.isInitialized) {
          return CameraPreview(controller.cameraController!);
        }
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }),
    );
  }

  Widget _buildLiveIndicator() {
    return Positioned(
      top: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
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
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerCount() {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Obx(() => Text(
              '${controller.viewerCount.value}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDuration() {
    return Positioned(
      top: 140,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatDuration(_liveDuration),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(String type) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Description input
            _buildDescriptionInput(),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Flip',
                  onTap: () => controller.flipCamera(),
                ),
                Obx(() => _buildControlButton(
                  icon: controller.showComments.value 
                      ? Icons.comment 
                      : Icons.comment_outlined,
                  label: 'Comments',
                  onTap: () => controller.toggleComments(),
                )),
                _buildControlButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _shareLiveStream(),
                ),
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'End',
                  onTap: () => _endLiveStream(),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideControls() {
    return Positioned(
      right: 20,
      bottom: 200,
      child: Obx(() => Column(
        children: [
          _buildSideButton(
            icon: Icons.flash_on,
            onTap: () => controller.toggleFlash(),
            isActive: controller.isFlashOn.value,
          ),
          const SizedBox(height: 16),
          _buildSideButton(
            icon: Icons.mic,
            onTap: () => controller.toggleMicrophone(),
            isActive: controller.isMicrophoneOn.value,
          ),
          const SizedBox(height: 16),
          _buildSideButton(
            icon: Icons.videocam,
            onTap: () => controller.toggleCamera(),
            isActive: controller.isCameraOn.value,
          ),
        ],
      )),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color ?? Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.primary 
              : Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Add a description...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () => controller.updateDescription(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsOverlay() {
    return Positioned(
      left: 20,
      right: 100,
      bottom: 200,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => controller.toggleComments(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '${comment['user']}: ${comment['text']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Live Stream Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingItem(
              'Stream Quality',
              'HD (720p)',
              () => _showQualityOptions(),
            ),
            _buildSettingItem(
              'Privacy',
              'Public',
              () => _showPrivacyOptions(),
            ),
            _buildSettingItem(
              'Notifications',
              'On',
              () => _showNotificationOptions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showQualityOptions() {
    // Show quality selection options
    Get.dialog(
      AlertDialog(
        title: const Text('Stream Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityOption('SD (480p)', '480p'),
            _buildQualityOption('HD (720p)', '720p'),
            _buildQualityOption('Full HD (1080p)', '1080p'),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(String title, String value) {
    return Obx(() => ListTile(
      title: Text(title),
      trailing: Radio<String>(
        value: value,
        groupValue: controller.streamQuality.value,
        onChanged: (value) {
          controller.setStreamQuality(value!);
          Get.back();
        },
      ),
    ));
  }

  void _showPrivacyOptions() {
    // Show privacy options
    Get.dialog(
      AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrivacyOption('Public', 'Anyone can watch'),
            _buildPrivacyOption('Followers Only', 'Only your followers'),
            _buildPrivacyOption('Private', 'Invite only'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(String title, String subtitle) {
    return Obx(() => ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Radio<String>(
        value: title,
        groupValue: controller.privacyLevel.value,
        onChanged: (value) {
          controller.setPrivacyLevel(value!);
          Get.back();
        },
      ),
    ));
  }

  void _showNotificationOptions() {
    // Show notification options
    Get.dialog(
      AlertDialog(
        title: const Text('Notifications'),
        content: Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: controller.pushNotifications.value,
              onChanged: (value) {
                controller.setPushNotifications(value);
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              value: controller.emailNotifications.value,
              onChanged: (value) {
                controller.setEmailNotifications(value);
              },
            ),
          ],
        )),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _shareLiveStream() {
    // Share live stream link
    Get.snackbar(
      'Share Live Stream',
      'Live stream link copied to clipboard!',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  void _endLiveStream() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            Text(
              'End Live Stream',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to end this live stream? This action cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Close dialog
              controller.endLiveStream();
              Get.back(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );
  }
}
