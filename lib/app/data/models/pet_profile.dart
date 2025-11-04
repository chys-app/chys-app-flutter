class PetModel {
  final String? id;
  final String? user;
  final bool? isHavePet;
  final String? petType;
  final String? profilePic;
  final String? name;
  final String? breed;
  final String? sex;
  final DateTime? dateOfBirth;
  final String? bio;
  final List<String>? photos;
  final String? color;
  final String? size;
  final num? weight;
  final String? marks;
  final String? microchipNumber; // Deprecated: kept for backward compatibility
  final List<String>? microchipNumbers; // New: supports multiple microchip numbers
  final String? tagId;
  final bool? lostStatus;
  final bool? vaccinationStatus;
  final String? vetName;
  final String? vetContactNumber;
  final List<String>? personalityTraits;
  final List<String>? allergies;
  final String? specialNeeds;
  final String? feedingInstructions;
  final String? dailyRoutine;
  final String? ownerContactNumber;
  final Address? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? userModel;
  final int? v;

  PetModel({
    this.id,
    this.user,
    this.isHavePet,
    this.petType,
    this.profilePic,
    this.name,
    this.breed,
    this.sex,
    this.dateOfBirth,
    this.bio,
    this.photos,
    this.color,
    this.size,
    this.weight,
    this.marks,
    this.microchipNumber,
    this.microchipNumbers,
    this.tagId,
    this.lostStatus,
    this.vaccinationStatus,
    this.vetName,
    this.vetContactNumber,
    this.personalityTraits,
    this.allergies,
    this.specialNeeds,
    this.feedingInstructions,
    this.dailyRoutine,
    this.createdAt,
    this.updatedAt,
    this.userModel,
          this.ownerContactNumber,
      this.address,
      this.v,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    try {
      final dynamic userField = json['user'];

      return PetModel(
      id: json['_id'] as String?,
      user: userField is String 
          ? userField 
          : userField is Map<String, dynamic> 
              ? userField['_id']?.toString() 
              : null,
      userModel: userField is Map<String, dynamic>
          ? UserModel.fromJson(userField)
          : null,
      isHavePet: json['isHavePet'] as bool?,
      petType: json['petType'] as String?,
      ownerContactNumber: json['ownerContactNumber'] as String?,
      address: json['address'] != null && json['address'] is Map<String, dynamic> 
          ? Address.fromJson(json['address']) 
          : null,
      profilePic: json['profilePic'] as String?,
      name: json['name'] as String?,
      breed: json['breed'] as String?,
      sex: json['sex'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      bio: json['bio'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e?.toString() ?? '').toList(),
      color: json['color'] as String?,
      size: json['size'] as String?,
      weight: json['weight'] as num?,
      marks: json['marks'] as String?,
      microchipNumber: json['microchipNumber'] is String 
          ? json['microchipNumber'] as String? 
          : null,
      microchipNumbers: (json['microchipNumbers'] as List?)?.map((e) => e?.toString() ?? '').toList(),
      tagId: json['tagId'] as String?,
      lostStatus: json['lostStatus'] as bool?,
      vaccinationStatus: json['vaccinationStatus'] as bool?,
      vetName: json['vetName'] as String?,
      vetContactNumber: json['vetContactNumber'] as String?,
      personalityTraits: (json['personalityTraits'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .toList(),
      allergies:
          (json['allergies'] as List?)?.map((e) => e?.toString() ?? '').toList(),
      specialNeeds: json['specialNeeds'] as String?,
      feedingInstructions: json['feedingInstructions'] as String?,
      dailyRoutine: json['dailyRoutine'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      v: json['__v'] as int?,
    );
    } catch (e) {
      print('Error parsing PetModel: $e');
      print('PetModel JSON: $json');
      // Return a minimal pet model if parsing fails
      return PetModel(
        id: json['_id']?.toString(),
        name: json['name']?.toString(),
        profilePic: json['profilePic']?.toString(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'isHavePet': isHavePet,
      'petType': petType,
      'profilePic': profilePic,
      'ownerContactNumber': ownerContactNumber,
      'address': address?.toJson(),
      'name': name,
      'breed': breed,
      'sex': sex,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio,
      'photos': photos,
      'color': color,
      'size': size,
      'weight': weight,
      'marks': marks,
      'microchipNumber': microchipNumber,
      'microchipNumbers': microchipNumbers,
      'tagId': tagId,
      'lostStatus': lostStatus,
      'vaccinationStatus': vaccinationStatus,
      'vetName': vetName,
      'vetContactNumber': vetContactNumber,
      'personalityTraits': personalityTraits,
      'allergies': allergies,
      'specialNeeds': specialNeeds,
      'feedingInstructions': feedingInstructions,
      'dailyRoutine': dailyRoutine,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
      'userModel': userModel?.toJson(),
    };
  }

  // Age calculation methods
  int get age {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get ageText {
    if (dateOfBirth == null) return "Unknown age";
    
    final years = age;
    if (years == 0) {
      final months = _calculateMonths();
      if (months == 0) {
        final days = _calculateDays();
        return "$days ${days == 1 ? 'day' : 'days'} old";
      }
      return "$months ${months == 1 ? 'month' : 'months'} old";
    }
    return "$years ${years == 1 ? 'year' : 'years'} old";
  }

  int _calculateMonths() {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    int months = (now.year - dateOfBirth!.year) * 12 + (now.month - dateOfBirth!.month);
    if (now.day < dateOfBirth!.day) months--;
    return months < 0 ? 0 : months;
  }

  int _calculateDays() {
    if (dateOfBirth == null) return 0;
    final now = DateTime.now();
    return now.difference(dateOfBirth!).inDays;
  }

  bool get isBirthdayToday {
    if (dateOfBirth == null) return false;
    final now = DateTime.now();
    return now.month == dateOfBirth!.month && now.day == dateOfBirth!.day;
  }

  bool get isBirthdayThisWeek {
    if (dateOfBirth == null) return false;
    final now = DateTime.now();
    final birthdayThisYear = DateTime(now.year, dateOfBirth!.month, dateOfBirth!.day);
    final daysUntilBirthday = birthdayThisYear.difference(now).inDays;
    return daysUntilBirthday >= 0 && daysUntilBirthday <= 7;
  }

  String get birthdayText {
    if (dateOfBirth == null) return "Unknown";
    return "${dateOfBirth!.month}/${dateOfBirth!.day}/${dateOfBirth!.year}";
  }
}

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final Location? location;

  UserModel({this.id, this.name, this.email, this.location});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        id: json['_id']?.toString(),
        name: json['name']?.toString(),
        email: json['email']?.toString(),
        location: json['location'] is Map<String, dynamic>
            ? Location.fromJson(json['location'])
            : null,
      );
    } catch (e) {
      print('Error parsing UserModel: $e');
      print('UserModel JSON: $json');
      // Return empty user model if parsing fails
      return UserModel();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'location': location?.toJson(),
    };
  }
}

class Location {
  final String? type;
  final List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    try {
      return Location(
        type: json['type']?.toString(),
        coordinates: (json['coordinates'] as List?)
            ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList(),
      );
    } catch (e) {
      print('Error parsing Location: $e');
      print('Location JSON: $json');
      // Return empty location if parsing fails
      return Location();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

class Address {
  final String? state;
  final String? country;
  final String? city;
  final String? zipCode;
  final String? street;

  Address({this.state, this.country, this.city, this.zipCode, this.street});

  factory Address.fromJson(Map<String, dynamic> json) {
    try {
      return Address(
        state: json['state']?.toString(),
        country: json['country']?.toString(),
        city: json['city']?.toString(),
        zipCode: json['zipCode']?.toString(),
        street: json['street']?.toString(),
      );
    } catch (e) {
      print('Error parsing Address: $e');
      print('Address JSON: $json');
      // Return empty address if parsing fails
      return Address();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'country': country,
      'city': city,
      'zipCode': zipCode,
      'street': street,
    };
  }
}
