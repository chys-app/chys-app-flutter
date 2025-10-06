import 'package:chys/app/test_video/video_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'video_page_view.dart';

class VideoFeedScreen extends StatelessWidget {
  const VideoFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<VideoPlayerControllerX>(
        builder: (videoController) {
          return VideoPageView(
            onPageChanged: videoController.changeVideo,
          );
        },
      ),
    );
  }
}
