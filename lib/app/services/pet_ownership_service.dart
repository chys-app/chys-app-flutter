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

  /// Check if user can create posts
  bool get canCreatePosts => hasPet;

  /// Check if user can create podcasts
  bool get canCreatePodcasts => hasPet;

  /// Get restriction message for posts
  String get postRestrictionMessage => 
    "You need to have a pet to create posts. Add a pet to your profile to unlock this feature!";

  /// Get restriction message for podcasts
  String get podcastRestrictionMessage => 
    "You need to have a pet to create podcasts. Add a pet to your profile to unlock this feature!";

  // /// Show restriction dialog for posts
  // void showPostRestriction() {
  //   Get.dialog(
  //     _buildRestrictionDialog(
  //       title: "Post Creation Restricted",
  //       message: postRestrictionMessage,
  //       icon: Icons.photo_camera,
  //     ),
  //   );
  // }

  // /// Show restriction dialog for podcasts
  // void showPodcastRestriction() {
  //   Get.dialog(
  //     _buildRestrictionDialog(
  //       title: "Podcast Creation Restricted",
  //       message: podcastRestrictionMessage,
  //       icon: Icons.mic,
  //     ),
  //   );
  // }

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