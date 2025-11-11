import 'dart:developer';
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
    
    // Validate product ID
    final productId = widget.product.id;
    if (productId.isEmpty || productId == 'null') {
      log('❌ Cannot toggle wishlist - invalid product ID: $productId');
      Get.snackbar('Error', 'Invalid product data. Please refresh the page.');
      return;
    }
    
    // Check current state before toggling
    final wasInWishlist = productsController!.isInWishlist(productId);
    
    productsController!.toggleWishlist(productId);
    
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
