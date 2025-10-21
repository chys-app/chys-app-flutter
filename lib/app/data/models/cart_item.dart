import 'package:chys/app/data/models/product.dart';

class CartItem {
  final String productId;
  final String description;
  final List<String> media;
  final String creatorId;
  final String creatorName;
  int quantity;
  final DateTime addedAt;

  CartItem({
    required this.productId,
    required this.description,
    required this.media,
    required this.creatorId,
    required this.creatorName,
    this.quantity = 1,
    required this.addedAt,
  });

  // Create from Product model
  factory CartItem.fromProduct(Products product) {
    return CartItem(
      productId: product.id,
      description: product.description,
      media: product.media,
      creatorId: product.creator.id,
      creatorName: product.creator.name,
      quantity: 1,
      addedAt: DateTime.now(),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'description': description,
      'media': media,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      description: json['description'] ?? '',
      media: List<String>.from(json['media'] ?? []),
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  CartItem copyWith({
    String? productId,
    String? description,
    List<String>? media,
    String? creatorId,
    String? creatorName,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      description: description ?? this.description,
      media: media ?? this.media,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
