import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/models/podcast_model.dart';

class PodcastBannerCard extends StatelessWidget {
  final Podcast podcast;

  const PodcastBannerCard({super.key, required this.podcast});

  @override
  Widget build(BuildContext context) {
    final bannerUrl = (podcast.bannerImage?.isNotEmpty ?? false)
        ? podcast.bannerImage!
        : 'https://fastly.picsum.photos/id/1/600/400.jpg?hmac=jH5bDkLr6Tgy3oAg5khKCHeunZMHq0ehBZr6vGifPLY';

    final heading1 = podcast.heading1;
    final heading2 = podcast.heading2;
    final bannerLine = podcast.bannerLine;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 🎯 Banner background
          Image.network(
            bannerUrl,
            fit: BoxFit.cover,
            height: 220,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              height: 220,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child:
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
            ),
          ),

          // ✨ Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading 1
                  Text(
                    heading1.text,
                    style: TextStyle(
                      color: _parseColor(heading1.color),
                      fontFamily: heading1.font,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Heading 2
                  Text(
                    heading2.text,
                    style: TextStyle(
                      color: _parseColor(heading2.color),
                      fontFamily: heading2.font,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    bannerLine.text,
                    style: TextStyle(
                      color: _parseColor(bannerLine.color),
                      fontFamily: bannerLine.font,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 👤 Host info
          Positioned(
            bottom: 12,
            right: 12,
            child: _hostInfo(podcast.host),
          ),
        ],
      ),
    );
  }

  Widget _hostInfo(UserMini host) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(host.profilePic),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (host.bio.isNotEmpty)
                    Text(
                      host.bio,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
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
    );
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }
}
