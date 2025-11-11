import 'dart:developer';
import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/%20home/widget/custom_header.dart';
import 'package:chys/app/modules/%20home/widget/floating_action_button.dart';
import 'package:chys/app/modules/cart/controllers/cart_controller.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../routes/app_routes.dart';
import '../../widget/common/product_grid_widget.dart';
import '../map/controllers/map_controller.dart';

class MarketplaceView extends StatefulWidget {
  const MarketplaceView({Key? key}) : super(key: key);

  @override
  State<MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<MarketplaceView> with WidgetsBindingObserver {
  late final MapController mapController;
  late final ProductsController productsController;
  late final CartController cartController;

  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  bool _hasInitialized = false;
  bool _isRefreshing = false;
  final RxInt _tabIndex = 0.obs;

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
    // Initialize controllers
    mapController = Get.put(MapController());
    cartController = Get.put(CartController());
    
    if (Get.isRegistered<ProductsController>()) {
      productsController = Get.find<ProductsController>();
    } else {
      productsController = Get.put(ProductsController());
    }
    
    log("Marketplace view initialized");
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshData();
    }
  }

  void _initializeData() {
    if (!_hasInitialized) {
      _hasInitialized = true;

      // Defer the fetch to after the build phase to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (productsController.products.isEmpty &&
            !productsController.isLoading.value) {
          log('🛒 Fetching all public products for marketplace...');
          productsController.fetchProducts(publicOnly: true);
        } else {
          log('🛒 Products already loaded: ${productsController.products.length} items');
        }
      });
    }
  }

  void _checkAndRefreshData() {
    try {
      // Defer to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Refresh products if needed
        if (productsController.products.isEmpty) {
          productsController.fetchProducts(publicOnly: true);
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
      child: Row(
        children: [
          Expanded(child: buildCustomHeader()),
          const SizedBox(width: 12),
          // Shopping cart icon with badge
          Obx(() => GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.cart),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: _primaryColor,
                    size: 24,
                  ),
                ),
              if (cartController.cartItemCount.value > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      cartController.cartItemCount.value > 99 
                          ? '99+' 
                          : cartController.cartItemCount.value.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
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
              _buildTabButton('Favorites', 1, Icons.favorite),
              _buildTabButton('All Products', 2, Icons.grid_view),
            ],
          )),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _tabIndex.value == index;

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
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    _tabIndex.value = index;
    _refreshController.refreshCompleted();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _refreshProducts();
    } catch (e) {
      log("Error during refresh: $e");
      Get.snackbar(
        "Refresh Failed",
        "Failed to refresh products. Please try again.",
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
      switch (_tabIndex.value) {
        case 0:
          return _buildProductsContent(sortBySales: true);
        case 1:
          return _buildProductsContent(favoritesOnly: true);
        case 2:
          return _buildProductsContent();
        default:
          return _buildProductsContent();
      }
    });
  }

  Widget _buildProductsContent({bool sortByViews = false, bool sortBySales = false, bool favoritesOnly = false}) {
    log('🛒 Building products content. Products count: ${productsController.products.length}, Loading: ${productsController.isLoading.value}');
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
            if (productsController.isLoading.value &&
                productsController.products.isEmpty) {
              return _buildProductsLoadingGrid();
            }
            // Filter products based on tab
            final displayProducts = favoritesOnly
                ? productsController.products.where((p) => p.isFavorite).toList()
                : productsController.products;
            
            if (displayProducts.isEmpty) {
              return _buildEmptyState();
            } else {
              return _buildProductsGrid(sortByViews: sortByViews, sortBySales: sortBySales, favoritesOnly: favoritesOnly);
            }
          }),

          // Loading overlay
          Obx(() {
            if (productsController.isLoading.value && productsController.products.isNotEmpty) {
              return Container(
                color: Colors.white.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
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

  Widget _buildEmptyState() {
    return Obx(() {
      final isFavoritesTab = _tabIndex.value == 1;

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
                  isFavoritesTab ? Icons.favorite_outline : Icons.shopping_bag_outlined,
                  size: 48,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFavoritesTab ? 'No Favorite Products' : 'No Products Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFavoritesTab
                    ? 'You haven\'t favorited any products yet.\nTap the heart on products you love!'
                    : "Check back later for new products!",
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

  Widget _buildProductsLoadingGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 3;

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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 2,
          ),
        ),
      ),
      staggeredTileBuilder: (index) {
        return const StaggeredTile.count(1, 1.2);
      },
    );
  }

  Widget _buildProductsGrid({bool sortByViews = false, bool sortBySales = false, bool favoritesOnly = false}) {
    return Obx(() {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 3;

      // Get products and filter/sort if needed
      List<Products> products = favoritesOnly
          ? productsController.products.where((p) => p.isFavorite).toList()
          : productsController.products.toList();
      
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
          );
        },
        staggeredTileBuilder: (index) {
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
}
