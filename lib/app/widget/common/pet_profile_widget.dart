import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/post.dart';
import '../../routes/app_routes.dart';

class PetProfileWidget extends StatelessWidget {
  final Posts post;
  final double imageSize;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final bool showBio;
  final Color? bioColor;
  final double? bioFontSize;

  const PetProfileWidget({
    Key? key,
    required this.post,
    this.imageSize = 32.0,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w600,
    this.textColor = Colors.white,
    this.showBio = true,
    this.bioColor,
    this.bioFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile image with error handling
        Stack(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: _buildPetProfileImage(),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClickableUsername(),
              if (showBio && post.creator.bio.isNotEmpty)
                Text(
                  post.creator.bio,
                  style: TextStyle(
                    color: bioColor ?? Colors.white.withOpacity(0.7),
                    fontSize: bioFontSize ?? 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableUsername() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.otherUserProfile, arguments: post.creator.id);
      },
      child: Text(
        post.creator.name,
        style: TextStyle(
          color: textColor,
          fontWeight: fontWeight,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildPetProfileImage() {
    // Find the first image in the media list (not video)
    String? petImageUrl;
    for (var mediaUrl in post.media) {
      if (!_isVideo(mediaUrl)) {
        petImageUrl = mediaUrl;
        break;
      }
    }

    if (petImageUrl == null || petImageUrl.isEmpty) {
      return _buildFallbackProfileImage();
    }

    return Image.network(
      petImageUrl,
      fit: BoxFit.cover,
      width: imageSize,
      height: imageSize,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackProfileImage();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackProfileImage() {
    final userName = post.creator.name;
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: imageSize * 0.375, // 12px for 32px container
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.mov', '.webm', '.avi'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  String getUserInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Color getAvatarColor(String initials) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
    ];
    final index = initials.hashCode % colors.length;
    return colors[index];
  }
}
