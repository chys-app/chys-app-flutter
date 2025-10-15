import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../services/custom_Api.dart';

class StoryPreviewPage extends StatefulWidget {
  final List<String> mediaUrls;
  final String userName;
  final List<String>? storyIds; // Optional story IDs for tracking views
  final List<int>? viewCounts; // Optional view counts for each story

  const StoryPreviewPage({
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
  final Set<String> _viewedStoryIds = {}; // Track which stories have been viewed

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
        
        // Track the view asynchronously
        _apiService.trackStoryView(storyId).catchError((error) {
          print('Failed to track story view: $error');
          // Remove from viewed set so it can be retried
          _viewedStoryIds.remove(storyId);
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

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return const Scaffold(
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
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // Full screen story content
            Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
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
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                      child: isVideo
                          ? VideoPlayerWidget(url: url)
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.white,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.white,
                                child: const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Colors.black,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
            // Progress indicators
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(widget.mediaUrls.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentIndex 
                            ? Colors.black 
                            : Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Instagram-like header
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'now',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View count display
                  if (widget.viewCounts != null && widget.viewCounts!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatViewCount(_getCurrentViewCount()),
                            style: const TextStyle(
                              color: Colors.white,
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
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
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

// Simple video player widget
class VideoPlayerWidget extends StatelessWidget {
  final String url;
  
  const VideoPlayerWidget({Key? key, required this.url}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: Colors.black,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Story',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to play video',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
