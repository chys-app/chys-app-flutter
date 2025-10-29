import 'dart:developer';

import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:get/get.dart';

class ProductsController extends GetxController {
  final CustomApiService apiService = CustomApiService();
  final RxList<Products> products = <Products>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasAttemptedFetch = false.obs;

  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> fetchProducts({bool forceRefresh = false, bool publicOnly = false}) async {
    if (!forceRefresh && _isCacheValid && products.isNotEmpty) {
      log('📦 Using cached products (${products.length} items)');
      return;
    }

    try {
      isLoading.value = true;
      hasAttemptedFetch.value = true;
      // Use public endpoint for marketplace to get all products
      final endpoint = publicOnly ? 'products/public' : 'products';
      log('📦 Fetching products from API endpoint: $endpoint');
      final response = await apiService.getRequest(endpoint);
      log('📦 API Response: $response');
      final parsedProducts = _parseProducts(response);
      log('📦 Parsed ${parsedProducts.length} products');
      products.assignAll(parsedProducts);
      _lastFetch = DateTime.now();
      log('📦 Products updated successfully: ${products.length} items');
    } catch (e) {
      log('❌ Error fetching products: $e');
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
      log('⚠️ Response is null');
      return [];
    }

    try {
      log('📦 Response type: ${response.runtimeType}');
      
      if (response is List) {
        log('📦 Response is a List with ${response.length} items');
        return response
            .whereType<Map<String, dynamic>>()
            .map(Products.fromMap)
            .toList();
      }

      if (response is Map<String, dynamic>) {
        log('📦 Response is a Map with keys: ${response.keys.join(", ")}');
        
        if (_looksLikePagination(response)) {
          log('📦 Detected pagination structure');
          return PaginatedProducts.fromMap(response).posts;
        }

        final listCandidates = [
          response['products'],
          response['posts'],
          response['data'],
          (response['data'] as Map?)?['products'],
          (response['data'] as Map?)?['posts'],
        ];

        for (int i = 0; i < listCandidates.length; i++) {
          final candidate = listCandidates[i];
          if (candidate is List) {
            log('📦 Found products list at candidate index $i with ${candidate.length} items');
            return candidate
                .whereType<Map<String, dynamic>>()
                .map(Products.fromMap)
                .toList();
          }
        }
        
        log('⚠️ No valid products list found in response');
      }
    } catch (e) {
      log('❌ Error parsing products response: $e');
    }

    return [];
  }

  bool _looksLikePagination(Map<String, dynamic> map) {
    return map.containsKey('currentPage') &&
        map.containsKey('totalPages') &&
        map.containsKey('posts');
  }
}
