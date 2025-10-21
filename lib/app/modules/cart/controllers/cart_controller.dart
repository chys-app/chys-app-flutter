import 'dart:developer';
import 'package:chys/app/data/models/cart_item.dart';
import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/services/cart_service.dart';
import 'package:get/get.dart';

class CartController extends GetxController {
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxInt cartItemCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  /// Load cart from storage
  void loadCart() {
    try {
      cartItems.value = CartService.getCartItems();
      _updateCartCount();
      log('Cart loaded: ${cartItems.length} unique items');
    } catch (e) {
      log('Error loading cart: $e');
    }
  }

  /// Add product to cart
  Future<bool> addToCart(Products product) async {
    try {
      final success = await CartService.addToCart(product);
      if (success) {
        loadCart(); // Refresh cart
        return true;
      }
      return false;
    } catch (e) {
      log('Error adding to cart: $e');
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(String productId) async {
    try {
      final success = await CartService.removeFromCart(productId);
      if (success) {
        loadCart(); // Refresh cart
        return true;
      }
      return false;
    } catch (e) {
      log('Error removing from cart: $e');
      return false;
    }
  }

  /// Update item quantity
  Future<bool> updateQuantity(String productId, int quantity) async {
    try {
      final success = await CartService.updateQuantity(productId, quantity);
      if (success) {
        loadCart(); // Refresh cart
        return true;
      }
      return false;
    } catch (e) {
      log('Error updating quantity: $e');
      return false;
    }
  }

  /// Increment quantity
  Future<void> incrementQuantity(String productId) async {
    final item = cartItems.firstWhereOrNull((item) => item.productId == productId);
    if (item != null) {
      await updateQuantity(productId, item.quantity + 1);
    }
  }

  /// Decrement quantity
  Future<void> decrementQuantity(String productId) async {
    final item = cartItems.firstWhereOrNull((item) => item.productId == productId);
    if (item != null) {
      if (item.quantity > 1) {
        await updateQuantity(productId, item.quantity - 1);
      } else {
        await removeFromCart(productId);
      }
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return CartService.isInCart(productId);
  }

  /// Clear cart
  Future<void> clearCart() async {
    try {
      await CartService.clearCart();
      loadCart();
    } catch (e) {
      log('Error clearing cart: $e');
    }
  }

  /// Get total items count (including quantities)
  int getTotalItemCount() {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Update cart count
  void _updateCartCount() {
    cartItemCount.value = getTotalItemCount();
  }

  /// Get cart item by product ID
  CartItem? getCartItem(String productId) {
    return cartItems.firstWhereOrNull((item) => item.productId == productId);
  }
}
