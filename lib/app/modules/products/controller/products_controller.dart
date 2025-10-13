import 'dart:developer';

import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:get/get.dart';

class ProductsController extends GetxController {
  final CustomApiService apiService = CustomApiService();
  final RxList<Products> products = <Products>[].obs;
  final RxBool isLoading = false.obs;

  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && products.isNotEmpty) {
      return;
    }

    try {
      isLoading.value = true;
      final response = await apiService.getRequest('products');
      final parsedProducts = _parseProducts(response);
      products.assignAll(parsedProducts);
      _lastFetch = DateTime.now();
    } catch (e) {
      log('Error fetching products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    await fetchProducts(forceRefresh: true);
  }

  List<Products> productsForTab(int tabIndex) {
    final List<Products> sorted = products.toList(growable: false);

    switch (tabIndex) {
      case 0:
        sorted.sort((a, b) => b.salesCount.compareTo(a.salesCount));
        break;
      case 1:
        sorted.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      default:
        break;
    }

    return sorted;
  }

  List<Products> _parseProducts(dynamic response) {
    if (response == null) {
      return [];
    }

    try {
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map(Products.fromMap)
            .toList();
      }

      if (response is Map<String, dynamic>) {
        if (_looksLikePagination(response)) {
          return PaginatedProducts.fromMap(response).posts;
        }

        final listCandidates = [
          response['products'],
          response['posts'],
          response['data'],
          (response['data'] as Map?)?['products'],
          (response['data'] as Map?)?['posts'],
        ];

        for (final candidate in listCandidates) {
          if (candidate is List) {
            return candidate
                .whereType<Map<String, dynamic>>()
                .map(Products.fromMap)
                .toList();
          }
        }
      }
    } catch (e) {
      log('Error parsing products response: $e');
    }

    return [];
  }

  bool _looksLikePagination(Map<String, dynamic> map) {
    return map.containsKey('currentPage') &&
        map.containsKey('totalPages') &&
        map.containsKey('posts');
  }
}
