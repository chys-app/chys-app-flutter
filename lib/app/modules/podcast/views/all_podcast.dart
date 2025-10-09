import 'dart:developer';

import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:chys/app/modules/podcast/controllers/podcast_controller.dart';
import 'package:chys/app/services/common_service.dart';
import 'package:chys/app/services/pet_ownership_service.dart';
import 'package:chys/app/widget/shimmer/lottie_animation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ home/home_controller.dart';
import '../../ home/story_view.dart';
import '../../ home/widget/custom_header.dart';
import '../../ home/widget/floating_action_button.dart';
import '../../../core/const/app_text.dart';
import '../../../core/utils/app_size.dart';
import '../../../data/models/podcast_model.dart';
import '../../../data/models/story.dart';
import '../../../routes/app_routes.dart';
import '../../../services/custom_Api.dart';
import '../../../widget/shimmer/cat_quote_shimmer.dart';
import '../../../widget/shimmer/story_shimmer.dart';

class AllPodcast extends StatelessWidget {
  const AllPodcast({super.key});

  @override
  Widget build(BuildContext context) {
    final storyController = Get.put(HomeController());
    final podCastController = Get.find<CreatePodCastController>();
    final podCastCallController = Get.find<PodcastController>();
    final CustomApiService _apiService = Get.put(CustomApiService());
    final mapController = Get.find<MapController>();

    Future<void> _onRefresh() async {
      await podCastController.getAllPodCast();
    }

    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSize.h2,
                        children: [
                          SizedBox(
                            height: AppSize.h2,
                          ),
                          buildCustomHeader(),
                          SizedBox(
                            height: AppSize.getHeight(10),
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: _apiService
                                  .getRequest('story/public')
                                  .then((res) => res as Map<String, dynamic>),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const StoryShimmerList();
                                }

                                if (snapshot.hasError) {
                                  log("Error is ${snapshot.error}");
                                  return const Center(
                                      child: Text('Error loading stories'));
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!['success'] != true) {
                                  return const SizedBox.shrink();
                                }

                                final List<dynamic> storiesData =
                                    snapshot.data!['data'];
                                final List<UserStory> userStories = storiesData
                                    .map((story) => UserStory.fromMap(story))
                                    .toList();

                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  physics: const ScrollPhysics(),
                                  itemCount: userStories.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return GestureDetector(
                                        onTap: () {
                                          storyController.uploadStory();
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: const Column(
                                            children: [
                                              SizedBox(
                                                width: 60,
                                                height: 60,
                                                child: CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: Colors.grey,
                                                  child: Icon(Icons.add,
                                                      color: Colors.white),
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              AppText(text: "Add Story"),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    final userStory = userStories[index - 1];
                                    final hasStories =
                                        userStory.stories.isNotEmpty;
                                    final latestStory = hasStories
                                        ? userStory.stories.first
                                        : null;

                                    return GestureDetector(
                                      onTap: () {
                                        final storyMediaUrls = userStory.stories
                                            .map((s) => s.mediaUrl)
                                            .toList();
                                        final storyIds = userStory.stories
                                            .map((s) => s.id)
                                            .toList();
                                        final viewCounts = userStory.stories
                                            .map((s) => s.viewCount)
                                            .toList();

                                        Get.to(() => StoryPreviewPage(
                                              mediaUrls: storyMediaUrls,
                                              userName: userStory.userName,
                                              storyIds: storyIds,
                                              viewCounts: viewCounts,
                                            ));
                                        // TODO: Show story using `story_view` package
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              height: 60,
                                              child: CircleAvatar(
                                                radius: 30,
                                                backgroundColor:
                                                    Colors.grey.shade300,
                                                backgroundImage: latestStory !=
                                                        null
                                                    ? NetworkImage(
                                                        latestStory.mediaUrl)
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            AppText(
                                              text: userStory.userName,
                                              fontSize: 12,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          Obx(() => podCastController.isPodcastLoading.value
                              ? ListView.builder(
                                  physics: const ScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: 10,
                                  itemBuilder: (_, __) =>
                                      const CatQuoteCardShimmer(),
                                )
                              : podCastController.podcasts.isEmpty
                                  ? CustomLottieAnimation(
                                      jsonPath: AppImages.emptyPodcast,
                                    )
                                  : ListView.builder(
                                      physics: const ScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount:
                                          podCastController.podcasts.length,
                                      itemBuilder: (context, index) {
                                        final podcast =
                                            podCastController.podcasts[index];

                                        return CatQuoteCard(
                                          podcast: podcast,
                                          onUserProfileTap: () {
                                            Get.offNamed(AppRoutes.profile,
                                                arguments: podcast.host.id);
                                          },
                                          onTap: () {
                                            final canJoin =
                                                CommonService.canJoinPodcast(
                                                    hostId: podcast.host.id,
                                                    status: podcast.status,
                                                    scheduledAt:
                                                        podcast.scheduledAt);
                                            if (canJoin) {
                                              podCastCallController.podCastId =
                                                  podcast.id;
                                              log("Pod cast id is ${podCastCallController.podCastId}");
                                              Get.toNamed(AppRoutes.podCastView,
                                                  arguments: podcast);
                                            }
                                          },
                                        );
                                      }))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () {
                final petService = PetOwnershipService.instance;
                if (petService.canCreatePodcasts) {
                  Get.toNamed(AppRoutes.inviteUserToPodCast);
                } else {
                //  petService.showPodcastRestriction();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0095F6), Color(0xFF0066CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Schedule Podcast',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // CustomFloatingActionButton(controller: Get.find<MapController>()),
          // UserMapButtons(
          //     bottom: AppSize.getHeight(10),
          //     right: AppSize.getHeight(14),
          //     controller: Get.find<MapController>()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(controller: mapController),
    );
  }
}

class CatQuoteCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  final VoidCallback? onUserProfileTap;

  const CatQuoteCard(
      {super.key, required this.podcast, this.onTap, this.onUserProfileTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: Get.height * 0.69,
        child: Stack(
          children: [
            ClipRRect(
              child: Image.network(
                podcast.bannerImage != null && podcast.bannerImage!.isNotEmpty
                    ? podcast.bannerImage!
                    : "https://fastly.picsum.photos/id/1/200/300.jpg?hmac=jH5bDkLr6Tgy3oAg5khKCHeunZMHq0ehBZr6vGifPLY",
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            // Gradient overlay

            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: podcast.status.toLowerCase() == 'live'
                      ? Colors.green
                      : podcast.status.toLowerCase() == "ended"
                          ? Colors.red
                          : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  podcast.status.toLowerCase() == 'live'
                      ? "LIVE"
                      : podcast.status.toLowerCase() == 'ended'
                          ? "ENDED"
                          : CommonService.formatRemainingTime(
                              podcast.scheduledAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${podcast.guests.length} watching",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Description
            Positioned(
              left: 20,
              right: 80,
              bottom: 80,
              child: Text(
                podcast.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // User Info
            Positioned(
              left: 20,
              bottom: 20,
              child: InkWell(
                onTap: onUserProfileTap,
                child: Row(
                  children: [
                    _buildHostAvatar(podcast.host),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          podcast.host.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          podcast.host.bio,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
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
    );
  }

  Widget _buildHostAvatar(dynamic host) {
    final profilePic = host.profilePic;
    final userName = host.name ?? 'Host';
    
    if (profilePic != null && profilePic.toString().isNotEmpty && profilePic != 'null') {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(profilePic),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback handled by child
        },
        child: _buildInitialsAvatar(userName, 18),
      );
    } else {
      return _buildInitialsAvatar(userName, 18);
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
