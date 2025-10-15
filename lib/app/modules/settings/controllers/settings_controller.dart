import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../../login/controllers/login_controller.dart';

class SettingsController extends GetxController {
  final pushNotifications = true.obs;
  final emailNotifications = true.obs;
  final isDarkMode = false.obs;
  void togglePushNotifications(bool value) => pushNotifications.value = value;
  void toggleEmailNotifications(bool value) => emailNotifications.value = value;
  void toggleDarkMode(bool value) => isDarkMode.value = value;
  void onProfileTap() => Get.toNamed(AppRoutes.profile);
  void onPrivacyTap() => Get.toNamed(AppRoutes.privacy);
  void onSecurityTap() => Get.toNamed(AppRoutes.security);
  void onLanguageTap() => Get.toNamed(AppRoutes.language);
  void onHelpCenterTap() => Get.toNamed(AppRoutes.helpCenter);
  void onContactUsTap() => Get.toNamed(AppRoutes.contactUs);
  void onTermsTap() => Get.toNamed(AppRoutes.terms);
  void onPrivacyPolicyTap() => Get.toNamed(AppRoutes.privacyPolicy);
  Future<void> handleLogout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title:const Text('Logout'),
        content:const Text('Are you sure you want to logout? This will clear all your data and require you to login again.'),
        actions: [
          TextButton(
            child:const Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          TextButton(
            child:const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    try {
      // Navigate to login first
      Get.offAllNamed(AppRoutes.login);
      
      // Clear all controllers after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.deleteAll();
        // Reinitialize LoginController after clearing all
        Get.put(LoginController());
      });
      
    } catch (e) {
      // Even if there's an error, ensure LoginController is available and navigate to login
      try {
        Get.deleteAll();
        Get.put(LoginController());
      } catch (controllerError) {
        print("Error initializing LoginController: $controllerError");
      }
      Get.offAllNamed(AppRoutes.login);
    }
  }
} 