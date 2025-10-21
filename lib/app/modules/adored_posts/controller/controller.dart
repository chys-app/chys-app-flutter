import 'dart:developer';
import 'dart:io';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/data/models/post.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/short_message_utils.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart'; // Removed - deprecated
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/const/app_colors.dart';
import '../../../services/http_service.dart';
import '../../../services/payment_services.dart';
import '../../signup/widgets/custom_text_field.dart';
import 'package:chys/app/data/models/pet_profile.dart';

class AddoredPostsController extends GetxController {
  final CustomApiService customApiService = CustomApiService();
  final ScrollController homeScroll = ScrollController();
  final ScrollController profileScroll = ScrollController();
  final RxList<Posts> posts = <Posts>[].obs;
  final RxList<Posts> favoritePosts = <Posts>[].obs;
  final RxList<Map<String, dynamic>> favoritePostsRaw =
      <Map<String, dynamic>>[].obs;
  final Rxn<Posts> singlePost = Rxn<Posts>();

  final TextEditingController commentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  RxInt currentIndex = 0.obs;
  RxBool isLoading = false.obs;
  
  // Caching and API management
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const Duration _cacheExpiryShort = Duration(minutes: 2);

  final RxMap<String, VideoPlayerController> videoControllers =
      <String, VideoPlayerController>{}.obs;
  final RxMap<String, bool> isVideoInitialized = <String, bool>{}.obs;

  void updateIndex(int index) {
    currentIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    // Clear expired cache on initialization
    _clearExpiredCache();
  }

  // Tab index for For You / Following
  final RxInt tabIndex = 0.obs;

  // View mode toggle (list vs grid)
  final RxBool isGridView = false.obs;

  void clearUserFiltering() {
    log("Clearing user filtering to show all posts");
    // Clear any user-specific filtering and fetch all posts
    fetchAdoredPosts(userId: "", followingOnly: false, forceRefresh: true);
  }

  void onTabChange(int index) {
    tabIndex.value = index;
    if (index == 0) {
      // Hot picks - show all posts (clear user filtering)
      fetchAdoredPosts(userId: "", followingOnly: false, forceRefresh: false);
      print('Hot picks selected');
    } else if (index == 1) {
      // Favorites - show favorited posts
      fetchFavoritePosts();
      print('Favorites selected');
    }
    // index == 2 is Podcasts, handled separately in home view
  }

  void toggleViewMode() {
    isGridView.value = !isGridView.value;
  }

  RxBool isSinglePostLoading = false.obs;

  Future<void> fetchSinglePost(String postId, {bool forceRefresh = false}) async {
    try {
      final String cacheKey = "single_post_$postId";
      
      // Check cache first (unless force refresh)
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        log("📦 Using cached single post data");
        final cachedData = _cache[cacheKey];
        if (cachedData != null) {
          singlePost.value = cachedData;
          return;
        }
      }

      log("🔄 Fetching single post from API...");
      isSinglePostLoading.value = true;

      final String endPoint = "posts/$postId";
      log("📡 Endpoint is $endPoint");

      final response = await customApiService.getRequest(endPoint);
      final newPost = Posts.fromMap(response);

      // Update post and cache
      singlePost.value = newPost;
      _cache[cacheKey] = newPost;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      log("✅ Single post fetched and cached successfully");
    } catch (e) {
      log("❌ Error fetching single post: $e");
      // Try to use cached data if available
      final cacheKey = "single_post_$postId";
      if (_cache.containsKey(cacheKey)) {
        log("🔄 Using fallback cached single post data");
        singlePost.value = _cache[cacheKey];
      } else {
        singlePost.value = null;
      }
    } finally {
      isSinglePostLoading.value = false;
    }
  }

  Future<void> fetchAdoredPosts(
      {String userId = "", bool followingOnly = false, bool forceRefresh = false}) async {
    try {
      final String cacheKey = "posts_${userId}_${followingOnly}";
      
      // Check cache first (unless force refresh)
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        final cachedData = _cache[cacheKey];
        if (cachedData != null) {
          posts.value = cachedData;
          return;
        }
      }
      isLoading.value = true;

      String endPoint = userId.isEmpty
          ? "posts?followingOnly=$followingOnly&limit=0"
          : "posts/user/$userId?limit=0";

      var response = await customApiService.getRequest(endPoint);

      final List<dynamic> postsData = response["posts"];
      final List<Posts> newPosts = postsData.map((e) => Posts.fromMap(e)).toList();

      // Log media URLs for debugging
      log("📸 Loaded ${newPosts.length} posts");
      for (var i = 0; i < newPosts.length; i++) {
        final post = newPosts[i];
        log("📝 Post ${i + 1} (ID: ${post.id}):");
        log("   - Description: ${post.description.length > 50 ? post.description.substring(0, 50) + '...' : post.description}");
        log("   - Media count: ${post.media.length}");
        for (var j = 0; j < post.media.length; j++) {
          log("   - Media ${j + 1}: ${post.media[j]}");
        }
      }

      // Update posts and cache
      posts.value = newPosts;
      _cache[cacheKey] = newPosts;
      _cacheTimestamps[cacheKey] = DateTime.now();
    } catch (e) {
      log("❌ Error fetching adored posts: $e");
      // Try to use cached data if available
      final cacheKey = "posts_${userId}_${followingOnly}";
      if (_cache.containsKey(cacheKey)) {
        posts.value = _cache[cacheKey];
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    final expiry = key.contains('single') ? _cacheExpiryShort : _cacheExpiry;
    return DateTime.now().difference(timestamp) < expiry;
  }

  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void _clearExpiredCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      final expiry = key.contains('single') ? _cacheExpiryShort : _cacheExpiry;
      if (now.difference(timestamp) > expiry) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Public methods for cache management
  Future<void> refreshPosts({bool followingOnly = false}) async {
    await fetchAdoredPosts(followingOnly: followingOnly, forceRefresh: true);
  }

  Future<void> refreshSinglePost(String postId) async {
    await fetchSinglePost(postId, forceRefresh: true);
  }

  void clearAllCache() {
    _clearCache();
  }

  void clearExpiredCache() {
    _clearExpiredCache();
  }

  // Public method to check cache age
  Duration? getCacheAge(String cacheKey) {
    if (!_cacheTimestamps.containsKey(cacheKey)) {
      return null;
    }
    final timestamp = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(timestamp);
  }

  Future<void> likePost(String postId) async {
    log("🟠 likePost triggered for postId: $postId");

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) {
      log("⚠️ Post not found with postId: $postId");
      return;
    }

    // Ensure ProfileController is registered
    if (!Get.isRegistered<ProfileController>()) {
      log("🔁 ProfileController not registered, initializing...");
      Get.put(ProfileController());
    }

    final profile = Get.find<ProfileController>().profile.value;
    final currentUserId = profile?.id;
    if (currentUserId == null) {
      log("❌ Current user ID is null, cannot like post.");
      return;
    }

    final post = posts[index];

    // Normalize existing likes (Map → String)
    post.likes.value = post.likes.map((like) {
      if (like is Map && like.containsKey('_id')) {
        return like['_id'];
      }
      return like;
    }).toList();

    log("👤 Current User ID: $currentUserId");
    log("📝 Current like state: ${post.isCurrentUserLiked}");
    log("❤️ Likes before update: ${post.likes}");

    // Check if already liked
    final wasLiked = post.likes.contains(currentUserId);
    post.isCurrentUserLiked = !wasLiked;

    if (wasLiked) {
      post.likes.remove(currentUserId);
      log("💔 Removed like for user: $currentUserId");
    } else {
      post.likes.add(currentUserId);
      log("💖 Added like for user: $currentUserId");
    }

    posts.refresh();
    log("🔄 UI updated. Current likes: ${post.likes}");

    // Call API in background
    try {
      final response =
          await customApiService.postRequest("posts/$postId/like", {});
      log("✅ Like API response: $response");
    } catch (e) {
      // Revert state if API fails
      log("❌ Error liking post, reverting UI: $e");

      post.isCurrentUserLiked = wasLiked;
      if (wasLiked) {
        post.likes.add(currentUserId);
      } else {
        post.likes.remove(currentUserId);
      }
      posts.refresh();
      log("↩️ UI reverted. Current likes: ${post.likes}");
    }
  }

  Future<void> toggleFavorite(String postId) async {
    log("⭐ toggleFavorite triggered for postId: $postId");

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) {
      log("⚠️ Post not found with postId: $postId");
      return;
    }

    final post = posts[index];
    final wasFavorited = post.isFavorite;

    // Optimistically update UI
    post.isFavorite = !wasFavorited;
    posts.refresh();
    log("🔄 UI updated. Favorite state: ${post.isFavorite}");

    // Call API in background
    try {
      final response = await ApiClient().favoritePost(postId);
      log("✅ Favorite API response: $response");
      
      // If we're on the Favorites tab and unfavoriting, refresh the list
      if (tabIndex.value == 1 && !post.isFavorite) {
        await fetchFavoritePosts();
      }
    } catch (e) {
      // Revert state if API fails
      log("❌ Error toggling favorite, reverting UI: $e");
      post.isFavorite = wasFavorited;
      posts.refresh();
      log("↩️ UI reverted. Favorite state: ${post.isFavorite}");
    }
  }

  Future<void> fundRaise(String postId, BuildContext context) async {
    final amount = int.tryParse(amountController.text.trim());
    if (amount != null && amount <= 1) {
      ShortMessageUtils.showError("The minimum fundraising  is 1");
      return;
    }
    try {
      Get.find<LoadingController>().show();
      PaymentServices.stripePayment(
          amountController.text.trim(), "dummy_donationId", context,
          onSuccess: () async {
        await ApiClient().post("${ApiEndPoints.fundRaise}/post/$postId", {
          "amount": amountController.text.trim(),
        });
      });
      Get.find<LoadingController>().hide();
      Get.back();
    } catch (e) {
      Get.find<LoadingController>().hide();
      log("The error is $e");
    }
  }

  Future<void> commentOnPost(String postId, Posts post) async {
    if (commentController.text.trim().isEmpty) {
      return;
    }

    // Ensure ProfileController is registered
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }

    final profile = Get.find<ProfileController>().profile.value;
    final commentText = commentController.text.trim();

    // Get the appropriate display name (pet name if available, otherwise user name)
    String displayName = 'Unknown';
    String profilePic = '';
    
    if (profile != null) {
      // First try to get pet name from ProfileController
      final profileController = Get.find<ProfileController>();
      if (profileController.userPet.value?.name != null && 
          profileController.userPet.value!.name!.isNotEmpty) {
        displayName = profileController.userPet.value!.name!;
        profilePic = profileController.userPet.value!.profilePic ?? profile.profilePic ?? '';
        log("🐾 Using pet profile for comment - Name: $displayName, ProfilePic: $profilePic");
      } else {
        // Fallback to user name if no pet
        displayName = profile.name.isNotEmpty ? profile.name : 'Unknown';
        profilePic = profile.profilePic ?? '';
        log("👤 Using user profile for comment - Name: $displayName, ProfilePic: $profilePic");
      }
    }

    // Create new comment with Instagram-like structure
    final newComment = {
      "message": commentText,
      "createdAt": DateTime.now().toIso8601String(),
      "user": {
        "_id": profile?.id ?? '',
        "name": displayName,
        "profilePic": profilePic,
      },
      "_id": UniqueKey().toString(), // Temporary ID for UI
      "likes": <String>[], // Instagram-like likes array
      "replies": <Map<String, dynamic>>[], // Instagram-like replies array
    };

    // Clear input immediately for better UX
    commentController.clear();

    // Optimistically update UI (Instagram-like immediate feedback)
    post.comments.add(newComment);
    
    // Scroll to bottom to show new comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Scroll to bottom of comments list
    });

    // Call API in background
    try {
      final response = await customApiService.postRequest(
        "posts/$postId/comment",
        {"message": commentText},
      );

      // Update the comment with actual ID from response if available
      if (response != null && response["_id"] != null) {
        newComment["_id"] = response["_id"];
      }
      
      // Close the comment bottom sheet after successful comment submission
      Get.back();
      
      // Show success feedback (optional)
      // Get.snackbar('Comment posted', '', duration: Duration(seconds: 1));
      
    } catch (e) {
      // Revert state if API fails
      post.comments.remove(newComment);
      log("❌ Error posting comment: $e");
      
      // Show error feedback
      Get.snackbar(
        'Error', 
        'Failed to post comment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void sharePost(Posts post) async {
    try {
      log("Post id ${post.id}");
      // STEP 1: Generate simple share URL (Firebase Dynamic Links removed)
      final String postUrl = 'https://chys.app/post/${post.id}';
      log("Post url is $postUrl");
      // STEP 2: Combine description + link
      final String contentToShare = '''
${post.description ?? ''}

Check it out: $postUrl

Shared via CHYS app
''';

      XFile? previewFile;

      // STEP 3: If media exists, download first media
      if (post.media.isNotEmpty) {
        final mediaUrl = post.media[0];
        final mediaResponse = await http.get(Uri.parse(mediaUrl));

        final bytes = mediaResponse.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/shared_preview.jpg');
        await file.writeAsBytes(bytes);

        previewFile = XFile(file.path);
      }

      // STEP 4: Share content
      await Share.shareXFiles(
        previewFile != null ? [previewFile] : [],
        text: contentToShare,
      );
    } catch (e) {
      log("Error sharing post: $e");
      ShortMessageUtils.showError("Failed to share post");
    }
  }

  void showCommentsBottomSheet(Posts post) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: Get.height * 0.4,
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText(
                  text: 'Comments',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: const Icon(
                      Icons.cancel,
                      color: AppColors.error,
                    ))
              ],
            ),
            const SizedBox(height: 2),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 4),
            // Comments List
            Expanded(
              child: Obx(() {
                if (post.comments.isEmpty) {
                  return const Center(
                    child: AppText(
                      text: 'No comments yet.',
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: post.comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, index) {
                    final comment = post.comments[index];
                    log("Comment is $comment");
                    
                    // Process comment data to ensure proper structure
                    final processedComment = _processCommentData(comment);
                    final user = processedComment['user'] ?? {};
                    final username = user['name'] ?? 'User';
                    final avatarUrl = user['profilePic'] ?? null;
                    final message = processedComment['message'] ?? '';
                    final createdAt = processedComment['createdAt'];
                    String timeString = '';
                    if (createdAt != null) {
                      try {
                        timeString = DateFormat('MMM d, yyyy  h:mm a')
                            .format(DateTime.parse(createdAt));
                      } catch (_) {}
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          _buildCommentAvatar(avatarUrl, comment['user']?['name'] ?? 'User'),
                          const SizedBox(width: 12),
                          // Comment content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AppText(
                                      text: username,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    if (timeString.isNotEmpty)
                                      AppText(
                                        text: _formatTimeAgo(createdAt),
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  text: message,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 6),
            // Input area - simplified design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Comment input
                  Expanded(
                    child: CustomTextField(
                      controller: commentController,
                      hint: 'Add a comment...',
                      maxLines: 1,
                      fillColor: Colors.transparent,
                      borderColor: AppColors.border,
                      suffixIcon: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => commentOnPost(post.id, post),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: () => commentOnPost(post.id, post),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
    );
  }

  // Instagram-like time formatting
  String _formatTimeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    
    try {
      final DateTime commentTime = DateTime.parse(createdAt);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(commentTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }



  Future<void> fetchFavoritePosts() async {
    try {
      favoritePostsRaw.clear();
      favoritePosts.clear();
      isLoading.value = true;
      var response = await customApiService.getRequest('posts/getFavorite');
      final List<dynamic> favData = response['favorites'] ?? [];
      favoritePostsRaw.value = favData.cast<Map<String, dynamic>>();
      
      // Convert raw favorite posts to Posts objects
      favoritePosts.value = favoritePostsRaw
          .map((postData) => Posts.fromMap(postData))
          .toList();
      
      log('Fetched ${favoritePosts.length} favorite posts');
    } catch (e) {
      log('Error fetching favorite posts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initializeVideoController(String url) async {
    if (!videoControllers.containsKey(url)) {
      final controller = VideoPlayerController.network(url);
      await controller.initialize();
      videoControllers[url] = controller;
      isVideoInitialized[url] = true;
      controller.addListener(() {
        isVideoInitialized[url] = controller.value.isInitialized;
      });
    }
  }

  void disposeVideoController(String url) {
    videoControllers[url]?.dispose();
    videoControllers.remove(url);
    isVideoInitialized.remove(url);
  }

  void pauseAllVideos() {
    for (var controller in videoControllers.values) {
      if (controller.value.isPlaying) controller.pause();
    }
  }

  void fundPost(Posts post, BuildContext context) {
    Get.bottomSheet(
      _FundBottomSheet(
        post: post,
        onConfirm: (amount) async {
          final oldFundCount = post.fundCount.value;
          try {
            Get.find<LoadingController>().show();
            await PaymentServices.stripePayment(
                amount, "dummy_donationId", context, onSuccess: () async {
              post.isFunded.value = true;
              post.fundCount.value += int.tryParse(1.toString()) ?? 0;
              posts.refresh();
              final response = await customApiService.postRequest(
                  'posts/fundRaise/post/${post.id}', {"amount": amount});

              log("Response is $response");
            });
          } catch (e) {
            log("Error is $e");
            post.isFunded.value = false;
            post.fundCount.value = oldFundCount;
            posts.refresh();
            ShortMessageUtils.showError("Failed to fund post");
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> addPostView(String postId) async {
    try {
      final response = await customApiService.postRequest(
        'posts/$postId/view',
        {},
      );
      log("Response is $response");
    } catch (e) {
      log('Error adding post view: $e $postId');
    } finally {}
  }

  // Add this method for single post preview like functionality
  Future<void> likeSinglePost() async {
    final post = singlePost.value;
    if (post == null) return;

    // Ensure ProfileController is registered
    if (!Get.isRegistered<ProfileController>()) {
      log("🔁 ProfileController not registered, initializing...");
      Get.put(ProfileController());
    }

    final profile = Get.find<ProfileController>().profile.value;
    final currentUserId = profile?.id;
    if (currentUserId == null) {
      log("❌ Current user ID is null, cannot like post.");
      return;
    }

    // Normalize existing likes (Map → String)
    post.likes.value = post.likes.map((like) {
      if (like is Map && like.containsKey('_id')) {
        return like['_id'];
      }
      return like;
    }).toList();

    final wasLiked = post.likes.contains(currentUserId);
    post.isCurrentUserLiked = !wasLiked;

    if (wasLiked) {
      post.likes.remove(currentUserId);
    } else {
      post.likes.add(currentUserId);
    }
    singlePost.refresh();

    // Call API in background
    try {
      final response =
          await customApiService.postRequest("posts/${post.id}/like", {});
      log("✅ Like API response: $response");
    } catch (e) {
      // Revert state if API fails
      log("❌ Error liking post, reverting UI: $e");
      post.isCurrentUserLiked = wasLiked;
      if (wasLiked) {
        post.likes.add(currentUserId);
      } else {
        post.likes.remove(currentUserId);
      }
      singlePost.refresh();
    }
  }

  Widget _buildCommentAvatar(String? avatarUrl, String userName) {
    log("🖼️ Building comment avatar - URL: $avatarUrl, UserName: $userName");
    
    if (avatarUrl != null && avatarUrl.toString().isNotEmpty && avatarUrl != 'null') {
      log("✅ Loading profile image: $avatarUrl");
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            log("❌ Error loading profile image: $error");
            // Fallback to initials if image fails to load
            return _buildInitialsAvatar(userName, 20);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            log("⏳ Loading profile image...");
            // Show initials while loading
            return _buildInitialsAvatar(userName, 20);
          },
        ),
      );
    } else {
      log("📝 No profile image available, showing initials for: $userName");
      return _buildInitialsAvatar(userName, 20);
    }
  }

  Widget _buildInitialsAvatar(String userName, double radius) {
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Process comment data to ensure consistent structure for display
  Map<String, dynamic> _processCommentData(Map<String, dynamic> comment) {
    // If comment already has our expected structure, return as is
    if (comment['user'] != null && comment['user'] is Map) {
      return comment;
    }

    // Handle different API response structures
    Map<String, dynamic> processedComment = Map.from(comment);
    
    // Try to extract user data from different possible fields
    Map<String, dynamic> userData = {};
    
    // Check for user data in various possible fields
    if (comment['user'] != null && comment['user'] is Map) {
      userData = Map.from(comment['user']);
    } else if (comment['author'] != null && comment['author'] is Map) {
      userData = Map.from(comment['author']);
    } else if (comment['commenter'] != null && comment['commenter'] is Map) {
      userData = Map.from(comment['commenter']);
    } else if (comment['userId'] != null) {
      // If only userId is available, create minimal user data
      userData = {
        '_id': comment['userId'],
        'name': comment['userName'] ?? comment['authorName'] ?? 'User',
        'profilePic': comment['userProfilePic'] ?? comment['authorProfilePic'] ?? '',
      };
    }

    // Ensure user data has required fields
    userData['_id'] = userData['_id'] ?? userData['id'] ?? '';
    userData['name'] = userData['name'] ?? userData['username'] ?? 'User';
    userData['profilePic'] = userData['profilePic'] ?? userData['profile_pic'] ?? userData['avatar'] ?? '';

    // If no profile picture is available, try to get it from user profile
    if (userData['profilePic'].toString().isEmpty) {
      // Try to get profile picture from ProfileController if this is the current user
      try {
        final profileController = Get.find<ProfileController>();
        final currentUserId = profileController.profile.value?.id;
        final commentUserId = userData['_id']?.toString();
        
        if (currentUserId == commentUserId) {
          // This is the current user's comment, try to get their pet/user profile pic
          if (profileController.userPet.value?.name != null && 
              profileController.userPet.value!.name!.isNotEmpty) {
            userData['name'] = profileController.userPet.value!.name!;
            userData['profilePic'] = profileController.userPet.value!.profilePic ?? 
                                   profileController.profile.value?.profilePic ?? '';
            log("🐾 Updated comment with pet profile - Name: ${userData['name']}, ProfilePic: ${userData['profilePic']}");
          } else {
            userData['profilePic'] = profileController.profile.value?.profilePic ?? '';
            log("👤 Updated comment with user profile - Name: ${userData['name']}, ProfilePic: ${userData['profilePic']}");
          }
        }
      } catch (e) {
        log("⚠️ Could not get profile data for comment: $e");
      }
    }

    processedComment['user'] = userData;
    log("🔄 Processed comment data: $processedComment");
    
    return processedComment;
  }
}

class _FundBottomSheet extends StatefulWidget {
  final Posts post;
  final Function(String amount) onConfirm;
  const _FundBottomSheet({required this.post, required this.onConfirm});
  @override
  State<_FundBottomSheet> createState() => _FundBottomSheetState();
}

class _FundBottomSheetState extends State<_FundBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Pet Profile Section
          _buildPetProfileSection(),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            "Paws Up for Joy",
            style: TextStyle(
              color: AppColors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 12),
          
          // Description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Your generosity makes tails wag and hearts purr",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Amount Input
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: TextField(
              onTapOutside: (event) {
                FocusScope.of(context).unfocus();
              },
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: "Enter amount",
                labelStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money, color: Colors.white, size: 20),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.blue, AppColors.blue.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            await widget.onConfirm(_amountController.text.trim());
                            setState(() => _isLoading = false);
                            Get.back();
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            "Give with ❤️",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPetProfileSection() {
    return FutureBuilder<PetModel?>(
      future: _getPetProfile(widget.post.creator.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPetProfile();
        }
        
        final pet = snapshot.data;
        if (pet != null) {
          return _buildPetProfileCard(pet);
        } else {
          return _buildCreatorAvatar(widget.post.creator);
        }
      },
    );
  }

  Future<PetModel?> _getPetProfile(String userId) async {
    try {
      final response = await Get.find<CustomApiService>().getRequest('pet-profile/user/$userId');
      if (response != null && response['data'] != null) {
        return PetModel.fromJson(response['data']);
      }
    } catch (e) {
      log("Error fetching pet profile: $e");
    }
    return null;
  }

  Widget _buildLoadingPetProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetProfileCard(PetModel pet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue.withOpacity(0.1), AppColors.blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Pet Profile Picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: pet.profilePic != null && pet.profilePic!.isNotEmpty
                  ? Image.network(
                      pet.profilePic!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPetFallback(pet);
                      },
                    )
                  : _buildPetFallback(pet),
            ),
          ),
          const SizedBox(width: 16),
          
          // Pet Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name ?? 'Pet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (pet.breed != null && pet.breed!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pet.breed!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (pet.petType != null && pet.petType!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pet.petType!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Support Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetFallback(PetModel pet) {
    final petName = pet.name ?? 'Pet';
    final initials = petName.isNotEmpty ? petName[0].toUpperCase() : 'P';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue, AppColors.blue.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorAvatar(dynamic creator) {
    final profilePic = creator.profilePic;
    final userName = creator.name ?? 'Creator';
    
    if (profilePic != null && profilePic.toString().isNotEmpty && profilePic != 'null') {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback handled by child
        },
        child: _buildInitialsAvatar(userName, 32),
      );
    } else {
      return _buildInitialsAvatar(userName, 32);
    }
  }

  Widget _buildInitialsAvatar(String userName, double radius) {
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
