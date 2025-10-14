import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_text.dart';
import '../../../core/utils/app_size.dart';
import '../../../data/models/story.dart';
import '../../../data/models/pet_profile.dart';
import '../../../modules/profile/controllers/profile_controller.dart';
import '../../../services/custom_Api.dart';
import '../../../services/pet_ownership_service.dart';
import '../../../widget/shimmer/story_shimmer.dart';
import '../home_controller.dart';
import '../home_view.dart';
import '../story_view.dart';

class StorySection extends StatefulWidget {
  const StorySection({super.key});

  @override
  State<StorySection> createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  late Future<List<Map<String, dynamic>>> _storiesFuture;
  late final CustomApiService _apiService;
  late final HomeController contrroller;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers in initState to avoid build-phase conflicts
    _apiService = Get.put(CustomApiService());
    if (Get.isRegistered<HomeController>(tag: 'home')) {
      contrroller = Get.find<HomeController>(tag: 'home');
    } else {
      contrroller = Get.put(HomeController(), tag: 'home');
    }
    
    _loadStories();
  }

  void _loadStories() {
    _storiesFuture = Future.wait([
      _apiService
          .getRequest('story')
          .then((res) => res as Map<String, dynamic>),
      _apiService
          .getRequest('story/public')
          .then((res) => res as Map<String, dynamic>),
    ]);
  }

  void _refreshAfterPosting(Future Function() action) async {
    await action(); // Wait for story upload or editor to complete
    setState(() {
      _loadStories(); // Re-fetch the stories
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const StoryShimmerList();
            }

            if (snapshot.hasError) {
              log("Error is ${snapshot.error}");

              return const Center(child: Text('Error loading stories'));
            }

            if (!snapshot.hasData ||
                snapshot.data!.isEmpty ||
                snapshot.data![1]['success'] != true) {
              return const SizedBox.shrink();
            }

            final currentUserStoriesData = snapshot.data![0]['stories'] ?? [];
            final publicStoriesData = snapshot.data![1]['data'] ?? [];

            final List<StoryModel> currentUserStories = currentUserStoriesData
                .map<StoryModel>((e) => StoryModel.fromMap(e))
                .toList();

            final List<UserStory> userStories = publicStoriesData
.map<UserStory>((e) => UserStory.fromMap(e))
                .toList();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: userStories.length + 1, // +1 for your story
              itemBuilder: (context, index) {
                if (index == 0) {
                  final hasStories = currentUserStories.isNotEmpty;
                  final firstStory =
                      hasStories ? currentUserStories.first : null;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            // Instagram-like story ring
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: hasStories
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF833AB4),
                                          Color(0xFFE1306C),
                                          Color(0xFFFD1D1D),
                                          Color(0xFFF77737),
                                          Color(0xFFFCAF45),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.grey.shade300,
                                          Colors.grey.shade300,
                                        ],
                                      ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (hasStories) {
                                        final urls = currentUserStories
                                            .map((e) => e.mediaUrl)
                                            .toList();
                                        final storyIds = currentUserStories
                                            .map((e) => e.id)
                                            .toList();
                                        final viewCounts = currentUserStories
                                            .map((e) => e.viewCount)
                                            .toList();
                                        Get.to(() => StoryPreviewPage(
                                              mediaUrls: urls,
                                              userName: firstStory?.userName ?? 'You',
                                              storyIds: storyIds,
                                              viewCounts: viewCounts,
                                            ));
                                      }
                                      // Don't handle tap here - let the + button handle story creation
                                    },
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: hasStories
                                          ? NetworkImage(firstStory!.mediaUrl)
                                          : _getPetProfileImage(),
                                      child: !hasStories
                                          ? _buildPetProfileFallback()
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Add story icon - always show on corner
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  _showStoryCreationOptions();
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your Story",
                        style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF262626),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ));
                }

                final userStory = userStories[index - 1];
                final latestStory = userStory.stories.firstOrNull;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          // Instagram-like story ring for other users
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF833AB4),
                                  Color(0xFFE1306C),
                                  Color(0xFFFD1D1D),
                                  Color(0xFFF77737),
                                  Color(0xFFFCAF45),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    final storyMediaUrls =
                                        userStory.stories.map((s) => s.mediaUrl).toList();
                                    final storyIds =
                                        userStory.stories.map((s) => s.id).toList();
                                    final viewCounts =
                                        userStory.stories.map((s) => s.viewCount).toList();
                                    Get.to(() => StoryPreviewPage(
                                          mediaUrls: storyMediaUrls,
                                          userName: userStory.userName,
                                          storyIds: storyIds,
                                          viewCounts: viewCounts,
                                        ));
                                  },
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: latestStory != null
                                        ? NetworkImage(latestStory.mediaUrl)
                                        : null,
                                    child: latestStory == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.grey,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 66,
                        child: Text(
                          userStory.userName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF262626),
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

    );
  }

  ImageProvider? _getPetProfileImage() {
    final profileController = Get.find<ProfileController>();
    final userPet = profileController.userPet.value;
    if (userPet?.profilePic != null && userPet!.profilePic!.isNotEmpty) {
      return NetworkImage(userPet.profilePic!);
    }
    return null;
  }

  Widget _buildPetProfileFallback() {
    final profileController = Get.find<ProfileController>();
    final userPet = profileController.userPet.value;
    if (userPet?.profilePic == null || userPet!.profilePic!.isEmpty) {
      // Show pet initials or pet icon instead of person icon
      if (userPet?.name != null && userPet!.name!.isNotEmpty) {
        return Text(
          _getPetInitials(userPet.name!),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return const Icon(Icons.pets, color: Colors.white);
      }
    }
    return const SizedBox.shrink();
  }

  String _getPetInitials(String petName) {
    if (petName.isEmpty) return "P";
    final words = petName.split(' ');
    if (words.length >= 2) {
      return "${words[0][0]}${words[1][0]}".toUpperCase();
    }
    return petName[0].toUpperCase();
  }

  void _showStoryCreationOptions() {
    final petService = PetOwnershipService.instance;
    if (!petService.hasPet) {
      petService.showStoriesRestriction();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Create Story',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Camera option
                  _buildStoryOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    subtitle: 'Take a photo or video',
                    onTap: () {
                      Navigator.pop(context);
                      _refreshAfterPosting(() => contrroller.pickMedia(source: ImageSource.camera));
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Gallery option
                  _buildStoryOption(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    subtitle: 'Choose from your photos',
                    onTap: () {
                      Navigator.pop(context);
                      _refreshAfterPosting(() => contrroller.pickMedia(source: ImageSource.gallery));
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
