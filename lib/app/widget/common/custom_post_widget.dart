import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chys/app/widget/image/svg_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as th;
import 'package:path_provider/path_provider.dart';

import '../../core/const/app_image.dart';
import '../../data/models/post.dart';
import '../../modules/adored_posts/controller/controller.dart';
import '../../routes/app_routes.dart';

class CustomPostWidget extends StatefulWidget {
  final Posts posts;
  final bool isCurrentUser;
  final AddoredPostsController addoredPostsController;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapMessage;
  final VoidCallback? onTapShare;
  final VoidCallback? onTapLove;
  final VoidCallback? onTapPaw;

  const CustomPostWidget(
      {Key? key,
      required this.posts,
      required this.addoredPostsController,
      this.onTapCard,
      this.isCurrentUser = false,
      this.onTapMessage,
      this.onTapShare,
      this.onTapLove,
      this.onTapPaw})
      : super(key: key);

  @override
  State<CustomPostWidget> createState() => _CustomPostWidgetState();
}

class _CustomPostWidgetState extends State<CustomPostWidget>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  bool _showHeart = false;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  bool _showPlayPauseIcon = false;
  Timer? _playPauseIconTimer;
  final Map<String, String?> _videoThumbnails = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnimation = Tween<double>(begin: 0.7, end: 1.4).animate(
      CurvedAnimation(
          parent: _heartAnimationController, curve: Curves.elasticOut),
    );

    // Pre-generate thumbnails for video media
    for (final url in widget.posts.media.where(_isVideo)) {
      _generateVideoThumbnail(url);
    }
  }

  @override
  void dispose() {
    for (var url in widget.posts.media.where(_isVideo)) {
      widget.addoredPostsController.disposeVideoController(url);
    }
    // Cleanup generated thumbnails
    _videoThumbnails.values.whereType<String>().forEach((path) {
      try {
        final f = File(path);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    });
    _playPauseIconTimer?.cancel();
    _pageController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.mov', '.webm', '.avi'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  Future<void> _generateVideoThumbnail(String mediaUrl) async {
    if (_videoThumbnails.containsKey(mediaUrl)) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbPath = await th.VideoThumbnail.thumbnailFile(
        video: mediaUrl,
        thumbnailPath: tempDir.path,
        imageFormat: th.ImageFormat.JPEG,
        quality: 75,
        maxWidth: 600,
        maxHeight: 600,
        timeMs: 1000,
      );
      if (!mounted) return;
      setState(() {
        _videoThumbnails[mediaUrl] = thumbPath;
      });
    } catch (e) {
      log('Error generating inline video thumbnail: $e');
      if (!mounted) return;
      setState(() {
        _videoThumbnails[mediaUrl] = null;
      });
    }
  }

  void _onDoubleTapLike() {
    setState(() {
      _showHeart = true;
    });
    _heartAnimationController.forward(from: 0);
    widget.onTapLove?.call();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showHeart = false;
        });
      }
    });
  }

  void _showPlayPause() {
    setState(() {
      _showPlayPauseIcon = true;
    });
    _playPauseIconTimer?.cancel();
    _playPauseIconTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTapCard,
      child: Container(
        margin: EdgeInsets.zero,
        height: Get.height * 0.69,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.posts.media.length,
                onPageChanged: (index) {
                  widget.addoredPostsController.pauseAllVideos();
                  widget.addoredPostsController.currentIndex.value = index;
                },
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final mediaUrl = widget.posts.media[index];

                  if (_isVideo(mediaUrl)) {
                    widget.addoredPostsController
                        .initializeVideoController(mediaUrl);
                    return Obx(() {
                      final isInitialized = widget.addoredPostsController
                              .isVideoInitialized[mediaUrl] ??
                          false;
                      final controller = widget
                          .addoredPostsController.videoControllers[mediaUrl];
                      if (!isInitialized || controller == null) {
                        // Show generated thumbnail as placeholder instead of icon
                        final thumbPath = _videoThumbnails[mediaUrl];
                        if (thumbPath != null) {
                          return Image.file(
                            File(thumbPath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        }
                        return Container(color: Colors.grey[200]);
                      }
                      return ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: controller,
                        builder: (context, value, child) {
                          return Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onDoubleTap: _onDoubleTapLike,
                                onTap: () {
                                  if (value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    widget.addoredPostsController
                                        .addPostView(widget.posts.id);
                                    controller.play();
                                  }
                                  _showPlayPause();
                                },
                                child: AspectRatio(
                                  aspectRatio: value.aspectRatio,
                                  child: VideoPlayer(controller),
                                ),
                              ),

                              // Conditionally show pause or play icon based on _showPlayPauseIcon
                              if (_showPlayPauseIcon)
                                IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_showHeart)
                                ScaleTransition(
                                  scale: _heartScaleAnimation,
                                  child: const Icon(Icons.favorite,
                                      color: Colors.white, size: 100),
                                ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.remove_red_eye,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.posts.viewCount
                                            .toString(), // your views count here
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    });
                  }

                  // If it's not a video, show image
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onDoubleTap: _onDoubleTapLike,
                        child: Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      _showHeart
                          ? ScaleTransition(
                              scale: _heartScaleAnimation,
                              child: const Icon(Icons.favorite,
                                  color: Colors.white, size: 100),
                            )
                          : const SizedBox.shrink(),
                    ],
                  );
                },
              ),
            ),

            if (widget.posts.media.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          widget.posts.media.length,
                          (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.addoredPostsController
                                              .currentIndex.value ==
                                          index
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.5),
                                ),
                              )),
                    )),
              ),

            // Post Description
            Positioned(
              left: 20,
              right: 80,
              bottom: 80,
              child: Text(
                widget.posts.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Creator Info
            Positioned(
              left: 20,
              bottom: 20,
              child: InkWell(
                onTap: () {
                  log("Id is ==>${widget.posts.creator.id}");
                  Get.toNamed(AppRoutes.otherUserProfile,
                      arguments: widget.posts.creator.id);
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(widget.posts.creator.profilePic),
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.posts.creator.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.posts.creator.bio,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (!widget.isCurrentUser)
              Positioned(
                right: 10,
                bottom: 5,
                child: Column(
                  children: [
                    Obx(() => _circleIcon(
                          AppImages.gift,
                          () {
                            if (widget.posts.isFunded.value) {
                              return;
                            } else {
                              widget.addoredPostsController
                                  .fundPost(widget.posts, context);
                            }
                          },
                          bgColor: widget.posts.isFunded.value
                              ? Colors.red
                              : Colors.white,
                        )),
                    Obx(() => Text(
                          widget.posts.fundCount.value.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        )),
                    const SizedBox(height: 12),
                    _circleIcon(AppImages.message, widget.onTapMessage),
                    Obx(() => Text(
                          widget.posts.comments.length.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        )),
                    const SizedBox(height: 12),
                    _circleIcon(AppImages.share, widget.onTapShare),
                    const SizedBox(height: 12),
                    _circleIcon(
                      AppImages.love,
                      widget.onTapLove,
                      bgColor:
                          widget.posts.isCurrentUserLiked ? Colors.red : null,
                    ),
                    Obx(() => Text(
                          widget.posts.likes.length.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        )),
                  ],
                ),
              ),
            if (widget.isCurrentUser)
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 28),
                  onPressed: () {
                    Get.toNamed(AppRoutes.addPost, arguments: widget.posts);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _circleIcon(
    String icon,
    VoidCallback? onTap, {
    Color? bgColor,
    bool isLoading = false,
  }) {
    final Color finalBgColor = bgColor ?? Colors.white.withOpacity(0.6);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: const BoxDecoration(
          // color: finalBgColor,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Icon(
                    Icons.hourglass_empty,
                    color: Colors.grey,
                    size: 16,
                  ),
                ),
              )
            : IconButton(
                onPressed: onTap,
                icon: icon.toSvg(color: bgColor),
                color: Colors.black87,
              ),
      ),
    );
  }
}
