import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/data/models/own_profile.dart';
import 'package:chys/app/data/models/pet_profile.dart';
import 'package:chys/app/services/custom_Api.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/short_message_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_places_autocomplete_widgets/model/place.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/controllers/location_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/storage_service.dart';
import '../../adored_posts/controller/controller.dart';

class ProfileController extends GetxController {
  final CustomApiService customApiService = CustomApiService();
  
  // Loading state
  final isLoading = false.obs;
  
  // Profile data
  var profile = Rxn<OwnProfileModel>();
  final RxList<PetModel> userPets = <PetModel>[].obs;
  var userPet = Rxn<PetModel>();
  
  // Current user ID for comparison
  RxString userCurrentId = "".obs;
  
  // Follow/Unfollow state management
  RxBool isFollowing = false.obs;
  RxInt followersCount = 0.obs;
  RxInt followingCount = 0.obs;
  
  // Selected tab for posts/pets
  RxInt selectedTab = 0.obs;
  
  // Legacy fields for backward compatibility
  final profilePhoto = Rxn<File>();
  final userName = 'John Doe'.obs;
  final userLocation = 'New York, USA'.obs;
  final petCount = 2.obs;
  final pets = <Map<String, dynamic>>[].obs;
  RxBool isCurrentUser = true.obs;
  
  // Form controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController taxIdController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController zipController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  RxString imagePath = "".obs;
  
  // Bank details controllers
  final accountHolderName = TextEditingController();
  final routingNumber = TextEditingController();
  final accountNumber = TextEditingController();
  final bankName = TextEditingController();
  final bankAddress = TextEditingController();
  final balance = TextEditingController();
  final accountType = ''.obs;
  final formKey = GlobalKey<FormState>();

  void onSuggestionClick(Place placeDetails) {
    streetController.text = placeDetails.streetAddress ?? '';
    cityController.text = placeDetails.city ?? '';
    stateController.text = placeDetails.state ?? '';
    zipController.text = placeDetails.zipCode ?? '';
    countryController.text = placeDetails.country ?? '';
  }

  Future<void> updateBankDetails() async {
    try {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }
      final response = await ApiClient().put(ApiEndPoints.bankDetails, {
        "accountHolderName": accountHolderName.text,
        "routingNumber": routingNumber.text,
        "accountNumber": accountNumber.text,
        "bankName": bankName.text,
        "accountType": accountType.value,
        "bankAddress": bankAddress.text
      });
      log("Response of the $response");
      Get.back();
      fetchProfilee();
    } catch (e) {}
  }

  Future<void> followUnfollow(String userId) async {
    if (userId.isEmpty) {
      log("Invalid user ID for follow/unfollow");
      return;
    }

    try {
      // Store current state for rollback if needed
      final currentProfile = profile.value;
      final wasFollowing = isFollowing.value;

      // Optimistically update UI
      isFollowing.value = !isFollowing.value;

      // Update profile state optimistically
      if (currentProfile != null) {
        if (isFollowing.value) {
          // Following - add target user to following list and current user to followers list
          final updatedFollowing = List<String>.from(currentProfile.following);
          final updatedFollowers = List<String>.from(currentProfile.followers);
          
          if (!updatedFollowing.contains(userId)) {
            updatedFollowing.add(userId);
          }
          if (!updatedFollowers.contains(userCurrentId.value)) {
            updatedFollowers.add(userCurrentId.value);
          }
          
          profile.value = currentProfile.copyWith(
            following: updatedFollowing,
            followers: updatedFollowers,
            isFollowing: true,
          );
          followersCount.value = updatedFollowers.length;
          followingCount.value = updatedFollowing.length;
        } else {
          // Unfollowing - remove target user from following list and current user from followers list
          final updatedFollowing = List<String>.from(currentProfile.following);
          final updatedFollowers = List<String>.from(currentProfile.followers);
          
          updatedFollowing.remove(userId);
          updatedFollowers.remove(userCurrentId.value);
          
          profile.value = currentProfile.copyWith(
            following: updatedFollowing,
            followers: updatedFollowers,
            isFollowing: false,
          );
          followersCount.value = updatedFollowers.length;
          followingCount.value = updatedFollowing.length;
        }
      }

      // Call API
      final response =
          await ApiClient().post("${ApiEndPoints.followUnfollow}/$userId", {});
      log("Follow/Unfollow response: $response");

      // Update with real data from API response
      if (response != null) {
        final apiIsFollowing = response['isFollowing'] as bool?;
        if (apiIsFollowing != null) {
          isFollowing.value = apiIsFollowing;

          // Update profile with real data if available
          if (currentProfile != null) {
            profile.value = currentProfile.copyWith(
              isFollowing: apiIsFollowing,
            );
          }
        }
      }

      // Show success message
      final message = response?['message'] ??
          (isFollowing.value
              ? 'Followed successfully'
              : 'Unfollowed successfully');
      ShortMessageUtils.showSuccess(message);
    } catch (e) {
      log("Follow/Unfollow error: $e");

      // Rollback optimistic updates on error
      isFollowing.value = !isFollowing.value;
      if (profile.value != null) {
        profile.value = profile.value!.copyWith(
          isFollowing: !isFollowing.value,
        );
      }
      ShortMessageUtils.showError(
          "Failed to ${isFollowing.value ? 'follow' : 'unfollow'}");
    }
  }

  void checkIsCurrentUser(String userId) {
    final currentId = userCurrentId.value;
    if (currentId.isNotEmpty) {
      isCurrentUser.value = currentId == userId;
      log("IsCurrent user ${isCurrentUser.value} - Current ID: $currentId, Profile ID: $userId");
    } else {
      // If we don't have current user ID yet, assume it's not current user
      // This happens when viewing other user profiles before loading current user
      isCurrentUser.value = false;
      log("No current user ID available, assuming not current user");
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserId();
    _loadUserData();
    fetchProfilee();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data when page becomes ready/active
    refreshProfileData();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // Method to handle when returning to profile page
  void onReturnToProfile() {
    log("Returning to profile page, refreshing data...");
    refreshProfileData();
  }

  // Method to refresh profile data when returning from other pages
  Future<void> refreshProfileData() async {
    try {
      // Show loading state immediately for better UX
      isLoading.value = true;
      
      await fetchProfilee();
      
      // Don't refresh posts here to avoid conflicts with home page
      // Posts will be handled by the profile view itself
    } catch (e) {
      log("Error refreshing profile data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Public method to reload current user ID
  Future<void> reloadCurrentUserId() async {
    await _loadCurrentUserId();
  }

  // Method to handle when user returns to profile page
  void onProfilePageResume() {
    log("Profile page resumed, refreshing data...");
    refreshProfileData();
  }

  Future<void> withdrawAmount() async {
    // Validate amount field
    if (amountController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter a withdrawal amount',
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(
          Icons.warning_amber,
          color: Colors.white,
          size: 24,
        ),
      );
      return;
    }

    // Validate amount is numeric
    if (double.tryParse(amountController.text.trim()) == null) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid numeric amount',
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(
          Icons.warning_amber,
          color: Colors.white,
          size: 24,
        ),
      );
      return;
    }

    try {
      final response = await ApiClient()
          .post(ApiEndPoints.withdraw, {"amount": amountController.text.trim()});
      log("Response for withdraw amount is $response");
      
      // Clear the amount field on success
      amountController.clear();
      
      // Show success message
      Get.snackbar(
        'Success',
        'Withdrawal request submitted successfully',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      
    } catch (e) {
      log("Error during withdrawal: $e");
      
      // Show specific error message from API
      String errorMessage = 'Failed to submit withdrawal request. Please try again.';
      if (e.toString().contains('You already have a pending request')) {
        errorMessage = 'You already have a pending withdrawal request. Please wait for it to be processed.';
      } else if (e.toString().contains('Insufficient balance')) {
        errorMessage = 'Insufficient balance for this withdrawal amount.';
      } else if (e.toString().contains('Invalid amount')) {
        errorMessage = 'Please enter a valid withdrawal amount.';
      }
      
      Get.snackbar(
        'Withdrawal Error',
        errorMessage,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon:  Icon(
          Icons.error_outline,
          color: Colors.white,
          size: 24,
        ),
      );
    }
  }

  // Method to refresh follow state for a specific user
  Future<void> refreshFollowState(String userId) async {
    try {
      final response =
          await customApiService.getRequest("users/profile/$userId");
      if (response != null && response['user'] != null) {
        final userData = response['user'];
        final isFollowingUser = userData['isFollowing'] == true;

        // Update the follow state
        isFollowing.value = isFollowingUser;

        // Update profile if it exists
        if (profile.value != null) {
          profile.value = profile.value!.copyWith(
            isFollowing: isFollowingUser,
          );
        }
      }
    } catch (e) {
      log("Error refreshing follow state: $e");
    }
  }

  Future<void> fetchProfilee(
      {String? userId, bool isFromUserProfile = false}) async {
    try {
      log("Loading profile data $userId $isFromUserProfile");
      
      // Clear profile data when fetching a different user's profile
      if (userId != null && profile.value != null && profile.value!.id != userId) {
        profile.value = null;
        userPets.clear();
        userPet.value = null;
        log("Cleared existing profile data for different user");
      }
      
      final LocationController locationController =
          Get.find<LocationController>();

      isLoading.value = true;

      final endpoint = (userId == null || userId.trim().isEmpty)
          ? "users/profile"
          : "users/profile/$userId";
      if (userId != null) {
        log("Come here");
        checkIsCurrentUser(userId);
      }
      log("Fetch profile $endpoint");
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

        log("Profile loaded - Followers: ${followersCount.value}, Following: ${followingCount.value}, IsFollowing: ${isFollowing.value}");
      }

      // Set current user ID only if we're fetching current user's profile and don't have it yet
      if (userCurrentId.isEmpty && userId == null) {
        userCurrentId.value = profile.value!.id;
        log("Set current user ID from profile: ${userCurrentId.value}");
      }
      // Load posts in background if needed
      if (isFromUserProfile) {
        final postController = Get.put(AddoredPostsController());
        final targetUserId = userId ?? profile.value!.id;
        if (targetUserId != null) {
          postController.fetchAdoredPosts(userId: targetUserId);
          checkIsCurrentUser(targetUserId);
        }
      }
      final petProfiles = response["petProfiles"];
      if (petProfiles is List && petProfiles.isNotEmpty) {
        final pets = petProfiles
            .whereType<Map<String, dynamic>>()
            .map(PetModel.fromJson)
            .toList();
        userPets
          ..clear()
          ..addAll(pets);
        userPet.value = pets.first;
        selectedTab.value = 0;
      } else {
        log("No pet profile found.");
        userPets.clear();
        userPet.value = null;
        selectedTab.value = 0;
      }
      log("Profile is $response");
      nameController.text = profile.value!.name;
      bioController.text = profile.value!.bio ?? '';
      imagePath.value = profile.value!.profilePic ?? '';

      final bankDetail = profile.value!.bankDetails;
      log("Bank details $bankDetail");
      if (bankDetail != null) {
        accountNumber.text = bankDetail.accountNumber;
        accountHolderName.text = bankDetail.accountHolderName;
        bankAddress.text = bankDetail.bankAddress ?? '';
        bankName.text = bankDetail.bankName;
        routingNumber.text = bankDetail.routingNumber;
        accountType.value = bankDetail.accountType.isNotEmpty ? bankDetail.accountType : '';
      }

      // Update form controllers with profile data
      _updateFormControllers();
      
      // Update address fields from API if present, otherwise fallback to location
      await _updateAddressFields(locationController);
    } catch (e) {
      log("Error:-==? $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        profilePhoto.value = File(pickedFile.path);
        imagePath.value = pickedFile.path;
        log("Picked image: ${pickedFile.path}");
      } else {
        log("No image selected.");
      }
    } catch (e) {
      log("Image picker error: $e");
      Get.snackbar("Error", "Failed to pick image");
    }
  }

  Future<void> updateProfile(bool isComplete, {bool isBusinessProfile = false}) async {
    final loading = Get.find<LoadingController>();

    try {
      loading.show();
      final data = <String, dynamic>{
        "name": nameController.text.trim(),
        "bio": bioController.text.trim(),
        "website": websiteController.text.trim(),
        "taxId": taxIdController.text.trim(),
        "address": streetController.text.trim(),
        "zipCode": zipController.text.trim(),
        "city": cityController.text.trim(),
        "state": stateController.text.trim(),
        "country": countryController.text.trim(),
      };
      
      // Set role to business user if this is a business profile
      if (isBusinessProfile) {
        data["role"] = "biz-user";
      }
      
      log("Data is $data and profile pic is ${profilePhoto.value}");
      // Add image if selected
      if (profilePhoto.value != null) {
        data["profilePic"] = profilePhoto.value!;
      }

      final response =
          await ApiClient().postFormData(ApiEndPoints.editProfile, data);
      log("Update Profile Response: $response");
      fetchProfilee();
      if (isComplete) {
        await StorageService.setStepDone(StorageService.editProfileDone);
        loading.hide();

        // Navigate based on profile type
        if (isBusinessProfile) {
          // Business users go to city view after profile completion
          await Get.offAllNamed(AppRoutes.cityView);
        } else {
          // Regular users go to pet ownership
          await Get.offAllNamed(AppRoutes.petOwnership);
        }
      } else {
        loading.hide();

        Get.back();
      }
    } catch (e) {
      loading.hide();
      log("Update Profile Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteUserAccount(String password) async {
    try {
      Get.find<LoadingController>().show();

      final response = await ApiClient().delete(
        ApiEndPoints.deleteAccount,
        {'password': password},
      );
      log("Response during delete account is $response");
      
      // Clear profile data immediately after successful deletion
      clearProfileData();
      
      // Show success message
      Get.snackbar(
        'Success',
        'Account deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      log("The error is ${e}");
      
      // Show error message
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      
      // Re-throw the error so the calling code can handle it
      rethrow;
    } finally {
      Get.find<LoadingController>().hide();
    }
  }

  void clearProfileData() {
    profile.value = null;
    userPets.clear();
    userPet.value = null;
    isFollowing.value = false;
    followersCount.value = 0;
    followingCount.value = 0;
    selectedTab.value = 0;
    log("Profile data cleared");
  }

  void selectPet(int index) {
    if (index < 0 || index >= userPets.length) {
      log("Invalid pet index selected: $index");
      return;
    }
    userPet.value = userPets[index];
    selectedTab.value = index;
  }
  bool get isCurrentUserProfile {
    final profileId = profile.value?.id;
    final currentId = userCurrentId.value;

    log("Checking if current user profile - Profile ID: $profileId, Current ID: $currentId");

    // Compare both IDs, handling null cases
    if (profileId == null || currentId.isEmpty) {
      return false;
    }

    final isCurrent = profileId == currentId;
    log("Is current user profile: $isCurrent");
    return isCurrent;
  }

  /// Update form controllers with profile data
  void _updateFormControllers() {
    if (profile.value != null) {
      nameController.text = profile.value!.name;
      bioController.text = profile.value!.bio ?? '';
      websiteController.text = profile.value!.website ?? '';
      taxIdController.text = profile.value!.taxId ?? '';
      imagePath.value = profile.value!.profilePic ?? '';

      final bankDetail = profile.value!.bankDetails;
      log("Bank details $bankDetail");
      if (bankDetail != null) {
        accountNumber.text = bankDetail.accountNumber;
        accountHolderName.text = bankDetail.accountHolderName;
        bankAddress.text = bankDetail.bankAddress ?? '';
        bankName.text = bankDetail.bankName;
        routingNumber.text = bankDetail.routingNumber;
        accountType.value = bankDetail.accountType.isNotEmpty ? bankDetail.accountType : '';
      }
    }
  }

  /// Update address fields from API if present, otherwise fallback to location
  Future<void> _updateAddressFields(LocationController locationController) async {
    if (profile.value != null) {
      // Set address fields from API if present
      if (profile.value!.address != null && profile.value!.address!.isNotEmpty) {
        streetController.text = profile.value!.address!;
      }
      if (profile.value!.city != null && profile.value!.city!.isNotEmpty) {
        cityController.text = profile.value!.city!;
      }
      if (profile.value!.state != null && profile.value!.state!.isNotEmpty) {
        stateController.text = profile.value!.state!;
      }
      if (profile.value!.zipCode != null && profile.value!.zipCode!.isNotEmpty) {
        zipController.text = profile.value!.zipCode!;
      }
      if (profile.value!.country != null && profile.value!.country!.isNotEmpty) {
        countryController.text = profile.value!.country!;
      }
    } else {
      // Fallback to location data if available
      try {
        final locationData = locationController.locationData.value;
        if (locationData != null) {
          // Use the street address from location data
          if (locationData.street != null && locationData.street!.isNotEmpty) {
            streetController.text = locationData.street!;
          }
          if (locationData.city != null && locationData.city!.isNotEmpty) {
            cityController.text = locationData.city!;
          }
          if (locationData.state != null && locationData.state!.isNotEmpty) {
            stateController.text = locationData.state!;
          }
          if (locationData.zipCode != null && locationData.zipCode!.isNotEmpty) {
            zipController.text = locationData.zipCode!;
          }
          if (locationData.country != null && locationData.country!.isNotEmpty) {
            countryController.text = locationData.country!;
          }
        }
      } catch (e) {
        log("Error getting location data: $e");
      }
    }
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

      // Fallback: Try to decode from JWT token
      try {
        final token = StorageService.getToken();
        if (token != null && token.isNotEmpty) {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final resp = utf8.decode(base64Url.decode(normalized));
            final payloadMap = json.decode(resp);
            
            if (payloadMap['userId'] != null) {
              userCurrentId.value = payloadMap['userId'].toString();
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

  Future<void> _loadUserData() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Mock data
      pets.value = [
        {
          'id': '1',
          'name': 'Max',
          'breed': 'Golden Retriever',
          'age': '3',
          'photo': 'assets/images/pets/dog1.jpg',
          'type': 'dog',
        },
        {
          'id': '2',
          'name': 'Luna',
          'breed': 'Persian Cat',
          'age': '2',
          'photo': 'assets/images/pets/cat1.jpg',
          'type': 'cat',
        },
      ];
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onEditProfile() => Get.toNamed(AppRoutes.editProfile);

  Future<void> onAddPet() async {
    final result = await Get.toNamed(AppRoutes.addPet);
    if (result != null) {
      // Add new pet to list
      pets.add(result as Map<String, dynamic>);
      petCount.value++;
    }
  }

  void onPetTap(Map<String, dynamic> pet) {
    Get.toNamed(
      AppRoutes.petDetails,
      arguments: pet,
    );
  }

  // Utility method to check if current user is following a specific user
  bool isCurrentUserFollowing(String targetUserId) {
    if (profile.value == null || targetUserId.isEmpty) return false;
    return profile.value!.following.contains(targetUserId);
  }

  // Utility method to get follow statistics
  Map<String, int> getFollowStatistics() {
    return {
      'followers': followersCount.value,
      'following': followingCount.value,
    };
  }
}
