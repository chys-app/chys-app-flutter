import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/app_size.dart';
import '../../data/models/podcast_model.dart';
import '../../routes/app_routes.dart';

class PodcastGridWidget extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  final VoidCallback? onUserProfileTap;

  const PodcastGridWidget({
    Key? key,
    required this.podcast,
    this.onTap,
    this.onUserProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bannerUrl = (podcast.bannerImage?.isNotEmpty ?? false)
        ? podcast.bannerImage!
        : 'https://fastly.picsum.photos/id/1/600/400.jpg?hmac=jH5bDkLr6Tgy3oAg5khKCHeunZMHq0ehBZr6vGifPLY';
    final status = podcast.status.toLowerCase();
    final statusColor = status == 'live'
        ? Colors.green
        : status == 'ended'
            ? Colors.red
            : Colors.orange;

    return GestureDetector(
      onTap: onTap ??
          () {
            Get.toNamed(AppRoutes.podCastView, arguments: podcast);
          },
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          child: Stack(
            children: [
              // Banner image
              SizedBox(
                width: double.infinity,
                height: 220,
                child: Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image,
                        size: 40, color: Colors.grey),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Status badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status == 'live'
                        ? 'LIVE'
                        : status == 'ended'
                            ? 'ENDED'
                            : 'SCHEDULED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Guests count
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${podcast.guests.length} guests',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Podcast title
              Positioned(
                left: 16,
                right: 16,
                bottom: 60,
                child: Text(
                  podcast.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
              // Podcast description
              Positioned(
                left: 16,
                right: 16,
                bottom: 38,
                child: Text(
                  podcast.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // Host info
              Positioned(
                left: 16,
                bottom: 12,
                child: GestureDetector(
                  onTap: onUserProfileTap,
                  child: Row(
                    children: [
                      _buildHostAvatar(podcast.host),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            podcast.host.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (podcast.host.bio.isNotEmpty)
                            Text(
                              podcast.host.bio,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostAvatar(dynamic host) {
    final profilePic = host.profilePic;
    final userName = host.name ?? 'Host';
    
    if (profilePic != null && profilePic.toString().isNotEmpty && profilePic != 'null') {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback handled by child
        },
        child: _buildInitialsAvatar(userName, 16),
      );
    } else {
      return _buildInitialsAvatar(userName, 16);
    }
  }

  Widget _buildInitialsAvatar(String userName, double radius) {
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
