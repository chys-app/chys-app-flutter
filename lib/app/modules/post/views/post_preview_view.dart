import 'dart:async';

import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/widget/image/svg_extension.dart';
import 'package:chys/app/widget/common/pet_profile_widget.dart';
import 'package:chys/app/widget/shimmer/post_preview_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart';
import 'package:video_player/video_player.dart';

class PostPreviewView extends StatefulWidget {
  const PostPreviewView({Key? key}) : super(key: key);

  @override
  State<PostPreviewView> createState() => _PostPreviewViewState();
}

class _PostPreviewViewState extends State<PostPreviewView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;
  bool _showHeart = false;
  bool _showPlayPauseIcon = false;
  Timer? _playPauseIconTimer;
  late AddoredPostsController controller;
  late String postId;

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

    // Get arguments
    final arguments = Get.arguments as Map<String, dynamic>;
    controller = arguments['controller'] as AddoredPostsController;
    postId = arguments['postId'] as String;

    // Fetch single post
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSinglePost(postId);
    });
  }

  @override
  void dispose() {
    final post = controller.singlePost.value;
    if (post != null) {
      for (var url in post.media.where(_isVideo)) {
        controller.disposeVideoController(url);
      }
    }
    _playPauseIconTimer?.cancel();
    _pageController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.mov', '.webm', '.avi'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  void _onDoubleTapLike() {
    final post = controller.singlePost.value;
    if (post == null) return;
    setState(() {
      _showHeart = true;
    });
    _heartAnimationController.forward(from: 0);
    controller.likeSinglePost();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted)
        setState(() {
          _showHeart = false;
        });
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
    return Obx(() {
      if (controller.isSinglePostLoading.value) {
        return const PostPreviewShimmer();
      }
      final post = controller.singlePost.value;

      if (post == null) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.black,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load post',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0095F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Full screen media content
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: post.media.length,
                onPageChanged: (index) {
                  controller.pauseAllVideos();
                  controller.currentIndex.value = index;
                },
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final mediaUrl = post.media[index];

                  if (_isVideo(mediaUrl)) {
                    controller.initializeVideoController(mediaUrl);
                    return Obx(() {
                      final isInitialized =
                          controller.isVideoInitialized[mediaUrl] ?? false;
                      final videoController =
                          controller.videoControllers[mediaUrl];
                      if (!isInitialized || videoController == null) {
                        return Container(
                          color: Colors.white,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.black,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading video...',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: videoController,
                        builder: (context, value, child) {
                          return Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onDoubleTap: _onDoubleTapLike,
                                onTap: () {
                                  if (value.isPlaying) {
                                    videoController.pause();
                                  } else {
                                    controller.addPostView(post.id);
                                    videoController.play();
                                  }
                                  _showPlayPause();
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: videoController.value.size.width,
                                      height: videoController.value.size.height,
                                      child: VideoPlayer(videoController),
                                    ),
                                  ),
                                ),
                              ),
                              if (!value.isPlaying)
                                IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: const Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_showPlayPauseIcon)
                                IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(16),
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
                                      color: Colors.red, size: 100),
                                ),
                              // Description and stats overlay on video
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
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
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Description
                                      ReadMoreText(
                                        post.description,
                                        trimLines: 3,
                                        colorClickableText: Colors.white,
                                        trimMode: TrimMode.Line,
                                        trimCollapsedText: ' Show more',
                                        trimExpandedText: ' Show less',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.4,
                                          fontWeight: FontWeight.w400,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                        moreStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                        lessStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Stats
                                      Obx(() => Row(
                                            children: [
                                              // Views
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.remove_red_eye,
                                                    color: Colors.white70,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${post.viewCount} views',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(0, 1),
                                                          blurRadius: 2,
                                                          color: Colors.black54,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 20),
                                              // Likes
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.favorite,
                                                    color:
                                                        post.isCurrentUserLiked
                                                            ? Colors.red
                                                            : Colors.white70,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${post.likes.length} likes',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(0, 1),
                                                          blurRadius: 2,
                                                          color: Colors.black54,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 20),
                                              // Comments
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.comment,
                                                    color: Colors.white70,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${post.comments.length} comments',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(0, 1),
                                                          blurRadius: 2,
                                                          color: Colors.black54,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )),
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

                  // Image display
                  return Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onDoubleTap: _onDoubleTapLike,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.network(
                            mediaUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.white,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.black,
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (_showHeart)
                        ScaleTransition(
                          scale: _heartScaleAnimation,
                          child: const Icon(Icons.favorite,
                              color: Colors.red, size: 100),
                        ),
                      // Description and stats overlay on media
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Description
                              ReadMoreText(
                                post.description,
                                trimLines: 3,
                                colorClickableText: Colors.white,
                                trimMode: TrimMode.Line,
                                trimCollapsedText: ' Show more',
                                trimExpandedText: ' Show less',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                moreStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                lessStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Stats
                              Obx(() => Row(
                                    children: [
                                      // Views
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.remove_red_eye,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.viewCount} views',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 2,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: post.isCurrentUserLiked
                                                ? Colors.red
                                                : Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.likes.length} likes',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 2,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      // Comments
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.comment,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.comments.length} comments',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(0, 1),
                                                  blurRadius: 2,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Header overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User profile section
                    Expanded(
                      child: PetProfileWidget(
                        post: post,
                        textColor: Colors.white,
                        bioColor: Colors.white.withOpacity(0.7),
                      ),
                    ),

                    ],
                ),
              ),
            ),

            // Action buttons on the right with improved design
            Positioned(
              right: 16,
              bottom: 80,
              child: Obx(() => Column(
                    children: [
                      // Fund button
                      _buildActionButton(
                        AppImages.gift,
                        post.fundCount.value.toString(),
                        () {
                          if (post.isFunded.value) {
                            return;
                          } else {
                            controller.fundPost(post, context);
                          }
                        },
                        isActive: post.isFunded.value,
                      ),
                      const SizedBox(height: 16),

                      // Comment button
                      _buildActionButton(
                        AppImages.message,
                        post.comments.length.toString(),
                        () {
                          controller.showCommentsBottomSheet(post);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Share button
                      _buildActionButton(
                        AppImages.share,
                        '',
                        () {
                          controller.sharePost(post);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Like button
                      _buildActionButton(
                        AppImages.love,
                        post.likes.length.toString(),
                        () {
                          controller.likeSinglePost();
                        },
                        isActive: post.isCurrentUserLiked,
                      ),
                    ],
                  )),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton(
    String icon,
    String count,
    VoidCallback? onTap, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon.toSvg(
                color: isActive ? Colors.white : Colors.black,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _circleIcon(
    String icon,
    VoidCallback? onTap, {
    Color? bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: InkWell(
            splashColor: Colors.transparent,
            onTap: onTap,
            child: icon.toSvg(color: bgColor)),
      ),
    );
  }
}
