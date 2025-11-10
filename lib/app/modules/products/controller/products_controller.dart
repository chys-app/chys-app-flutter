import 'dart:developer';

import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:get/get.dart';

class ProductsController extends GetxController {
  final CustomApiService apiService = CustomApiService();
  final ApiClient apiClient = ApiClient();
  final RxList<Products> products = <Products>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasAttemptedFetch = false.obs;
  final RxList<String> wishlist = <String>[].obs;

  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  bool get _isCacheValid =>
      _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration;

  Future<void> fetchProducts({bool forceRefresh = false, bool publicOnly = false, String userId = ''}) async {
    if (!forceRefresh && _isCacheValid && products.isNotEmpty) {
      log('📦 Using cached products (${products.length} items)');
      return;
    }

    try {
      isLoading.value = true;
      hasAttemptedFetch.value = true;
      
      // Determine endpoint based on parameters
      String endpoint;
      if (userId.isNotEmpty) {
        endpoint = 'products/user/$userId?limit=0';
      } else if (publicOnly) {
        endpoint = 'products/public';
      } else {
        endpoint = 'products';
      }
      
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
        if (response.isNotEmpty) {
          log('📦 First product raw data: ${response.first}');
        }
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
            if (candidate.isNotEmpty) {
              log('📦 First product raw data: ${candidate.first}');
            }
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

  Future<void> toggleWishlist(String productId) async {
    try {
      // Check current state before making API call
      final wasInWishlist = wishlist.contains(productId);
      
      // Optimistically update UI state
      if (wasInWishlist) {
        wishlist.remove(productId);
      } else {
        wishlist.add(productId);
      }
      
      // Make API call using CustomApiService
      if (wasInWishlist) {
        await apiService.removeFromWishlist(productId);
        log('❤️ Removed from wishlist: $productId');
      } else {
        await apiService.addToWishlist(productId);
        log('❤️ Added to wishlist: $productId');
      }
    } catch (e) {
      // Revert state on error
      if (wishlist.contains(productId)) {
        wishlist.remove(productId);
      } else {
        wishlist.add(productId);
      }
      log('❌ Error toggling wishlist: $e');
      
      // Show more specific error message
      String errorMessage = 'Failed to update wishlist';
      if (e.toString().contains('401')) {
        errorMessage = 'Please login to update wishlist';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Product not found';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please try again';
      }
      
      Get.snackbar('Error', errorMessage);
    }
  }

  bool isInWishlist(String productId) {
    return wishlist.contains(productId);
  }

  Future<void> fetchWishlist() async {
    try {
      final response = await apiService.getWishlist();
      if (response is List) {
        wishlist.assignAll(response.map((item) => item['_id'].toString()).toList());
        log('❤️ Fetched wishlist: ${wishlist.length} items');
      }
    } catch (e) {
      log('❌ Error fetching wishlist: $e');
    }
  }

  Future<List<Products>> fetchUserWishlist(String userId) async {
    try {
      isLoading.value = true;
      log('🔍 API Debug - Fetching wishlist for user: $userId');
      final response = await apiService.getWishlistByUser(userId);
      log('🔍 API Debug - Response type: ${response.runtimeType}');
      log('🔍 API Debug - Response data: $response');
      
      // Handle the actual response structure: {success: true, wishlist: [...]}
      if (response is Map && response['wishlist'] is List) {
        final wishlistData = response['wishlist'] as List;
        final userWishlistProducts = wishlistData.map((item) {
          log('🔍 API Debug - Parsing item: $item');
          return Products.fromMap(item);
        }).toList();
        
        log('❤️ Fetched user wishlist: ${userWishlistProducts.length} items for user $userId');
        return userWishlistProducts;
      } else if (response is List) {
        // Fallback for direct list response
        final userWishlistProducts = response.map((item) {
          log('🔍 API Debug - Parsing item: $item');
          return Products.fromMap(item);
        }).toList();
        
        log('❤️ Fetched user wishlist: ${userWishlistProducts.length} items for user $userId');
        return userWishlistProducts;
      } else {
        log('🔍 API Debug - Response is not expected format, got: ${response.runtimeType}');
      }
      return [];
    } catch (e) {
      log('❌ Error fetching user wishlist: $e');
      return [];
    } finally {
      isLoading.value = false;
    }
  }
}
