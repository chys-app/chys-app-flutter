import 'dart:developer';
import 'package:chys/app/modules/%20home/widget/custom_header.dart';
import 'package:chys/app/modules/%20home/widget/floating_action_button.dart';
import 'package:chys/app/modules/%20home/widget/story_section.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:chys/app/modules/podcast/controllers/podcast_controller.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/widget/common/custom_post_widget.dart';
import 'package:chys/app/widget/common/post_grid_widget.dart';
import 'package:chys/app/widget/common/product_grid_widget.dart';
import 'package:chys/app/data/models/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  late final MapController mapController;
  late final CustomApiService _apiService;
  late final CreatePodCastController podcastController;
  late final PodcastController podCastCallController;
  late final ProductsController productsController;

  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInitialized = false;
  bool _isRefreshing = false;

  // Constants for better maintainability
  static const Color _primaryColor = Color(0xFF0095F6);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _textPrimary = Color(0xFF262626);
  static const Color _textSecondary = Color(0xFF8E8E8E);
  static const double _defaultPadding = 8.0;
  static const double _tabHeight = 30.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers in initState to avoid build-phase conflicts
    mapController = Get.put(MapController());
    _apiService = Get.put(CustomApiService());
    podcastController = Get.put(CreatePodCastController());
    podCastCallController = Get.put(PodcastController());
    
    // Ensure we get the existing controller or create a new one
    if (Get.isRegistered<AddoredPostsController>(tag: 'home')) {
      contrroller = Get.find<AddoredPostsController>(tag: 'home');
    } else {
      contrroller = Get.put(AddoredPostsController(), tag: 'home');
    }
    if (Get.isRegistered<ProductsController>()) {
      productsController = Get.find<ProductsController>();
    } else {
      productsController = Get.put(ProductsController());
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

      // Defer fetching to after build phase to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Fetch products for Hot Picks tab - always call, let controller handle caching
        log("Initializing products fetch (controller will use cache if valid)");
        log("Products controller state before fetch - isLoading: ${productsController.isLoading.value}, products count: ${productsController.products.length}");
        productsController.fetchProducts(publicOnly: true);
        if (contrroller.posts.isEmpty && !contrroller.isLoading.value) {
          contrroller.fetchAdoredPosts();
        }
        if (podcastController.podcasts.isEmpty) {
          podcastController.getAllPodCast();
        }
      });
    }
  }

  void _resetPostFiltering() {
    try {
      log("Resetting post filtering to show all posts in home view");
      // Only reset the home controller, not profile controllers
      if (Get.isRegistered<AddoredPostsController>(tag: 'home')) {
        final homeController = Get.find<AddoredPostsController>(tag: 'home');
        // Defer the update to after the current frame to avoid setState during build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          homeController.clearUserFiltering();
          log("Home view post filtering reset completed");
        });
      }
    } catch (e) {
      log("Error resetting post filtering: $e");
    }
  }

  void _checkAndRefreshData() {
    try {
      // Defer to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
    } catch (e) {
      log("Error checking data freshness: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStorySection(),
            _buildTabNavigation(),
            Expanded(child: _buildContentArea()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(controller: mapController),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _defaultPadding, vertical: 8),
      child: buildCustomHeader(),
    );
  }

  Widget _buildStorySection() {
    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: _defaultPadding),
      child: const StorySection(),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.only(left: _defaultPadding, right: _defaultPadding, top: 4, bottom: 4),
      height: _tabHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(() => Row(
            children: [
              _buildTabButton('Hot Picks', 0, Icons.local_fire_department),
              _buildTabButton('Furrfriends', 1, Icons.favorite),
              _buildTabButton('Podcasts', 2, Icons.mic_none),
            ],
          )),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = contrroller.tabIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : _textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : _textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
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
    
    // Handle podcast tab changes
    if (index == 2) {
      // Podcasts tab - show podcasts from followed hosts
      log("Switching to Podcasts tab (following only)");
      podcastController.getAllPodCast(followingOnly: true);
    }
    
    _refreshController.refreshCompleted();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      switch (contrroller.tabIndex.value) {
        case 0:
          await _refreshProducts();
          break;
        case 1:
          await _refreshPosts();
          break;
        case 2:
          await _refreshPodcasts();
          break;
      }
    } catch (e) {
      log("Error during refresh: $e");
      // Show error message to user
      Get.snackbar(
        "Refresh Failed",
        "Failed to refresh content. Please try again.",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Widget _buildContentArea() {
    return Obx(() {
      switch (contrroller.tabIndex.value) {
        case 0:
          return _buildProductsContent();
        case 1:
          return _buildPostsContent();
        case 2:
          return _buildPodcastsContent();
        default:
          return _buildPostsContent();
      }
    });
  }

  Widget _buildProductsContent() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropHeader(
        waterDropColor: _primaryColor,
      ),
      onRefresh: () async {
        await _handleRefresh();
        _refreshController.refreshCompleted();
      },
      child: Stack(
        children: [
          // Main content
          Obx(() {
            // Debug logging
            log("Products content - isLoading: ${productsController.isLoading.value}, hasAttemptedFetch: ${productsController.hasAttemptedFetch.value}, products count: ${productsController.products.length}");
            
            // Show loading overlay if loading
            if (productsController.isLoading.value) {
              log("Showing loading state");
              return _buildProductsLoadingState();
            } else if (!productsController.hasAttemptedFetch.value) {
              log("Showing initial state (no fetch attempted yet)");
              return _buildProductsLoadingState();
            } else if (productsController.products.isEmpty) {
              log("Showing empty state (no products found)");
              return _buildProductsEmptyState();
            } else {
              log("Showing products grid (${productsController.products.length} products)");
              return _buildProductsGrid();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPostsContent() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropHeader(
        waterDropColor: _primaryColor,
      ),
      onRefresh: () async {
        await _handleRefresh();
        _refreshController.refreshCompleted();
      },
      child: Obx(() {
        // Use currentPosts which returns posts based on the current filter state
        final postsList = contrroller.currentPosts;
        
        return Stack(
          children: [
            // Main content
            postsList.isEmpty
                ? _buildEmptyState()
                : contrroller.isGridView.value
                    ? _buildPostsGrid()
                    : _buildPostsList(),

          // Single loading overlay
          if (contrroller.isLoading.value)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading posts...",
                      style: TextStyle(
                        fontSize: 16,
                        color: _textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPodcastsContent() {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      header: const WaterDropHeader(
        waterDropColor: _primaryColor,
      ),
      onRefresh: () async {
        await _handleRefresh();
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
    final crossAxisCount = screenWidth > 600 ? 3 : 3;

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
      // Use currentPosts which returns posts based on the current filter state
      final postsList = contrroller.currentPosts;
      
      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 3;

      return StaggeredGridView.countBuilder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        itemCount: postsList.length,
        itemBuilder: (context, index) {
          final post = postsList[index];
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
    return Obx(() {
      // Use currentPosts which returns posts based on the current filter state
      final postsList = contrroller.currentPosts;
      
      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: postsList.length,
        itemBuilder: (context, index) {
          final post = postsList[index];
          return CustomPostWidget(
            posts: post,
            addoredPostsController: contrroller,
            onTapCard: () {
              // Route to different preview views based on post type
              if (post.type == PostType.fundraise) {
                Get.toNamed(AppRoutes.fundraisePreview, arguments: {
                  'postId': post.id,
                  'controller': contrroller,
                });
              } else {
                Get.toNamed(AppRoutes.postPreview, arguments: {
                  'postId': post.id,
                  'controller': contrroller,
                });
              }
            },
            onTapPaw: () {},
            onTapLove: () {
              log("Favorite tap");
              contrroller.toggleFavorite(post.id);
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
    });
  }

  Widget _buildEmptyState() {
    return Obx(() {
      final isFurrfriendsTab = contrroller.tabIndex.value == 1;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(_defaultPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFurrfriendsTab ? Icons.favorite_outline : Icons.photo_library_outlined,
                  size: 48,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFurrfriendsTab ? 'No Furrfriends Posts' : 'No Posts Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFurrfriendsTab
                    ? 'Follow other users to see their posts here!\nStart by searching for friends in the search tab.'
                    : 'Be the first to share something amazing\nwith your friends!',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
            : 3;

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
              : 3;

      return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        padding: EdgeInsets.zero,
        itemCount: podcastController.podcasts.length,
        itemBuilder: (context, index) {
          final podcast = podcastController.podcasts[index];
          return PodcastGridWidget(
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
          );
        },
        staggeredTileBuilder: (index) {
          // Fixed height ratio for Instagram-like uniform grid
          return const StaggeredTile.count(1, 1.0);
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
            'No Furrfriends Podcasts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow other users to see their podcasts here!\nStart by searching for friends in the search tab.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Obx(() {
      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 3;

      return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        padding: EdgeInsets.zero,
        itemCount: productsController.products.length,
        itemBuilder: (context, index) {
          final product = productsController.products[index];
          return ProductGridWidget(
            product: product,
            onTap: () {
              // Navigate to product details
              Get.toNamed(AppRoutes.productDetail, arguments: product);
            },
            onCreatorTap: () {
              // Navigate to creator profile
              log("Navigate to creator profile: ${product.creator.id}");
            },
          );
        },
        staggeredTileBuilder: (index) {
          // Fixed height ratio for all products to make them uniform (Instagram-like)
          return const StaggeredTile.count(1, 1.0);
        },
      );
    });
  }

  Widget _buildProductsLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading products...',
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_defaultPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to share amazing products\nwith the community!',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProducts() async {
    try {
      await productsController.refreshProducts();
    } catch (e) {
      log("Error refreshing products: $e");
    }
  }

  Future<void> _refreshPosts() async {
    try {
      if (contrroller.tabIndex.value == 1) {
        // Furrfriends tab - show posts from followed users
        await contrroller.fetchAdoredPosts(
          followingOnly: true,
          forceRefresh: true, // Force refresh to get latest data
        );
      } else {
        // Hot Picks tab - show all posts
        await contrroller.fetchAdoredPosts(
          followingOnly: false,
          forceRefresh: true, // Force refresh to get latest data
        );
      }
    } catch (e) {
      log("Error refreshing posts: $e");
    }
  }

  Future<void> _refreshPodcasts() async {
    try {
      // Podcasts tab always shows podcasts from followed hosts
      await podcastController.getAllPodCast(followingOnly: true);
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
