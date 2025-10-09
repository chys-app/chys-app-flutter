import 'dart:developer';
import 'dart:convert';

import 'package:chys/app/data/models/own_profile.dart';
import 'package:chys/app/data/models/pet_profile.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/storage_service.dart';
import 'package:get/get.dart';

import '../../adored_posts/controller/controller.dart';
import '../controllers/profile_controller.dart';

class OtherUserProfileController extends GetxController {
  final CustomApiService customApiService = CustomApiService();

  // Loading state
  final isLoading = false.obs;

  // Profile data
  var profile = Rxn<OwnProfileModel>();
  var userPet = Rxn<PetModel>();

  // Current user ID for comparison
  RxString userCurrentId = "".obs;

  // Follow/Unfollow state management
  RxBool isFollowing = false.obs;
  RxInt followersCount = 0.obs;
  RxInt followingCount = 0.obs;

  // Selected tab for posts/pets
  RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final userData = StorageService.getUser();
      log("Raw user data from storage: $userData");

      if (userData != null) {
        // Try different possible field names for user ID
        String? userId;
        if (userData['_id'] != null) {
          userId = userData['_id'].toString();
        } else if (userData['id'] != null) {
          userId = userData['id'].toString();
        } else if (userData['userId'] != null) {
          userId = userData['userId'].toString();
        }

        if (userId != null && userId.isNotEmpty) {
          userCurrentId.value = userId;
          log("Current user ID loaded successfully: ${userCurrentId.value}");
          return;
        } else {
          log("No valid user ID found in user data");
        }
      } else {
        log("No user data found in storage");
      }

      // Fallback: Try to get user ID from profile controller if available
      try {
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          final profileData = profileController.profile.value;
          if (profileData?.id != null) {
            userCurrentId.value = profileData!.id!;
            log("Current user ID loaded from profile controller: ${userCurrentId.value}");
            return;
          }
        }
      } catch (e) {
        log("Error getting user ID from profile controller: $e");
      }

      // Final fallback: Try to decode from JWT token
      try {
        final token = StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          // Simple JWT decode (this is a basic implementation)
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final resp = utf8.decode(base64Url.decode(normalized));
            final payloadMap = json.decode(resp);

            if (payloadMap['_id'] != null) {
              userCurrentId.value = payloadMap['_id'].toString();
              log("Current user ID loaded from JWT token: ${userCurrentId.value}");
              return;
            }
          }
        }
      } catch (e) {
        log("Error decoding JWT token: $e");
      }

      log("Could not load current user ID from any source");
    } catch (e) {
      log("Error loading current user ID: $e");
    }
  }

  // /// Public method to reload current user ID
  // Future<void> reloadCurrentUserId() async {
  //   await _loadCurrentUserId();
  // }

  Future<void> fetchOtherUserProfile(String userId) async {
    try {
      log("Loading other user profile for ID: $userId");

      // Load current user ID in parallel if needed
      if (userCurrentId.value.isEmpty) {
        _loadCurrentUserId(); // Don't await, let it run in background
      }

      // Clear any existing data
      clearProfileData();
      isLoading.value = true;

      final endpoint = "users/profile/$userId";
      log("Fetching profile from: $endpoint");

      var response = await customApiService.getRequest(endpoint);

      // Handle the response structure
      Map<String, dynamic> userData;
      if (response["user"] != null) {
        userData = response["user"];
      } else {
        // If no nested user object, use the response directly
        userData = response;
      }

      profile.value = OwnProfileModel.fromMap(userData);

      // Update follow state and counts
      if (profile.value != null) {
        isFollowing.value = profile.value!.isFollowing;
        followersCount.value = profile.value!.followers.length;
        followingCount.value = profile.value!.following.length;

        log("Other user profile loaded - Followers: ${followersCount.value}, Following: ${followingCount.value}, IsFollowing: ${isFollowing.value}");
      }

      // Load pet profiles
      final petProfiles = response["petProfiles"];
      if (petProfiles is List && petProfiles.isNotEmpty) {
        userPet.value = PetModel.fromJson(petProfiles[0]);
        log("Pet profile loaded for other user");
      } else {
        log("No pet profile found for other user.");
        userPet.value = null;
      }

      log("Other user profile data loaded successfully");
    } catch (e) {
      log("Error loading other user profile: $e");
      profile.value = null;
      userPet.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void clearProfileData() {
    profile.value = null;
    userPet.value = null;
    isFollowing.value = false;
    followersCount.value = 0;
    followingCount.value = 0;
    selectedTab.value = 0;
    log("Other user profile data cleared");
  }

  bool get isCurrentUser {
    final profileId = profile.value?.id;
    final currentId = userCurrentId.value;

    log("Checking if current user - Profile ID: $profileId, Current ID: $currentId");

    // Compare both IDs, handling null cases
    if (profileId == null || currentId.isEmpty) {
      return false;
    }

    final isCurrent = profileId == currentId;
    log("Is current user: $isCurrent");
    return isCurrent;
  }

  Future<void> followUnfollow(String userId) async {
    if (userId.isEmpty) {
      log("Invalid user ID for follow/unfollow");
      return;
    }

    // Prevent follow/unfollow on current user's own profile
    if (isCurrentUser) {
      log("Cannot follow/unfollow own profile");
      return;
    }

    try {
      // Store current state for rollback if needed
      final wasFollowing = isFollowing.value;

      // Optimistically update UI
      isFollowing.value = !isFollowing.value;
      if (wasFollowing) {
        followersCount.value =
            (followersCount.value - 1).clamp(0, double.infinity).toInt();
      } else {
        followersCount.value = followersCount.value + 1;
      }

      // Use the single toggle endpoint
      final endpoint = "users/follow-toggle/$userId";
      log("Calling follow-toggle endpoint: $endpoint");
      final response = await customApiService.postRequest(endpoint, {});

      log("Follow-toggle response: $response");

      // Refresh profile data to get updated counts
      await fetchOtherUserProfile(userId);
    } catch (e) {
      log("Error in follow/unfollow: $e");
      // Revert optimistic update on error
      isFollowing.value = !isFollowing.value;
      if (isFollowing.value) {
        followersCount.value = followersCount.value + 1;
      } else {
        followersCount.value =
            (followersCount.value - 1).clamp(0, double.infinity).toInt();
      }
    }
  }

  void setSelectedTab(int index) {
    selectedTab.value = index;
  }

  /// Reload current user ID from storage
  Future<void> reloadCurrentUserId() async {
    await _loadCurrentUserId();
  }

  /// Get current user ID as string
  String get currentUserId => userCurrentId.value;
}
