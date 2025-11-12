import 'package:get/get_rx/src/rx_types/rx_types.dart';

class CreatorMini {
  final String id;
  final String name;
  final String bio;
  final String profilePic;
  final bool isFollowing;

  CreatorMini({
    required this.id,
    required this.name,
    required this.bio,
    required this.profilePic,
    this.isFollowing = false,
  });

  factory CreatorMini.fromMap(Map<dynamic, dynamic> map) {
    final originalProfilePic = map['profilePic']?.toString();
    final finalProfilePic = (originalProfilePic?.isNotEmpty ?? false)
        ? originalProfilePic!
        : 'https://ui-avatars.com/api/?name=User&background=0095F6&color=fff&size=150';
    
    // Try multiple possible field names for the user's name, preferring actual names over email
    String name = map['name']?.toString() ?? 
                  map['userName']?.toString() ?? 
                  map['username']?.toString() ?? 
                  map['firstName']?.toString() ?? 
                  map['lastName']?.toString() ??
                  '';
    
    // If no name found, try to construct from firstName + lastName
    if (name.isEmpty && map['firstName'] != null && map['lastName'] != null) {
      name = '${map['firstName']} ${map['lastName']}';
    }
    
    // Only use email as last resort if no name fields are available
    if (name.isEmpty) {
      name = map['email']?.toString() ?? 'Unknown User';
    }
    
    return CreatorMini(
      id: map['_id']?.toString() ?? '',
      name: name,
      bio: map['bio']?.toString() ?? '',
      profilePic: finalProfilePic,
      isFollowing: map['isFollowing'] == true,
    );
  }
}

class PaginatedProducts {
  final int currentPage;
  final int totalPages;
  final int totalProducts;
  final List<Products> posts;

  PaginatedProducts({
    required this.currentPage,
    required this.totalPages,
    required this.totalProducts,
    required this.posts,
  });

  factory PaginatedProducts.fromMap(Map<String, dynamic> map) {
    final List<dynamic> postList = map["posts"] ?? [];

    return PaginatedProducts(
      currentPage: map["currentPage"] ?? 1,
      totalPages: map["totalPages"] ?? 1,
      totalProducts: map["totalProducts"] ?? 0,
      posts: postList.map((p) => Products.fromMap(p)).toList(),
    );
  }
}

class Products {
  final String id;
  final String description;
  final List<String> media;
  RxList<dynamic> likes;
  final int viewCount;
  final int salesCount;
  final double price;
  final double discount;
  final List<String> tags;
  final bool isActive;
  RxList<Map<String, dynamic>> comments;
  final CreatorMini creator;
  final String createdAt;
  final String updatedAt;
  bool isFavorite;
  final int v;
  bool isCurrentUserLiked;
  RxBool isFunded;
  RxInt fundedAmount;
  RxInt fundCount;
  bool isInWishlist;

  Products({
    required this.id,
    required this.description,
    required this.media,
    required List<dynamic> likes,
    required this.viewCount,
    required this.salesCount,
    required this.price,
    required this.discount,
    required this.tags,
    required this.isActive,
    required List<dynamic> comments,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    required this.isCurrentUserLiked,
    required bool isFunded,
    required int fundedAmount,
    required int fundCount,
    required this.isFavorite,
    required this.v,
    required this.isInWishlist,
  })  : likes = RxList<dynamic>(likes),
        comments =
            RxList<Map<String, dynamic>>(comments.cast<Map<String, dynamic>>()),
        fundedAmount = fundedAmount.obs,
        fundCount = fundCount.obs,
        isFunded = isFunded.obs;

  factory Products.fromMap(Map<String, dynamic> map) {
    // Debug: Print the raw map to see what fields are available
    print('🔍 Products.fromMap - Raw map keys: ${map.keys.toList()}');
    print('🔍 Products.fromMap - product name field: ${map['name']}');
    print('🔍 Products.fromMap - owner field type: ${map['owner'].runtimeType}');
    print('🔍 Products.fromMap - owner field value: ${map['owner']}');
    
    // Extract and validate product ID
    final productId = map["_id"]?.toString() ?? '';
    print('🔍 Products.fromMap - Extracted product ID: "$productId"');
    if (productId.isEmpty) {
      print('⚠️ Products.fromMap - WARNING: Product ID is empty!');
    }
    
    // The API uses 'owner' field for creator information
    dynamic creatorData = map['owner'] ?? map['creator'] ?? map['createdBy'] ?? map['user'];
    
    final creatorMap = creatorData is Map<String, dynamic>
        ? creatorData as Map<String, dynamic>
        : (creatorData is Map
            ? Map<String, dynamic>.from(creatorData)
            : {});
    
    print('🔍 Products.fromMap - Final creatorMap: $creatorMap');
    print('🔍 Products.fromMap - creatorMap keys: ${creatorMap.keys.toList()}');

    return Products(
      isFunded: map["isFunded"] == true,
      id: productId,
      description: map["description"]?.toString() ?? '',
      media: _safeStringList(map["media"]),
      likes: map["likes"] ?? [],
      isCurrentUserLiked: map['isLike'] != null
          ? map['isLike'] == true
          : map['isCurrentUserLiked'] == true,
      viewCount: map["viewCount"] is int
          ? map["viewCount"]
          : int.tryParse(map["viewCount"]?.toString() ?? '') ?? 0,
      salesCount: map["salesCount"] is int
          ? map["salesCount"]
          : int.tryParse(map["salesCount"]?.toString() ?? '') ?? 0,
      price: map["price"] is num
          ? (map["price"] as num).toDouble()
          : double.tryParse(map["price"]?.toString() ?? '') ?? 0.0,
      discount: map["discount"] is num
          ? (map["discount"] as num).toDouble()
          : double.tryParse(map["discount"]?.toString() ?? '') ?? 0.0,
      tags: _safeStringList(map["tags"]),
      isActive: map["isActive"] == true,
      comments: map["comments"] ?? [],
      creator: CreatorMini.fromMap(creatorMap),
      createdAt: map["createdAt"]?.toString() ?? '',
      updatedAt: map["updatedAt"]?.toString() ?? '',
      isFavorite: map["isFavorite"] == true,
      isInWishlist: map["isInWishlist"] == true || map["isWishlisted"] == true,
      fundedAmount: map["viewCount"] is int
          ? map["viewCount"]
          : int.tryParse(map["viewCount"]?.toString() ?? '') ?? 0,
      fundCount: map["fundCount"] is int
          ? map["fundCount"]
          : int.tryParse(map["fundCount"]?.toString() ?? '') ?? 0,
      v: map["__v"] is int
          ? map["__v"]
          : int.tryParse(map["__v"]?.toString() ?? '') ?? 0,
    );
  }

  static List<String> _safeStringList(dynamic list) {
    if (list is List) {
      return list.map((item) => item.toString()).toList();
    }
    return [];
  }
}
