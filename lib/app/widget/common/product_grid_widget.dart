import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductGridWidget extends StatefulWidget {
  final Products product;
  final VoidCallback? onTap;
  final VoidCallback? onCreatorTap;

  const ProductGridWidget({
    super.key,
    required this.product,
    this.onTap,
    this.onCreatorTap,
  });

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget> {
  late final ProductsController? productsController;

  @override
  void initState() {
    super.initState();
    // Try to find ProductsController, but don't fail if it's not registered
    try {
      productsController = Get.find<ProductsController>();
    } catch (e) {
      productsController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product.media.isNotEmpty ? widget.product.media.first : null;
    final creator = widget.product.creator;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImageFallback(),
                      )
                    : _buildImageFallback(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.description.isNotEmpty
                            ? widget.product.description
                            : 'Untitled product',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Color(0xFFC8E6C9),
                            size: 18,
                          ),
                          Text(
                            widget.product.price.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: widget.onCreatorTap,
                        child: Row(
                          children: [
                            _buildCreatorAvatar(creator.profilePic, creator.name),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Awesome Pet Store',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (creator.bio.isNotEmpty)
                                    Text(
                                      creator.bio,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: productsController != null ? _toggleWishlist : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: productsController != null
                        ? Obx(() {
                            final isInWishlist = productsController!.isInWishlist(widget.product.id);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                                  color: isInWishlist ? Colors.red : Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.likes.length.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          })
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.likes.length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_red_eye,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.viewCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _buildCreatorAvatar(String profilePic, String name) {
    if (profilePic.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (_, __) {},
      );
    }

    final initials = getUserInitials(name);
    final color = getAvatarColor(initials);

    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Colors.grey,
        size: 40,
      ),
    );
  }

  void _toggleWishlist() {
    if (productsController == null) return;
    
    // Check current state before toggling
    final wasInWishlist = productsController!.isInWishlist(widget.product.id);
    
    productsController!.toggleWishlist(widget.product.id);
    
    // Show snackbar feedback based on the action that was taken
    Get.snackbar(
      wasInWishlist ? 'Removed from Wishlist' : 'Added to Wishlist',
      wasInWishlist 
          ? 'Product removed from your wishlist'
          : 'Product added to your wishlist',
      backgroundColor: wasInWishlist ? Colors.grey.shade100 : Colors.pink.shade100,
      colorText: wasInWishlist ? Colors.grey.shade800 : Colors.pink.shade800,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      icon: Icon(
        wasInWishlist ? Icons.favorite_border : Icons.favorite,
        color: wasInWishlist ? Colors.grey : Colors.pink,
      ),
    );
  }
}
