import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Products createProduct({
    required String id,
    required int sales,
    required int views,
    double price = 0.0,
  }) {
    return Products(
      id: id,
      description: '',
      media: const [],
      likes: const [],
      viewCount: views,
      salesCount: sales,
      price: price,
      tags: const [],
      isActive: true,
      comments: const [],
      creator: CreatorMini(
        id: 'creator-$id',
        name: 'Creator $id',
        bio: '',
        profilePic: '',
      ),
      createdAt: '',
      updatedAt: '',
      isCurrentUserLiked: false,
      isFunded: false,
      fundedAmount: 0,
      fundCount: 0,
      isFavorite: false,
      v: 0,
      isInWishlist: false,
    );
  }

  group('ProductsController productsForTab', () {
    late ProductsController controller;

    setUp(() {
      controller = ProductsController();
      controller.products.addAll([
        createProduct(id: 'a', sales: 5, views: 10),
        createProduct(id: 'b', sales: 12, views: 8),
        createProduct(id: 'c', sales: 7, views: 25),
      ]);
    });

    test('sorts by salesCount when Best Sellers tab selected', () {
      final result = controller.productsForTab(0);
      expect(result.map((p) => p.id).toList(), ['b', 'c', 'a']);
    });

    test('sorts by viewCount when Most Viewed tab selected', () {
      final result = controller.productsForTab(1);
      expect(result.map((p) => p.id).toList(), ['c', 'a', 'b']);
    });

    test('keeps original order for All tab', () {
      final result = controller.productsForTab(2);
      expect(result.map((p) => p.id).toList(), ['a', 'b', 'c']);
    });
  });
}
