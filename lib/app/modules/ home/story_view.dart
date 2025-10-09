import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../services/custom_Api.dart';
import '../../core/const/app_colors.dart';

class StoryPreviewPage extends StatefulWidget {
  final List<String> mediaUrls;
  final String userName;
  final List<String>? storyIds; // Optional story IDs for tracking views
  final List<int>? viewCounts; // Optional view counts for each story

  StoryPreviewPage({
    Key? key,
    required this.mediaUrls,
    required this.userName,
    this.storyIds,
    this.viewCounts,
  }) : super(key: key);

  @override
  State<StoryPreviewPage> createState() => _StoryPreviewPageState();
}

class _StoryPreviewPageState extends State<StoryPreviewPage> {
  final StoryController _storyController = StoryController();
  final CustomApiService _apiService = Get.put(CustomApiService());
  int _currentIndex = 0;
  Set<String> _viewedStoryIds = {}; // Track which stories have been viewed

  @override
  void initState() {
    super.initState();
    // Track the first story view when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackStoryView(0);
    });
  }

  /// Track story view when user views a story
  void _trackStoryView(int index) {
    if (widget.storyIds != null &&
        index < widget.storyIds!.length &&
        index < widget.mediaUrls.length) {
      final storyId = widget.storyIds![index];

      // Only track if not already viewed in this session
      if (!_viewedStoryIds.contains(storyId)) {
        _viewedStoryIds.add(storyId);

        // Track the view asynchronously - don't let errors affect the UI
        _apiService.trackStoryView(storyId).then((result) {
          log("✅ [STORY VIEW] Successfully tracked view for story: $storyId");
        }).catchError((error) {
          log("⚠️ [STORY VIEW] Failed to track view for story $storyId: $error");
          // Don't remove from viewed set - just log the error and continue
        });
      }
    }
  }

  /// Get view count for current story
  int _getCurrentViewCount() {
    if (widget.viewCounts != null &&
        _currentIndex < widget.viewCounts!.length) {
      return widget.viewCounts![_currentIndex];
    }
    return 0;
  }

  /// Format view count for display
  String _formatViewCount(int count) {
    if (count == 0) return 'No views';
    if (count == 1) return '1 view';
    if (count < 1000) return '$count views';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K views';
    return '${(count / 1000000).toStringAsFixed(1)}M views';
  }

  // Get screen dimensions - 80% height, full width
  double get _screenHeight => MediaQuery.of(Get.context!).size.height ; // 80% of screen height
  double get _screenWidth => MediaQuery.of(Get.context!).size.width; // Full width


  // Full screen image widget
  Widget _buildImageWidget(String url) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background,
      child: Stack(
        children: [
          // Full screen image
          Positioned.fill(
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.background,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 50,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load story',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Stack(
          children: [
            // Story content - 80% height, full width
            Positioned.fill(
              child: Center(
                child: Container(
                  width: _screenWidth,
                  height: _screenHeight,
                  child: PageView.builder(
                    itemCount: widget.mediaUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                      // Track story view when user navigates to a story
                      _trackStoryView(index);
                    },
                    itemBuilder: (context, index) {
                      final url = widget.mediaUrls[index];
                      final isVideo = url.endsWith(".mp4") || url.contains("video");

                      return Container(
                        width: _screenWidth,
                        height: _screenHeight,
                        color: AppColors.background,
                        child: isVideo
                            ? VideoPlayerWidget(url: url)
                            : _buildImageWidget(url),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Progress indicators - App theme style
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.mediaUrls.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: index <= _currentIndex
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // App theme header - Name only
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'now',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View count display
                  if (widget.viewCounts != null &&
                      widget.viewCounts!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            color: AppColors.primary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatViewCount(_getCurrentViewCount()),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Video player widget with proper video playback
class VideoPlayerWidget extends StatefulWidget {
  final String url;

  VideoPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Auto-play the video
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
        
        // Listen for video completion
        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            // Video finished, restart it for stories
            _controller.seekTo(Duration.zero);
            _controller.play();
          }
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_isInitialized) {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 50,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background, // White background like images
        child: Stack(
          children: [
            // Video player - full screen like images
            Positioned.fill(
              child: VideoPlayer(_controller),
            ),
            
            // Play/Pause overlay
            if (!_isPlaying)
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
