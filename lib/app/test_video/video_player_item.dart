import 'package:chys/app/test_video/video_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatelessWidget {
  final int index;

  const VideoPlayerItem({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final videoController = Get.find<VideoPlayerControllerX>();
    final controller = videoController.controllers[index];

    // Show loading indicator if controller is not ready
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading video...'),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player with tap toggle
        GestureDetector(
          onTap: () => videoController.togglePlayPause(index),
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        // Play/pause overlay icon
        if (!controller.value.isPlaying)
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 80,
              color: Colors.white70,
            ),
          ),

        // Video index indicator (top-right)
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Video ${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
