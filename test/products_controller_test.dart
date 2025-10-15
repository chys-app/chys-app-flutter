import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Products product({
    required String id,
    required int sales,
    required int views,
  }) {
    return Products(
      id: id,
      description: '',
      media: const [],
      likes: const [],
      viewCount: views,
      salesCount: sales,
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
    );
  }

  group('ProductsController productsForTab', () {
    late ProductsController controller;

    setUp(() {
      controller = ProductsController();
      controller.products.assignAll([
        product(id: 'a', sales: 5, views: 10),
        product(id: 'b', sales: 12, views: 8),
        product(id: 'c', sales: 7, views: 25),
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
