import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/cart/controllers/cart_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailView extends StatefulWidget {
  final Products product;

  const ProductDetailView({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _currentImageIndex = 0;
  final ApiClient _apiClient = ApiClient();
  late bool _isFavorite;
  late CartController _cartController;
  
  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
    _cartController = Get.put(CartController());
  }
  
  bool get _isCurrentUserCreator {
    try {
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        final currentUserId = profileController.profile.value?.id;
        return currentUserId != null && currentUserId == widget.product.creator.id;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool get _isBusinessUser {
    try {
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        final userRole = profileController.profile.value?.role;
        final isBusiness = userRole != null && userRole.toLowerCase() == 'biz-user';
        print('🔍 Product Detail - User role: $userRole, Is business: $isBusiness');
        return isBusiness;
      }
      print('🔍 Product Detail - ProfileController not registered');
      return false;
    } catch (e) {
      print('🔍 Product Detail - Error checking business user: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print user type on build
    print('🔍 Building ProductDetailView - Is Business User: $_isBusinessUser');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Get.back(),
            ),
            actions: [
              // Make actions reactive to profile changes
              ...[
                // Edit button - only show for creator
                if (_isCurrentUserCreator)
                  IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    // TODO: Navigate to edit product
                    Get.snackbar(
                      'Edit Product',
                      'Edit functionality coming soon',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                    );
                  },
                ),
              // Promote button - only show for creator
              if (_isCurrentUserCreator)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    Get.toNamed('/promote-product', arguments: widget.product);
                  },
                ),
              // Favorite button - hide for business users
              if (!_isBusinessUser)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isFavorite 
                          ? const Color(0xFFE91E63).withOpacity(0.9)
                          : Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    _toggleFavorite();
                  },
                ),
              // For business users: show promote button
              // For regular users: show shopping cart button
              if (_isBusinessUser)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C851).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    Get.toNamed('/promote-product', arguments: widget.product);
                  },
                )
              else
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095F6).withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
                      ),
                      // Cart item count badge
                      Obx(() {
                        final itemCount = _cartController.cartItemCount.value;
                        if (itemCount > 0) {
                          return Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                itemCount > 99 ? '99+' : itemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                  onPressed: () {
                    Get.toNamed('/cart');
                  },
                ),
              const SizedBox(width: 8),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.product.media.isNotEmpty
                  ? _buildImageCarousel()
                  : _buildImageFallback(),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Description with creator name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.description.isNotEmpty
                              ? widget.product.description
                              : 'No description available',
                          style: const TextStyle( 
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF262626),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'by ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8E8E8E),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.toNamed('/profile', arguments: widget.product.creator.id);
                              },
                              child: const Text(
                                'Awesome Pet Store',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF0095F6),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price and Add to Cart Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0095F6).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.attach_money,
                                color: Color(0xFF0095F6),
                                size: 28,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.price.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0095F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // For business users: Promote button
                        // For regular users: Add to Cart button
                        Expanded(
                          child: _isBusinessUser
                              ? ElevatedButton.icon(
                                  onPressed: () {
                                    Get.toNamed('/promote-product', arguments: widget.product);
                                  },
                                  icon: const Icon(Icons.campaign, size: 20),
                                  label: const Text(
                                    'Promote',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C851),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _addToCart,
                                  icon: const Icon(Icons.shopping_cart, size: 20),
                                  label: const Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0095F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.favorite,
                          count: widget.product.likes.length,
                          label: 'Likes',
                          color: const Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.visibility,
                          count: widget.product.viewCount,
                          label: 'Views',
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.shopping_bag,
                          count: widget.product.salesCount,
                          label: 'Sales',
                          color: const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tags
                  if (widget.product.tags.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.product.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 400,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.product.media.length > 1,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: widget.product.media.map((imageUrl) {
            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => _buildImageFallback(),
            );
          }).toList(),
        ),
        
        // Image indicator
        if (widget.product.media.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.product.media.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Colors.grey,
        size: 80,
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorCard() {
    final creator = widget.product.creator;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0095F6),
            backgroundImage: creator.profilePic.isNotEmpty
                ? NetworkImage(creator.profilePic)
                : null,
            child: creator.profilePic.isEmpty
                ? Text(
                    _getInitials(creator.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.name.isNotEmpty ? creator.name : 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF262626),
                  ),
                ),
                if (creator.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    creator.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Arrow
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _toggleFavorite() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      await _apiClient.favoriteProduct(widget.product.id);
      
      if (!mounted) return;
      
      Get.snackbar(
        _isFavorite ? "Added to Favorites" : "Removed from Favorites",
        _isFavorite 
            ? "${widget.product.description.isNotEmpty ? widget.product.description : 'Product'} added to favorites"
            : "${widget.product.description.isNotEmpty ? widget.product.description : 'Product'} removed from favorites",
        backgroundColor: _isFavorite ? Colors.pink.shade100 : Colors.grey.shade100,
        colorText: _isFavorite ? Colors.pink.shade800 : Colors.grey.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? Colors.pink : Colors.grey,
        ),
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      // Revert on error
      if (!mounted) return;
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      Get.snackbar(
        "Error",
        "Failed to update favorites. Please try again.",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.error, color: Colors.red),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _addToCart() async {
    final success = await _cartController.addToCart(widget.product);
    
    if (success) {
      Get.snackbar(
        "Added to Cart",
        "${widget.product.description.isNotEmpty ? widget.product.description : 'Product'} added to cart",
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.green),
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        "Error",
        "Failed to add product to cart",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.error, color: Colors.red),
        margin: const EdgeInsets.all(16),
      );
    }
  }
}
