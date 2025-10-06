class UserMini {
  final String id;
  final String name;
  final String bio;
  final String profilePic;

  UserMini({
    required this.id,
    required this.name,
    required this.bio,
    required this.profilePic,
  });

  factory UserMini.fromJson(Map<String, dynamic> json) {
    return UserMini(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      profilePic: (json['profilePic']?.toString().isNotEmpty ?? false)
          ? json['profilePic']
          : 'https://i.pravatar.cc/150?img=6',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'bio': bio,
      'profilePic': profilePic,
    };
  }
}

class StyledText {
  final String text;
  final String font;
  final String color;
  final String? background;

  StyledText({
    required this.text,
    required this.font,
    required this.color,
    this.background,
  });

  factory StyledText.fromJson(Map<String, dynamic>? json) {
    return StyledText(
      text: json?['text'] ?? '',
      font: json?['font'] ?? 'Roboto',
      color: json?['color'] ?? '#000000',
      background: json?['background'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'font': font,
      'color': color,
      'background': background,
    };
  }
}

class Podcast {
  final String id;
  final UserMini host;
  final List<UserMini> guests;
  final List<dynamic> petProfiles;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final String status;
  final String agoraChannel;
  final String? bannerImage;
  final DateTime createdAt;

  // New StyledText fields
  final StyledText heading1;
  final StyledText heading2;
  final StyledText bannerLine;

  Podcast({
    required this.id,
    required this.host,
    required this.guests,
    required this.petProfiles,
    required this.title,
    required this.description,
    required this.scheduledAt,
    required this.status,
    required this.agoraChannel,
    required this.createdAt,
    this.bannerImage,
    required this.heading1,
    required this.heading2,
    required this.bannerLine,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['_id'] ?? '',
      host: UserMini.fromJson(json['host']),
      guests: (json['guests'] as List<dynamic>? ?? [])
          .map((e) => UserMini.fromJson(e))
          .toList(),
      petProfiles: json['petProfiles'] ?? [],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: json['status'] ?? '',
      agoraChannel: json['agoraChannel'] ?? '',
      bannerImage: json['bannerImage'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),

      // StyledText parsing
      heading1: StyledText.fromJson(json['heading1']),
      heading2: StyledText.fromJson(json['heading2']),
      bannerLine: StyledText.fromJson(json['bannerLine']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'host': host.toJson(),
      'guests': guests.map((g) => g.toJson()).toList(),
      'petProfiles': petProfiles,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status,
      'agoraChannel': agoraChannel,
      'bannerImage': bannerImage,
      'createdAt': createdAt.toIso8601String(),
      'heading1': heading1.toJson(),
      'heading2': heading2.toJson(),
      'bannerLine': bannerLine.toJson(),
    };
  }
}
