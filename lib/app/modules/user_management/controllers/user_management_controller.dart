import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/user_management_service.dart';
import '../../../services/short_message_utils.dart';
import '../../../core/controllers/loading_controller.dart';

class UserManagementController extends GetxController {
  final UserManagementService _userManagementService = UserManagementService.instance;
  
  // Observable lists
  final blockedUsers = <Map<String, dynamic>>[].obs;
  final reportedUsers = <Map<String, dynamic>>[].obs;
  
  // Loading states
  final isLoadingBlockedUsers = false.obs;
  final isLoadingReportedUsers = false.obs;
  final isBlockingUser = false.obs;
  final isReportingUser = false.obs;
  
  // Form controllers for reporting
  final reportReasonController = TextEditingController();
  final reportDescriptionController = TextEditingController();
  final selectedReportReason = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadBlockedUsers();
    loadReportedUsers();
  }
  
  @override
  void onClose() {
    reportReasonController.dispose();
    reportDescriptionController.dispose();
    super.onClose();
  }

  /// Load blocked users
  Future<void> loadBlockedUsers() async {
    try {
      isLoadingBlockedUsers.value = true;
      final users = await _userManagementService.getBlockedUsers();
      blockedUsers.assignAll(users);
      log("✅ Loaded ${users.length} blocked users");
    } catch (e) {
      log("❌ Error loading blocked users: $e");
      ShortMessageUtils.showError('Failed to load blocked users');
    } finally {
      isLoadingBlockedUsers.value = false;
    }
  }

  /// Load reported users
  Future<void> loadReportedUsers() async {
    try {
      isLoadingReportedUsers.value = true;
      final users = await _userManagementService.getReportedUsers();
      reportedUsers.assignAll(users);
      log("✅ Loaded ${users.length} reported users");
    } catch (e) {
      log("❌ Error loading reported users: $e");
      ShortMessageUtils.showError('Failed to load reported users');
    } finally {
      isLoadingReportedUsers.value = false;
    }
  }

  /// Block a user
  Future<void> blockUser(String userId, String userName) async {
    try {
      isBlockingUser.value = true;
      Get.find<LoadingController>().show();
      
      final result = await _userManagementService.blockUser(userId);
      
      if (result['success']) {
        ShortMessageUtils.showSuccess('$userName has been blocked');
        await loadBlockedUsers(); // Refresh the list
      } else {
        ShortMessageUtils.showError(result['message']);
      }
    } catch (e) {
      log("❌ Error blocking user: $e");
      ShortMessageUtils.showError('Failed to block user');
    } finally {
      isBlockingUser.value = false;
      Get.find<LoadingController>().hide();
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId, String userName) async {
    try {
      isBlockingUser.value = true;
      Get.find<LoadingController>().show();
      
      final result = await _userManagementService.unblockUser(userId);
      
      if (result['success']) {
        ShortMessageUtils.showSuccess('$userName has been unblocked');
        await loadBlockedUsers(); // Refresh the list
      } else {
        ShortMessageUtils.showError(result['message']);
      }
    } catch (e) {
      log("❌ Error unblocking user: $e");
      ShortMessageUtils.showError('Failed to unblock user');
    } finally {
      isBlockingUser.value = false;
      Get.find<LoadingController>().hide();
    }
  }

  /// Report a user
  Future<void> reportUser({
    required String userId,
    required String userName,
  }) async {
    try {
      // Validate form
      if (selectedReportReason.value.isEmpty) {
        ShortMessageUtils.showError('Please select a reason for reporting');
        return;
      }
      
      isReportingUser.value = true;
      Get.find<LoadingController>().show();
      
      final result = await _userManagementService.reportUser(
        userId: userId,
        reason: selectedReportReason.value,
        description: reportDescriptionController.text.trim(),
      );
      
      if (result['success']) {
        ShortMessageUtils.showSuccess('$userName has been reported');
        await loadReportedUsers(); // Refresh the list
        
        // Clear form
        selectedReportReason.value = '';
        reportDescriptionController.clear();
        Get.back(); // Close the report dialog
      } else {
        ShortMessageUtils.showError(result['message']);
      }
    } catch (e) {
      log("❌ Error reporting user: $e");
      ShortMessageUtils.showError('Failed to report user');
    } finally {
      isReportingUser.value = false;
      Get.find<LoadingController>().hide();
    }
  }

  /// Show block user confirmation dialog
  void showBlockUserDialog(String userId, String userName) {
    Get.dialog(
      AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block $userName? You won\'t be able to see their posts or interact with them.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              blockUser(userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  /// Show unblock user confirmation dialog
  void showUnblockUserDialog(String userId, String userName) {
    Get.dialog(
      AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $userName? You\'ll be able to see their posts and interact with them again.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              unblockUser(userId, userName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  /// Show report user dialog
  void showReportUserDialog(String userId, String userName) {
    // Reset form
    selectedReportReason.value = '';
    reportDescriptionController.clear();
    
    Get.dialog(
      AlertDialog(
        title: Text('Report $userName'),
        content: SizedBox(
          width: Get.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reason dropdown
              DropdownButtonFormField<String>(
                value: selectedReportReason.value.isEmpty ? null : selectedReportReason.value,
                decoration: const InputDecoration(
                  labelText: 'Reason for reporting',
                  border: OutlineInputBorder(),
                ),
                items: _userManagementService.getReportReasons().map((reason) {
                  return DropdownMenuItem(
                    value: reason['value'],
                    child: Text(reason['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedReportReason.value = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              
              // Description text field
              TextField(
                controller: reportDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Please provide more details about the issue...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => reportUser(userId: userId, userName: userName),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    return await _userManagementService.isUserBlocked(userId);
  }

  /// Get report reasons for dropdown
  List<Map<String, String>> getReportReasons() {
    return _userManagementService.getReportReasons();
  }
} 