class DonationModel {
  final String? id;
  final String? title;
  final String? description;
  final num? targetAmount;
  final num? collectedAmount;
  final CreatedBy? createdBy;
  final bool? isActive;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DonationModel({
    this.id,
    this.title,
    this.description,
    this.targetAmount,
    this.collectedAmount,
    this.createdBy,
    this.isActive,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      targetAmount: json['targetAmount'],
      collectedAmount: json['collectedAmount'],
      createdBy: json['createdBy'] != null
          ? CreatedBy.fromJson(json['createdBy'])
          : null,
      isActive: json['isActive'],
      image: json['image'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class CreatedBy {
  final String? id;
  final String? email;

  CreatedBy({
    this.id,
    this.email,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id'],
      email: json['email'],
    );
  }
}
