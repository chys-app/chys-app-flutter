import 'dart:developer';
import 'package:chys/app/core/widget/app_button.dart';
import 'package:chys/app/modules/%20home/widget/custom_header.dart';
import 'package:chys/app/modules/%20home/widget/floating_action_button.dart';
import 'package:chys/app/modules/%20home/widget/story_section.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:chys/app/modules/podcast/controllers/podcast_controller.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/pet_ownership_service.dart';
import 'package:chys/app/widget/common/custom_post_widget.dart';
import 'package:chys/app/widget/common/post_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../routes/app_routes.dart';
import '../../services/common_service.dart';
import '../../widget/common/PodcastGridWidget.dart';
import '../../widget/shimmer/cat_quote_shimmer.dart';
import '../map/controllers/map_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  late final AddoredPostsController contrroller;
  final mapController = Get.put(MapController());
  final CustomApiService _apiService = Get.put(CustomApiService());
  final CreatePodCastController podcastController =
      Get.put(CreatePodCastController());
  final PodcastController podCastCallController = Get.put(PodcastController());

  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Ensure we get the existing controller or create a new one
    if (Get.isRegistered<AddoredPostsController>(tag: 'home')) {
      contrroller = Get.find<AddoredPostsController>(tag: 'home');
    } else {
      contrroller = Get.put(AddoredPostsController(), tag: 'home');
    }
    log("Home view using controller with tag: 'home'");
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reset post filtering when returning to home
      _resetPostFiltering();
      // Only refresh if data is stale (older than 5 minutes)
      _checkAndRefreshData();
    }
  }

  void _initializeData() {
    if (!_hasInitialized) {
      _hasInitialized = true;

      // Reset post filtering to show all posts
      _resetPostFiltering();

      // Only fetch if posts are empty AND we haven't loaded before
      if (contrroller.posts.isEmpty && !contrroller.isLoading.value) {
        contrroller.fetchAdoredPosts();
      }
      if (podcastController.podcasts.isEmpty) {
        podcastController.getAllPodCast();
      }
    }
  }

  void _resetPostFiltering() {
    try {
      log("Resetting post filtering to show all posts in home view");
      // Only reset the home controller, not profile controllers
      if (Get.isRegistered<AddoredPostsController>(tag: 'home')) {
        final homeController = Get.find<AddoredPostsController>(tag: 'home');
        homeController.clearUserFiltering();
        log("Home view post filtering reset completed");
      }
    } catch (e) {
      log("Error resetting post filtering: $e");
    }
  }

  void _checkAndRefreshData() {
    try {
      // Check if data is stale and needs refresh
      final cacheAge =
          contrroller.getCacheAge("posts__false"); // Default cache key

      if (cacheAge != null) {
        if (cacheAge.inMinutes > 5) {
          contrroller.fetchAdoredPosts(forceRefresh: true);
        }
      } else {
        contrroller.fetchAdoredPosts();
      }
    } catch (e) {
      log("Error checking data freshness: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset post filtering when home view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasInitialized) {
        _resetPostFiltering();
      }
    });

    // Handle navigation back to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we're returning from a profile view
      final currentRoute = Get.currentRoute;
      if (currentRoute == AppRoutes.home) {
        log("Returned to home view, resetting post filtering");
        _resetPostFiltering();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Instagram-like background
      floatingActionButton: _buildFloatingActionButton(),
      body: SafeArea(
        child: Column(
          children: [
            // Professional Header
            _buildHeader(),

            // Story Section
            _buildStorySection(),

            // Tab Navigation
            _buildTabNavigation(),

            // Content Area with Pull-to-Refresh
            Expanded(
              child: _buildContentArea(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(controller: mapController),
    );
  }

  Widget _buildFloatingActionButton() {
    final petService = PetOwnershipService.instance;

    return Container(
      decoration: BoxDecoration(
        color: petService.canCreatePodcasts
            ? const Color(0xFF0095F6)
            : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (petService.canCreatePodcasts
                    ? const Color(0xFF0095F6)
                    : Colors.grey.shade400)
                .withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Appbutton(
        borderColor: Colors.transparent,
        label: "Schedule Podcast",
        backgroundColor: Colors.transparent,
        textColor: Colors.white,
        onPressed: () {
          if (petService.canCreatePodcasts) {
            Get.toNamed(AppRoutes.inviteUserToPodCast);
          } else {
           // petService.showPodcastRestriction();
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // decoration: const BoxDecoration(
      //   color: Colors.white,
      // ),
      child: buildCustomHeader(),
    );
  }

  Widget _buildStorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const StorySection(),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Obx(() => Row(
            children: [
              _buildTabButton('Hot Picks', 0, Icons.local_fire_department),
              _buildTabButton('Friends', 1, Icons.people),
              _buildTabButton('Podcasts', 2, Icons.mic),
              // const SizedBox(width: 12),
              // _buildSchedulePodcastButton(),
            ],
          )),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = contrroller.tabIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0095F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildSchedulePodcastButton() {
  //   return GestureDetector(
  //     onTap: () => Get.toNamed(AppRoutes.invitePodcast),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       decoration: BoxDecoration(
  //         gradient: const LinearGradient(
  //           colors: [Color(0xFF0095F6), Color(0xFF00C851)],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: const Color(0xFF0095F6).withOpacity(0.2),
  //             blurRadius: 4,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Icon(
  //             Icons.mic,
  //             size: 16,
  //             color: Colors.white,
  //           ),
  //           const SizedBox(width: 6),
  //           const Text(
  //             'Schedule',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTabDivider() {
    return const SizedBox(width: 8);
  }

  void _onTabTap(int index) {
    contrroller.onTabChange(index);
    _refreshController.refreshCompleted();
  }

  Widget _buildContentArea() {
    return Obx(() {
      switch (contrroller.tabIndex.value) {
        case 0:
        case 1:
          return _buildPostsContent();
        case 2:
          return _buildPodcastsContent();
        default:
          return _buildPostsContent();
      }
    });
  }

  Widget _buildPostsContent() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropHeader(
        waterDropColor: Color(0xFF0095F6),
      ),
      onRefresh: () async {
        await _refreshPosts();
        _refreshController.refreshCompleted();
      },
      child: Stack(
        children: [
          // Main content
          contrroller.posts.isEmpty
              ? _buildEmptyState()
              : contrroller.isGridView.value
                  ? _buildPostsGrid()
                  : _buildPostsList(),

          // Single loading overlay
          if (contrroller.isLoading.value)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading posts...",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF262626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodcastsContent() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropHeader(
        waterDropColor: Color(0xFF0095F6),
      ),
      onRefresh: () async {
        await _refreshPodcasts();
        _refreshController.refreshCompleted();
      },
      child: Stack(
        children: [
          // Main content
          Obx(() {
            if (podcastController.podcasts.isEmpty) {
              return _buildPodcastEmptyState();
            } else {
              return _buildPodcastsGrid();
            }
          }),

          // Single loading overlay
          Obx(() {
            if (podcastController.isPodcastLoading.value) {
              return Container(
                color: Colors.white.withOpacity(0.9),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Loading podcasts...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF262626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid() {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return StaggeredGridView.countBuilder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
      staggeredTileBuilder: (index) {
        // Create different heights for loading items
        final heightRatio = 0.8 + (index % 4) * 0.4; // 0.8, 1.2, 1.6, 2.0
        return StaggeredTile.count(1, heightRatio);
      },
    );
  }

  Widget _buildPostsGrid() {
    return Obx(() {
      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 2;

      return StaggeredGridView.countBuilder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        itemCount: contrroller.posts.length,
        itemBuilder: (context, index) {
          final post = contrroller.posts[index];
          return PostGridWidget(
            post: post,
            addoredPostsController: contrroller,
            disableThumbnailGeneration: false,
          );
        },
        staggeredTileBuilder: (index) {
          // Fixed height ratio for all posts to make them the same height
          const double heightRatio = 1.2;
          return StaggeredTile.count(1, heightRatio);
        },
      );
    });
  }

  Widget _buildPostsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: contrroller.posts.length,
      itemBuilder: (context, index) {
        final post = contrroller.posts[index];
        return CustomPostWidget(
          posts: post,
          addoredPostsController: contrroller,
          onTapCard: () {
            Get.toNamed(AppRoutes.postPreview, arguments: {
              'postId': post.id,
              'controller': contrroller,
            });
          },
          onTapPaw: () {},
          onTapLove: () {
            log("Like tap");
            contrroller.likePost(post.id);
          },
          onTapShare: () {
            contrroller.sharePost(post);
          },
          onTapMessage: () {
            contrroller.showCommentsBottomSheet(post);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Obx(() {
      final isFriendsTab = contrroller.tabIndex.value == 1;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFriendsTab
                  ? 'Your friends haven\'t shared anything yet. Follow more friends to see their posts!'
                  : 'Be the first to share something amazing with your friends!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isFriendsTab) ...[
              const SizedBox(height: 24),
              Obx(() {
                final petService = PetOwnershipService.instance;
                return ElevatedButton(
                  onPressed: () {
                    if (petService.canCreatePosts) {
                      Get.toNamed(AppRoutes.addPost);
                    } else {
                    //  petService.showPostRestriction();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: petService.canCreatePosts
                        ? const Color(0xFF0095F6)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    petService.canCreatePosts
                        ? 'Create Post'
                        : 'Create Post (Restricted)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPodcastLoadingGrid() {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    return StaggeredGridView.countBuilder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => const CatQuoteCardShimmer(),
      staggeredTileBuilder: (index) {
        // Create different heights for loading items
        final heightRatio = 0.8 + (index % 4) * 0.4; // 0.8, 1.2, 1.6, 2.0
        return StaggeredTile.count(1, heightRatio);
      },
    );
  }

  Widget _buildPodcastsGrid() {
    return Obx(() {
      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 2;

      return StaggeredGridView.countBuilder(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        itemCount: podcastController.podcasts.length,
        itemBuilder: (context, index) {
          final podcast = podcastController.podcasts[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PodcastGridWidget(
                podcast: podcast,
                onTap: () {
                  final canJoin = CommonService.canJoinPodcast(
                    hostId: podcast.host.id,
                    status: podcast.status,
                    scheduledAt: podcast.scheduledAt,
                  );
                  if (canJoin) {
                    podCastCallController.podCastId = podcast.id;
                    log("Pod cast id is ${podCastCallController.podCastId}");
                    Get.toNamed(AppRoutes.podCastView, arguments: podcast);
                  }
                },
                onUserProfileTap: () {
                  // Navigate to user profile
                },
              ),
            ),
          );
        },
        staggeredTileBuilder: (index) {
          // Create different heights for podcasts
          final heightRatio = 1.0 + (index % 4) * 0.2; // 1.0, 1.2, 1.4, 1.6
          return StaggeredTile.count(1, heightRatio);
        },
      );
    });
  }

  Widget _buildPodcastEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No podcasts available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a podcast or join an existing one!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _refreshPosts() async {
    try {
      await contrroller.fetchAdoredPosts(
        followingOnly: contrroller.tabIndex.value == 1,
        forceRefresh: true, // Force refresh to get latest data
      );
    } catch (e) {
      log("Error refreshing posts: $e");
    }
  }

  Future<void> _refreshPodcasts() async {
    try {
      await podcastController.getAllPodCast();
    } catch (e) {
      log("Error refreshing podcasts: $e");
    }
  }
}

class StoryModel {
  final String id;
  final String mediaUrl;
  final String caption;
  final String userName;
  final int viewCount;

  StoryModel({
    required this.id,
    required this.mediaUrl,
    required this.caption,
    required this.userName,
    required this.viewCount,
  });

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: map['_id'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      caption: map['caption'] ?? '',
      userName: map['userId']?['name'] ?? '',
      viewCount: map['viewCount'] ?? 0,
    );
  }
}
