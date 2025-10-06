import 'dart:developer';

import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/data/models/story.dart';
import 'package:chys/app/modules/%20home/story_view.dart';
import 'package:chys/app/modules/%20home/widget/custom_header.dart';
import 'package:chys/app/modules/%20home/widget/floating_action_button.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/widget/common/custom_post_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_routes.dart';
import '../../widget/shimmer/cat_quote_shimmer.dart';
import '../../widget/shimmer/story_shimmer.dart';
import '../map/controllers/map_controller.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  final contrroller = Get.put(AddoredPostsController());
  final storyController = Get.put(HomeController());
  final CustomApiService _apiService = Get.put(CustomApiService());

  @override
  Widget build(BuildContext context) {
    log("Come here");
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
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: Future.wait([
                              _apiService.getRequest('story').then((res) => res
                                  as Map<String,
                                      dynamic>), // Current user stories
                              _apiService.getRequest('story/public').then(
                                  (res) => res as Map<String,
                                      dynamic>), // Other users' stories
                            ]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const StoryShimmerList();
                              }

                              if (snapshot.hasError) {
                                return const Center(
                                    child: Text('Error loading stories'));
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty ||
                                  snapshot.data![1]['success'] != true) {
                                return const SizedBox.shrink();
                              }

                              final currentUserStoriesData =
                                  snapshot.data![0]['stories'] ?? [];
                              final publicStoriesData =
                                  snapshot.data![1]['data'] ?? [];

                              final List<StoryModel> currentUserStories =
                                  currentUserStoriesData
                                      .map<StoryModel>(
                                          (e) => StoryModel.fromMap(e))
                                      .toList();

                              final List<UserStory> userStories =
                                  publicStoriesData
                                      .map<UserStory>(
                                          (e) => UserStory.fromMap(e))
                                      .toList();

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: userStories.length +
                                    1, // +1 for current user
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final hasStories =
                                        currentUserStories.isNotEmpty;
                                    final firstStory = hasStories
                                        ? currentUserStories.first
                                        : null;

                                    return Column(
                                      children: [
                                        Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                if (hasStories) {
                                                  final urls =
                                                      currentUserStories
                                                          .map(
                                                              (e) => e.mediaUrl)
                                                          .toList();
                                                  Get.to(() => StoryPreviewPage(
                                                        mediaUrls: urls,
                                                        userName: firstStory
                                                                ?.userName ??
                                                            'You',
                                                      ));
                                                }
                                              },
                                              child: SizedBox(
                                                width: 60,
                                                height: 60,
                                                child: CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor:
                                                      Colors.grey.shade300,
                                                  backgroundImage: hasStories
                                                      ? NetworkImage(
                                                          firstStory!.mediaUrl)
                                                      : null,
                                                  child: !hasStories
                                                      ? const Icon(Icons.person,
                                                          color: Colors.white)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: GestureDetector(
                                                onTap: () {
                                                  controller.pickMedia(source: ImageSource.gallery);
                                                },
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 2),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const AppText(
                                          text: "Your Story",
                                          fontSize: 12,
                                        ),
                                      ],
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

                                      Get.to(() => StoryPreviewPage(
                                            mediaUrls: storyMediaUrls,
                                            userName: userStory.userName,
                                          ));
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
                                              backgroundImage:
                                                  latestStory != null
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
                        Obx(() => contrroller.isLoading.value
                            ? ListView.builder(
                                physics: const ScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: 10,
                                itemBuilder: (_, __) =>
                                    const CatQuoteCardShimmer(),
                              )
                            : ListView.builder(
                                physics: const ScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: contrroller.posts.length,
                                itemBuilder: (context, index) {
                                  return CustomPostWidget(
                                      posts: contrroller.posts[index],
                                      addoredPostsController: contrroller,
                                      onTapPaw: () {
                                        log("Fund raise");
                                        Get.toNamed(AppRoutes.fundRaise,
                                            arguments:
                                                contrroller.posts[index]);
                                      },
                                      onTapLove: () {
                                        log("Like tap");
                                        contrroller.likePost(
                                            contrroller.posts[index].id);
                                      },
                                      onTapShare: () {
                                        contrroller.sharePost(
                                            contrroller.posts[index]);
                                      },
                                      onTapMessage: () {
                                        final controller =
                                            Get.find<AddoredPostsController>();
                                        controller.showCommentsBottomSheet(
                                            controller.posts[index]);
                                      });
                                }))
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // See All Posts
          // Positioned(
          //   bottom: 20,
          //   left: 20,
          //   child: GestureDetector(
          //     onTap: () {
          //       Get.toNamed(AppRoutes.startPodCost);
          //       // Get.to(const PetGalleryScreen());
          //     },
          //     child: Container(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          //       decoration: BoxDecoration(
          //         gradient: const LinearGradient(
          //           colors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
          //           begin: Alignment.topLeft,
          //           end: Alignment.bottomRight,
          //         ),
          //         borderRadius: BorderRadius.circular(30),
          //         boxShadow: const [
          //           BoxShadow(
          //             color: Colors.black26,
          //             blurRadius: 6,
          //             offset: Offset(0, 3),
          //           ),
          //         ],
          //       ),
          //       child: const Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: [
          //           Icon(Icons.explore, color: Colors.white, size: 20),
          //           SizedBox(width: 6),
          //           Text(
          //             'Start Podcast',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontWeight: FontWeight.bold,
          //               letterSpacing: 0.5,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),

          CustomFloatingActionButton(controller: Get.find<MapController>()),
          UserMapButtons(
              bottom: AppSize.getHeight(10),
              right: AppSize.getHeight(14),
              controller: Get.find<MapController>()),
        ],
      ),
    );
  }
}

class StoryModel {
  final String id;
  final String mediaUrl;
  final String caption;
  final String userName;

  StoryModel({
    required this.id,
    required this.mediaUrl,
    required this.caption,
    required this.userName,
  });

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: map['_id'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      caption: map['caption'] ?? '',
      userName: map['userId']?['name'] ?? '',
    );
  }
}
