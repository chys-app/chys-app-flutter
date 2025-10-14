import 'dart:developer';
import 'dart:io';

import 'package:chys/app/data/models/post.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:http/http.dart' as http;

class PostGridWidget extends StatefulWidget {
  final Posts post;
  final AddoredPostsController addoredPostsController;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapMessage;
  final VoidCallback? onTapShare;
  final VoidCallback? onTapLove;
  final VoidCallback? onTapPaw;
  final bool disableThumbnailGeneration;

  const PostGridWidget({
    Key? key,
    required this.post,
    required this.addoredPostsController,
    this.onTapCard,
    this.onTapMessage,
    this.onTapShare,
    this.onTapLove,
    this.onTapPaw,
    this.disableThumbnailGeneration = false,
  }) : super(key: key);

  @override
  State<PostGridWidget> createState() => _PostGridWidgetState();
}

class _PostGridWidgetState extends State<PostGridWidget> {
  String? _thumbnailPath;
  bool _isGeneratingThumbnail = false;
  bool _hasTriedThumbnail = false;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  bool _isVideo(String url) {
    if (url.isEmpty) return false;
    final videoExtensions = ['.mp4', '.mov', '.webm', '.avi', '.mkv', '.flv'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  bool _isValidUrl(String url) {
    try {
      return url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.disableThumbnailGeneration) {
      _generateThumbnail();
    }
  }

  @override
  void dispose() {
    // Clean up thumbnail file if it exists
    if (_thumbnailPath != null) {
      try {
        final file = File(_thumbnailPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        log("Error cleaning up thumbnail: $e");
      }
    }
    super.dispose();
  }

  Future<void> _generateThumbnail() async {
    log("Generating thumbnail for video (attempt ${_retryCount + 1})");
    final mediaUrl = widget.post.media.isNotEmpty ? widget.post.media[0] : '';
    if (!_isVideo(mediaUrl) || mediaUrl.isEmpty || !_isValidUrl(mediaUrl)) {
      log("Not a valid video URL: $mediaUrl");
      return;
    }

    // Check if we already have a thumbnail for this video
    if (_thumbnailPath != null) return;

    // Check if we've exceeded max retries
    if (_retryCount >= _maxRetries) {
      log("Max retries exceeded for thumbnail generation");
      return;
    }

    setState(() {
      _isGeneratingThumbnail = true;
      _hasTriedThumbnail = true;
    });

    try {
      // First, try to validate the URL is accessible
      try {
        final response = await http.head(Uri.parse(mediaUrl));
        if (response.statusCode != 200) {
          log("Video URL not accessible: ${response.statusCode}");
          if (mounted) {
            setState(() {
              _isGeneratingThumbnail = false;
            });
          }
          return;
        }
      } catch (e) {
        log("Error checking video URL accessibility: $e");
        // Continue anyway, the video_thumbnail package might handle it
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'thumbnail_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      log("Attempting to generate thumbnail for: $mediaUrl");
      log("Post ID: ${widget.post.id}");
      log("Thumbnail will be saved to: ${tempDir.path}");
      
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: mediaUrl,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 300,
        maxHeight: 300,
        timeMs: 1000, // Generate thumbnail at 1 second mark for better preview
      );

      log("Thumbnail generated: $thumbnailPath");

      if (mounted && thumbnailPath != null) {
        // Verify the file exists and has content
        final file = File(thumbnailPath);
        if (await file.exists() && await file.length() > 0) {
          setState(() {
            _thumbnailPath = thumbnailPath;
            _isGeneratingThumbnail = false;
          });
          log("Thumbnail successfully generated and saved");
        } else {
          log("Thumbnail file is empty or doesn't exist");
          if (mounted) {
            setState(() {
              _isGeneratingThumbnail = false;
            });
          }
          // Retry if we haven't exceeded max retries
          if (_retryCount < _maxRetries - 1) {
            _retryCount++;
            await Future.delayed(const Duration(seconds: 1));
            _generateThumbnail();
          }
        }
      } else {
        log("Thumbnail generation returned null");
        if (mounted) {
          setState(() {
            _isGeneratingThumbnail = false;
          });
        }
        // Retry if we haven't exceeded max retries
        if (_retryCount < _maxRetries - 1) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          _generateThumbnail();
        }
      }
    } catch (e) {
      log("Error generating thumbnail: $e");
      if (mounted) {
        setState(() {
          _isGeneratingThumbnail = false;
        });
      }
      // Retry if we haven't exceeded max retries
      if (_retryCount < _maxRetries - 1) {
        _retryCount++;
        await Future.delayed(const Duration(seconds: 1));
        _generateThumbnail();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = widget.post.media.isNotEmpty ? widget.post.media[0] : '';
    final isVideo = _isVideo(mediaUrl);

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.postPreview, arguments: {
          'postId': widget.post.id,
          'controller': widget.addoredPostsController,
        });
      },
      child: Container(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main image/video
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: mediaUrl.isNotEmpty
                    ? _buildMediaContent(mediaUrl, isVideo)
                    : _buildFallbackImage(),
              ),

              // Removed persistent video badge; show clean thumbnail instead

              // Multiple media indicator
              if (widget.post.media.length > 1)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.collections,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.post.media.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient overlay for better text visibility
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Post description
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  widget.post.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Creator info
              Positioned(
                bottom: 32,
                left: 8,
                right: 8, // Add this to provide width constraints
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(widget.post.creator.profilePic),
                      radius: 12,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        widget.post.creator.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats overlay
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_red_eye,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        widget.post.viewCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Like indicator
              if (widget.post.isCurrentUserLiked)
                Positioned(
                  top: 8,
                  left: 50,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 10,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'LIKED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(String mediaUrl, bool isVideo) {
    if (isVideo) {
      // For videos, show thumbnail if available, otherwise show loading or fallback
      if (_thumbnailPath != null) {
        return GestureDetector(
          onTap: () => _showImageInFullScreen(mediaUrl, isVideo: true),
          child: Image.file(
            File(_thumbnailPath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              log("Error loading thumbnail file: $error");
              return _buildVideoFallback();
            },
          ),
        );
      } else if (_isGeneratingThumbnail && !widget.disableThumbnailGeneration) {
        return _buildVideoLoading();
      } else {
        return _buildVideoFallback();
      }
    } else {
      // For images, show network image with tap to view full screen
      return GestureDetector(
        onTap: () => _showImageInFullScreen(mediaUrl),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            log("Error loading network image: $error");
            return _buildFallbackImage();
          },
        ),
      );
    }
  }

  Widget _buildVideoLoading() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFallback() {
    // Minimal neutral placeholder without icons/text
    return Container(color: Colors.grey[200]);
  }

  void _showImageInFullScreen(String mediaUrl, {bool isVideo = false}) {
    // Always navigate to post preview page for both images and videos
    Get.toNamed(AppRoutes.postPreview, arguments: {
      'postId': widget.post.id,
      'controller': widget.addoredPostsController,
    });
  }

  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}


