import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/widget/common/product_grid_widget.dart';
import 'package:flutter/material.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

class BusinessProductsGrid extends StatelessWidget {
  final List<Products> products;
  final ScrollController scrollController;
  final Widget? emptyState;

  const BusinessProductsGrid({
    super.key,
    required this.products,
    required this.scrollController,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth == double.infinity
            ? MediaQuery.of(context).size.width
            : constraints.maxWidth;

        final crossAxisCount = width > 900
            ? 4
            : width > 600
                ? 3
                : 3;

        return StaggeredGridView.countBuilder(
          controller: scrollController,
          primary: false,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          padding: const EdgeInsets.all(16),
          itemCount: products.isEmpty ? 1 : products.length,
          itemBuilder: (context, index) {
            if (products.isEmpty) {
              return emptyState ?? const SizedBox.shrink();
            }
            final product = products[index];
            return ProductGridWidget(product: product);
          },
          staggeredTileBuilder: (index) {
            if (products.isEmpty) {
              return const StaggeredTile.count(1, 1.2);
            }
            final heightRatio = 1.0 + (index % 4) * 0.2;
            return StaggeredTile.count(1, heightRatio);
          },
        );
      },
    );
  }
}

class BusinessProductsAddButton extends StatelessWidget {
  final VoidCallback? onTap;

  const BusinessProductsAddButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0095F6), Color(0xFF00C851)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0095F6).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
