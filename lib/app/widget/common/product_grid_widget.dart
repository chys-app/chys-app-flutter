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
    
    // Debug: Log discount value
    print('🔍 Product Grid - Discount: ${widget.product.discount}');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.zero,
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Price and Discount
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Color(0xFFC8E6C9),
                            size: 16,
                          ),
                          Text(
                            widget.product.price.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Color(0xFFC8E6C9),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      // Discount (if available)
                      if (widget.product.discount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${widget.product.discount.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}
