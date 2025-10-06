class OwnProfileModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String createdAt;
  final String updatedAt;
  final int v;
  final String? fcmToken;
  final String? bio;
  final String? profilePic;
  final double? lat;
  final double? lng;
  final int? numericUid;
  final int? totalFundReceived;
  final BankDetailsModel? bankDetails;
  final List<String> followers;
  final List<String> following;
  final bool isFollowing;
  final String? address;
  final String? city;
  final String? zipCode;
  final String? state;
  final String? country;

  OwnProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    this.fcmToken,
    this.bio,
    this.profilePic,
    this.lat,
    this.lng,
    this.numericUid,
    this.totalFundReceived,
    this.bankDetails,
    this.followers = const [],
    this.following = const [],
    this.isFollowing = false,
    this.address,
    this.city,
    this.zipCode,
    this.state,
    this.country,
  });

  factory OwnProfileModel.fromMap(Map<String, dynamic> map) {
    // Parse followers list
    List<String> followersList = [];
    if (map['followers'] is List) {
      followersList = (map['followers'] as List)
          .map((follower) => follower['_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }

    // Parse following list
    List<String> followingList = [];
    if (map['following'] is List) {
      followingList = (map['following'] as List)
          .map((following) => following['_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }

    return OwnProfileModel(
      id: map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      v: map['__v'] ?? map['v'] ?? 0,
      fcmToken: map['fcmToken']?.toString(),
      bio: (map['bio']?.toString().isNotEmpty ?? false) ? map['bio'] : null,
      profilePic: (map['profilePic']?.toString().isNotEmpty ?? false)
          ? map['profilePic']
          : null,
      lat: _parseDouble(map['lat']),
      lng: _parseDouble(map['lng']),
      numericUid: map['numericUid'] is int ? map['numericUid'] : null,
      totalFundReceived:
          map['totalFundReceived'] is int ? map['totalFundReceived'] : null,
      bankDetails: map['bankDetails'] is Map<String, dynamic>
          ? BankDetailsModel.fromMap(map['bankDetails'])
          : null,
      followers: followersList,
      following: followingList,
      isFollowing: map['isFollowing'] == true,
      address: map['address']?.toString(),
      city: map['city']?.toString(),
      zipCode: map['zipCode']?.toString(),
      state: map['state']?.toString(),
      country: map['country']?.toString(),
    );
  }

  // Create a copy method to update follow state
  OwnProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? createdAt,
    String? updatedAt,
    int? v,
    String? fcmToken,
    String? bio,
    String? profilePic,
    double? lat,
    double? lng,
    int? numericUid,
    int? totalFundReceived,
    BankDetailsModel? bankDetails,
    List<String>? followers,
    List<String>? following,
    bool? isFollowing,
    String? address,
    String? city,
    String? zipCode,
    String? state,
    String? country,
  }) {
    return OwnProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      profilePic: profilePic ?? this.profilePic,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      numericUid: numericUid ?? this.numericUid,
      totalFundReceived: totalFundReceived ?? this.totalFundReceived,
      bankDetails: bankDetails ?? this.bankDetails,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isFollowing: isFollowing ?? this.isFollowing,
      address: address ?? this.address,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class BankDetailsModel {
  final String accountHolderName;
  final String routingNumber;
  final String accountNumber;
  final String bankName;
  final String accountType;
  final String? bankAddress;

  BankDetailsModel({
    required this.accountHolderName,
    required this.routingNumber,
    required this.accountNumber,
    required this.bankName,
    required this.accountType,
    this.bankAddress,
  });

  factory BankDetailsModel.fromMap(Map<String, dynamic> map) {
    return BankDetailsModel(
      accountHolderName: map['accountHolderName']?.toString() ?? '',
      routingNumber: map['routingNumber']?.toString() ?? '',
      accountNumber: map['accountNumber']?.toString() ?? '',
      bankName: map['bankName']?.toString() ?? '',
      accountType: map['accountType']?.toString() ?? '',
      bankAddress: (map['bankAddress']?.toString().isNotEmpty ?? false)
          ? map['bankAddress']
          : null,
    );
  }
}
