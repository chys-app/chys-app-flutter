import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/signup/controller/signup_controller.dart';
import 'storage_service.dart';

class PetOwnershipService {
  static PetOwnershipService? _instance;
  static PetOwnershipService get instance => _instance ??= PetOwnershipService._();
  
  PetOwnershipService._();

  /// Check if the current user has a pet
  bool get hasPet {
    try {
      // First try to get from ProfileController
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();

        // Multi-pet support: treat any non-empty pet list as ownership
        if (profileController.userPets.isNotEmpty) {
          return true;
        }

        final userPet = profileController.userPet.value;
        if (userPet != null) {
          return userPet.isHavePet == true || userPet.name != null;
        }
      }
      
      // Fallback to SignupController
      if (Get.isRegistered<SignupController>()) {
        final signupController = Get.find<SignupController>();
        return signupController.hasPet.value;
      }
      
      // Check storage for pet ownership status
      final userData = StorageService.getUser();
      if (userData != null && userData['hasPet'] != null) {
        return userData['hasPet'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error checking pet ownership: $e');
      return false;
    }
  }

  /// Check if the current user is a business account
  bool get isBusinessUser {
    try {
      // First try to get from ProfileController
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        final userRole = profileController.profile.value?.role;
        if (userRole != null && userRole.toLowerCase() == 'biz-user') {
          return true;
        }
      }
      
      // Check storage for user role
      final userData = StorageService.getUser();
      if (userData != null && userData['role'] != null) {
        return userData['role'].toString().toLowerCase() == 'biz-user';
      }
      
      return false;
    } catch (e) {
      print('Error checking business user status: $e');
      return false;
    }
  }

  /// Check if user can create posts
  bool get canCreatePosts => hasPet && !isBusinessUser;

  /// Check if user can create podcasts
  bool get canCreatePodcasts => hasPet && !isBusinessUser;

  /// Get restriction message for posts
  String get postRestrictionMessage =>
      "Add a pet to your profile to create posts!";

  /// Get restriction message for podcasts
  String get podcastRestrictionMessage =>
      "Add a pet to your profile to create podcasts!";

// Get restriction message for stories
  String get storiesRestrictionMessage =>
      "Add a pet to your profile to create stories!";

  void showPostRestriction() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
      "Add a Pet",
      postRestrictionMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFFE3F2FD),
      colorText: const Color(0xFF0D47A1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          _navigateToAddPet();
        },
        child: const Text(
          "Add Pet",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void showPodcastRestriction() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
      "Add a Pet",
      podcastRestrictionMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFFE3F2FD),
      colorText: const Color(0xFF0D47A1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          _navigateToAddPet();
        },
        child: const Text(
          "Add Pet",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void showStoriesRestriction() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
      "Add a Pet",
      storiesRestrictionMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFFE3F2FD),
      colorText: const Color(0xFF0D47A1),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          _navigateToAddPet();
        },
        child: const Text(
          "Add Pet",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Widget _buildRestrictionDialog({
  //   required String title,
  //   required String message,
  //   required IconData icon,
  // }) {
  //   return AlertDialog(
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  //     title: Row(
  //       children: [
  //         Icon(
  //           icon,
  //           color: const Color(0xFF0095F6),
  //           size: 28,
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: const TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.w600,
  //               color: Color(0xFF262626),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //     content: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           message,
  //           style: const TextStyle(
  //             fontSize: 14,
  //             color: Color(0xFF666666),
  //             height: 1.4,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFFF8F9FA),
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(
  //               color: const Color(0xFFE9ECEF),
  //               width: 1,
  //             ),
  //           ),
  //           child: Row(
  //             children: [
  //               const Icon(
  //                 Icons.pets,
  //                 color: Color(0xFF0095F6),
  //                 size: 20,
  //               ),
  //               const SizedBox(width: 8),
  //               const Expanded(
  //                 child: Text(
  //                   "Add a pet to unlock all features!",
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w500,
  //                     color: Color(0xFF0095F6),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Get.back(),
  //         child: const Text(
  //           "Cancel",
  //           style: TextStyle(
  //             color: Color(0xFF666666),
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //       ),
  //       ElevatedButton(
  //         onPressed: () {
  //           Get.back();
  //           _navigateToAddPet();
  //         },
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: const Color(0xFF0095F6),
  //           foregroundColor: Colors.white,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //         ),
  //         child: const Text(
  //           "Add Pet",
  //           style: TextStyle(
  //             fontWeight: FontWeight.w600,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _navigateToAddPet() {
    try {
      // Navigate to add pet flow
      if (!Get.isRegistered<SignupController>()) {
        Get.put(SignupController());
      }
      final signupController = Get.find<SignupController>();
      signupController.assignValues();
      Get.toNamed('/pet-selection');
    } catch (e) {
      print('Error navigating to add pet: $e');
      // Fallback navigation
      Get.toNamed('/pet-ownership');
    }
  }
} 