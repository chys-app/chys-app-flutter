import 'package:chys/app/test_video/video_controller.dart';
import 'package:chys/app/test_video/video_player_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoPageView extends StatefulWidget {
  final Function(int) onPageChanged;

  const VideoPageView({
    super.key,
    required this.onPageChanged,
  });

  @override
  State<VideoPageView> createState() => _VideoPageViewState();
}

class _VideoPageViewState extends State<VideoPageView> {
  late PageController _pageController;
  final videoController = Get.find<VideoPlayerControllerX>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    final newIndex = _pageController.page?.round() ?? 0;

    if (newIndex != videoController.currentIndex) {
      videoController.changeVideo(newIndex);
      widget.onPageChanged(newIndex);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: videoController.videoUrls.length,
      itemBuilder: (context, index) => VideoPlayerItem(index: index),
    );
  }
}
