import 'dart:developer';
import 'package:chys/app/data/models/cart_item.dart';
import 'package:chys/app/data/models/product.dart';
import 'package:get_storage/get_storage.dart';

class CartService {
  static final _storage = GetStorage();
  static const String _cartKey = 'shopping_cart';

  /// Get all cart items
  static List<CartItem> getCartItems() {
    try {
      final cartData = _storage.read<List>(_cartKey);
      if (cartData == null) return [];
      
      return cartData
          .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      log('Error loading cart items: $e');
      return [];
    }
  }

  /// Save cart items
  static Future<void> _saveCartItems(List<CartItem> items) async {
    try {
      final cartData = items.map((item) => item.toJson()).toList();
      await _storage.write(_cartKey, cartData);
      log('Cart saved: ${items.length} items');
    } catch (e) {
      log('Error saving cart: $e');
    }
  }

  /// Add product to cart
  static Future<bool> addToCart(Products product) async {
    try {
      final items = getCartItems();
      
      // Check if product already exists in cart
      final existingIndex = items.indexWhere((item) => item.productId == product.id);
      
      if (existingIndex != -1) {
        // Increment quantity
        items[existingIndex].quantity++;
        log('Incremented quantity for product ${product.id}');
      } else {
        // Add new item
        items.add(CartItem.fromProduct(product));
        log('Added new product to cart: ${product.id}');
      }
      
      await _saveCartItems(items);
      return true;
    } catch (e) {
      log('Error adding to cart: $e');
      return false;
    }
  }

  /// Remove product from cart
  static Future<bool> removeFromCart(String productId) async {
    try {
      final items = getCartItems();
      items.removeWhere((item) => item.productId == productId);
      await _saveCartItems(items);
      log('Removed product from cart: $productId');
      return true;
    } catch (e) {
      log('Error removing from cart: $e');
      return false;
    }
  }

  /// Update item quantity
  static Future<bool> updateQuantity(String productId, int quantity) async {
    try {
      final items = getCartItems();
      final index = items.indexWhere((item) => item.productId == productId);
      
      if (index != -1) {
        if (quantity <= 0) {
          // Remove item if quantity is 0 or less
          items.removeAt(index);
        } else {
          items[index].quantity = quantity;
        }
        await _saveCartItems(items);
        log('Updated quantity for product $productId: $quantity');
        return true;
      }
      return false;
    } catch (e) {
      log('Error updating quantity: $e');
      return false;
    }
  }

  /// Check if product is in cart
  static bool isInCart(String productId) {
    final items = getCartItems();
    return items.any((item) => item.productId == productId);
  }

  /// Get cart item count
  static int getCartItemCount() {
    final items = getCartItems();
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get unique products count
  static int getUniqueProductCount() {
    return getCartItems().length;
  }

  /// Clear entire cart
  static Future<void> clearCart() async {
    try {
      await _storage.remove(_cartKey);
      log('Cart cleared');
    } catch (e) {
      log('Error clearing cart: $e');
    }
  }

  /// Get cart item by product ID
  static CartItem? getCartItem(String productId) {
    final items = getCartItems();
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }
}
