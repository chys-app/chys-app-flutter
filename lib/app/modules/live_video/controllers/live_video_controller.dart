import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../services/custom_Api.dart';

class LiveVideoController extends GetxController {
  final CustomApiService _apiService = Get.put(CustomApiService());

  // Camera and streaming
  CameraController? cameraController;
  final isInitialized = false.obs;
  final isStreaming = false.obs;
  final isFlashOn = false.obs;
  final isMicrophoneOn = true.obs;
  final isCameraOn = true.obs;

  // Live stream data
  final viewerCount = 0.obs;
  final streamQuality = '720p'.obs;
  final privacyLevel = 'Public'.obs;
  final pushNotifications = true.obs;
  final emailNotifications = false.obs;

  // UI state
  final showComments = false.obs;
  final comments = <Map<String, dynamic>>[].obs;
  final descriptionController = TextEditingController();

  // Stream management
  String? _streamId;
  Timer? _viewerCountTimer;
  Timer? _commentTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
  }

  @override
  void onClose() {
    _viewerCountTimer?.cancel();
    _commentTimer?.cancel();
    cameraController?.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        log('No cameras available');
        return;
      }

      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();
      isInitialized.value = true;

      // Start live stream
      await _startLiveStream();
    } catch (e) {
      log('Error initializing camera: $e');
      Get.snackbar(
        'Camera Error',
        'Failed to initialize camera: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startLiveStream() async {
    try {
      // Simulate starting live stream
      isStreaming.value = true;

      // Generate stream ID
      _streamId = DateTime.now().millisecondsSinceEpoch.toString();

      // Start viewer count simulation
      _startViewerCountSimulation();

      // Start comment simulation
      _startCommentSimulation();

      // Call API to start live stream
      await _apiService.postRequest('live/start', {
        'streamId': _streamId,
        'quality': streamQuality.value,
        'privacy': privacyLevel.value,
        'description': descriptionController.text,
      });

      log('Live stream started with ID: $_streamId');
    } catch (e) {
      log('Error starting live stream: $e');
      Get.snackbar(
        'Stream Error',
        'Failed to start live stream: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _startViewerCountSimulation() {
    _viewerCountTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Simulate viewer count changes
      final currentCount = viewerCount.value;
      final change = (currentCount * 0.1).round() + (currentCount > 0 ? -1 : 1);
      viewerCount.value = (currentCount + change).clamp(0, 1000);
    });
  }

  void _startCommentSimulation() {
    _commentTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate incoming comments
      final sampleComments = [
        {'user': 'PetLover123', 'text': 'Cute pet! 🐾'},
        {'user': 'AnimalFan', 'text': 'What breed is that?'},
        {'user': 'DogMom', 'text': 'So adorable! ❤️'},
        {'user': 'CatDad', 'text': 'My cat does the same thing!'},
        {'user': 'VetStudent', 'text': 'Great to see healthy pets!'},
      ];

      if (comments.length < 10) {
        final randomComment = sampleComments[
            DateTime.now().millisecondsSinceEpoch % sampleComments.length];
        comments.add(randomComment);
      }
    });
  }

  Future<void> flipCamera() async {
    try {
      if (cameraController == null) return;

      final cameras = await availableCameras();
      if (cameras.length < 2) {
        Get.snackbar(
          'Camera Error',
          'Only one camera available',
          backgroundColor: AppColors.accent,
          colorText: Colors.white,
        );
        return;
      }

      final currentCamera = cameraController!.description;
      final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection != currentCamera.lensDirection,
      );

      await cameraController!.dispose();

      cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();
    } catch (e) {
      log('Error flipping camera: $e');
    }
  }

  void toggleFlash() {
    if (cameraController == null) return;

    try {
      isFlashOn.value = !isFlashOn.value;
      cameraController!.setFlashMode(
        isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      log('Error toggling flash: $e');
    }
  }

  void toggleMicrophone() {
    isMicrophoneOn.value = !isMicrophoneOn.value;
    // In a real implementation, you would mute/unmute the microphone
    log('Microphone ${isMicrophoneOn.value ? "enabled" : "disabled"}');
  }

  void toggleCamera() {
    isCameraOn.value = !isCameraOn.value;
    // In a real implementation, you would turn camera on/off
    log('Camera ${isCameraOn.value ? "enabled" : "disabled"}');
  }

  void toggleComments() {
    showComments.value = !showComments.value;
  }

  void setStreamQuality(String quality) {
    streamQuality.value = quality;
    // In a real implementation, you would adjust stream quality
    log('Stream quality set to: $quality');
  }

  void setPrivacyLevel(String privacy) {
    privacyLevel.value = privacy;
    // In a real implementation, you would update privacy settings
    log('Privacy level set to: $privacy');
  }

  void setPushNotifications(bool enabled) {
    pushNotifications.value = enabled;
  }

  void setEmailNotifications(bool enabled) {
    emailNotifications.value = enabled;
  }

  void updateDescription() {
    if (descriptionController.text.trim().isEmpty) return;

    // In a real implementation, you would update the stream description
    log('Description updated: ${descriptionController.text}');

    Get.snackbar(
      'Description Updated',
      'Your live stream description has been updated',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  void addComment(String text) {
    if (text.trim().isEmpty) return;

    final comment = {
      'user': 'You',
      'text': text,
      'timestamp': DateTime.now(),
    };

    comments.add(comment);

    // In a real implementation, you would send the comment to the server
    log('Comment added: $text');
  }

  Future<void> endLiveStream() async {
    try {
      _viewerCountTimer?.cancel();
      _commentTimer?.cancel();

      isStreaming.value = false;

      // Call API to end live stream
      if (_streamId != null) {
        await _apiService.postRequest('live/end', {
          'streamId': _streamId,
        });
      }

      log('Live stream ended');

      Get.snackbar(
        'Live Stream Ended',
        'Your live stream has been ended successfully',
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error ending live stream: $e');
      Get.snackbar(
        'Stream Error',
        'Failed to end live stream: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void dispose() {
    _viewerCountTimer?.cancel();
    _commentTimer?.cancel();
    cameraController?.dispose();
    descriptionController.dispose();
  }
}
