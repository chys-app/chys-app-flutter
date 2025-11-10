import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/modules/donate/controller/donate_controller.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:chys/app/widget/common/post_grid_widget.dart';
import 'package:chys/app/widget/common/wishlist_product_widget.dart';
import 'package:chys/app/widget/shimmer/cat_quote_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class ProfileContentWidget extends StatelessWidget {
  final AddoredPostsController postController;
  final DonateController donateController;
  final ProductsController productsController;
  final List<dynamic> userWishlistProducts;
  final bool isOtherUserProfile;

  const ProfileContentWidget({
    Key? key,
    required this.postController,
    required this.donateController,
    required this.productsController,
    required this.userWishlistProducts,
    this.isOtherUserProfile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This widget provides content, not the full UI structure
    // The actual TabBarView is handled by ProfileTabsWidget
    return Container();
  }

  // Individual tab content widgets
  Widget get postsTabContent => _buildPostsTabContent();
  Widget get donateTabContent => _buildDonateTabContent();
  Widget get wishlistTabContent => _buildWishlistTabContent();

  Widget _buildPostsTabContent() {
    return Obx(() {
      if (postController.isLoading.value) {
        return const CatQuoteCardShimmer();
      }

      if (postController.posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "No posts yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOtherUserProfile 
                  ? "This user hasn't shared any posts yet"
                  : "Start sharing your pet's adventures!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final crossAxisCount = screenWidth > 600 ? 4 : 3;

          return StaggeredGridView.countBuilder(
            padding: const EdgeInsets.all(16),
            crossAxisCount: crossAxisCount,
            itemCount: postController.posts.length,
            itemBuilder: (context, index) {
              final post = postController.posts[index];
              return PostGridWidget(
                post: post,
                addoredPostsController: postController,
                onTapCard: () => Get.toNamed('/post-detail', arguments: post.id),
              );
            },
            staggeredTileBuilder: (index) => StaggeredTile.count(1, 1),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          );
        },
      );
    });
  }

  Widget _buildDonateTabContent() {
    return Obx(() {
      if (donateController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Donate Feature",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Coming soon!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWishlistTabContent() {
    return Obx(() {
      if (productsController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (userWishlistProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Color(0xFF0095F6),
              ),
              const SizedBox(height: 16),
              Text(
                "Wishlist is empty",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isOtherUserProfile
                  ? "This user hasn't added any products to their wishlist"
                  : "Your saved products will appear here",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: userWishlistProducts.length,
        itemBuilder: (context, index) {
          final product = userWishlistProducts[index];
          return WishlistProductWidget(product: product);
        },
      );
    });
  }
}
