import 'dart:developer';
import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/%20home/widget/custom_header.dart';
import 'package:chys/app/modules/%20home/widget/floating_action_button.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/widget/common/post_grid_widget.dart';
import 'package:chys/app/widget/common/custom_post_widget.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:chys/app/modules/product/views/add_product_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../routes/app_routes.dart';
import '../../widget/common/product_grid_widget.dart';
import '../map/controllers/map_controller.dart';

class BusinessHomeView extends StatefulWidget {
  const BusinessHomeView({Key? key}) : super(key: key);

  @override
  State<BusinessHomeView> createState() => _BusinessHomeViewState();
}

class _BusinessHomeViewState extends State<BusinessHomeView> with WidgetsBindingObserver {
  late final AddoredPostsController contrroller;
  late final MapController mapController;
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
  static const double _defaultPadding = 16.0;
  static const double _tabHeight = 40.0;

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState to avoid build-phase conflicts
    mapController = Get.put(MapController());
    // Ensure we get the existing controller or create a new one
    if (Get.isRegistered<AddoredPostsController>(tag: 'business')) {
      contrroller = Get.find<AddoredPostsController>(tag: 'business');
    } else {
      contrroller = Get.put(AddoredPostsController(), tag: 'business');
    }
    if (Get.isRegistered<ProductsController>()) {
      productsController = Get.find<ProductsController>();
    } else {
      productsController = Get.put(ProductsController());
    }
    log("Home view using controller with tag: 'business_home'");
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
        log('🏠 Fetching posts...');
        contrroller.fetchAdoredPosts();
      }
      if (productsController.products.isEmpty &&
          !productsController.isLoading.value) {
        log('🏠 Fetching products...');
        productsController.fetchProducts();
      } else {
        log('🏠 Products already loaded: ${productsController.products.length} items');
      }
    }
  }

  void _resetPostFiltering() {
    try {
      log("Resetting post filtering to show all posts in business home view");
      // Only reset the home controller, not profile controllers
      if (Get.isRegistered<AddoredPostsController>(tag: 'business_home')) {
        final homeController = Get.find<AddoredPostsController>(tag: 'business_home');
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
    // Single post frame callback to avoid multiple rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasInitialized && Get.currentRoute == AppRoutes.home) {
        _resetPostFiltering();
      }
    });

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildAddButton(),
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
      padding: const EdgeInsets.symmetric(horizontal: _defaultPadding, vertical: 12),
      child: buildCustomHeader(),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _defaultPadding, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            // Navigate to create product screen
            Get.to(() => AddProductView());
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _defaultPadding, vertical: 8),
      height: _tabHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Obx(() => Row(
            children: [
              _buildTabButton('Best Sellers', 0, Icons.local_fire_department),
              _buildTabButton('Most Viewed', 1, Icons.people),
              _buildTabButton('All', 2, Icons.list),
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
        case 1:
          await _refreshPosts();
          break;
        case 2:
          await _refreshProducts();
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
          return _buildProductsContent(sortBySales: true);
        case 1:
          return _buildProductsContent(sortByViews: true);
        case 2:
          return _buildProductsContent();
        default:
          return _buildProductsContent();
      }
    });
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
      ),
    );
  }

  Widget _buildProductsContent({bool sortByViews = false, bool sortBySales = false}) {
    log('🏠 Building products content. Products count: ${productsController.products.length}, Loading: ${productsController.isLoading.value}, SortByViews: $sortByViews, SortBySales: $sortBySales');
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
            log('🏠 Obx rebuild - Products: ${productsController.products.length}, Loading: ${productsController.isLoading.value}');
            if (productsController.isLoading.value &&
                productsController.products.isEmpty) {
              return _buildProductsLoadingGrid();
            }
            if (productsController.products.isEmpty) {
              log('🏠 Showing empty state');
              return _buildEmptyState();
            } else {
              log('🏠 Showing products grid with ${productsController.products.length} items');
              return _buildProductsGrid(sortByViews: sortByViews, sortBySales: sortBySales);
            }
          }),

          // Single loading overlay
          Obx(() {
            if (productsController.isLoading.value) {
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
                        "Loading products...",
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
                Icons.photo_library_outlined,
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
              "Let's create some products and services!",
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

  Widget _buildProductsLoadingGrid() {
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
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      staggeredTileBuilder: (index) {
        // Create different heights for loading items
        final heightRatio = 0.8 + (index % 4) * 0.4; // 0.8, 1.2, 1.6, 2.0
        return StaggeredTile.count(1, heightRatio);
      },
    );
  }

  Widget _buildProductsGrid({bool sortByViews = false, bool sortBySales = false}) {
    return Obx(() {
      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 2;

      // Get products and sort if needed
      List<Products> products = productsController.products.toList();
      
      if (sortBySales) {
        products.sort((a, b) => b.salesCount.compareTo(a.salesCount));
      } else if (sortByViews) {
        products.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      }

      return StaggeredGridView.countBuilder(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductGridWidget(
            product: product,
            onTap: () {
              Get.toNamed(AppRoutes.productDetail, arguments: product);
            },
            onCreatorTap: () {
              // Navigate to creator profile
              Get.toNamed(AppRoutes.businessUserProfile, arguments: product.creator.id);
            },
          );
        },
        staggeredTileBuilder: (index) {
          // Fixed height ratio for all products to make them the same size
          return const StaggeredTile.count(1, 1.2);
        },
      );
    });
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
      await contrroller.fetchAdoredPosts(
        followingOnly: contrroller.tabIndex.value == 1,
        forceRefresh: true, // Force refresh to get latest data
      );
    } catch (e) {
      log("Error refreshing posts: $e");
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
