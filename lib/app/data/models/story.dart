class Story {
  final String id;
  final String mediaUrl;
  final String caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;

  Story({
    required this.id,
    required this.mediaUrl,
    required this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewCount,
  });

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['_id'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      caption: map['caption'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(map['expiresAt'] ?? DateTime.now().toIso8601String()),
      viewCount: map['viewCount'] ?? 0,
    );
  }
}

class UserStory {
  final String userId;
  final String userName;
  final List<Story> stories;

  UserStory({
    required this.userId,
    required this.userName,
    required this.stories,
  });

  factory UserStory.fromMap(Map<String, dynamic> map) {
    return UserStory(
      userId: map['user']['_id'] ?? '',
      userName: map['user']['name'] ?? '',
      stories: (map['stories'] as List<dynamic>?)
              ?.map((story) => Story.fromMap(story))
              .toList() ??
          [],
    );
  }
} 