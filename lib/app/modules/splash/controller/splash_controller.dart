import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';
import '../../map/controllers/map_controller.dart';
import '../../signup/controller/signup_controller.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Animation controllers and Rx values
  late AnimationController animationController;
  late Animation<Color?> gradientColor1;
  late Animation<Color?> gradientColor2;
  final Rx<Color> color1 = Rx<Color>(AppColors.blue);
  final Rx<Color> color2 = Rx<Color>(AppColors.primary);

  final RxDouble logoScale = 0.8.obs;
  final RxDouble logoOpacity = 0.0.obs;
  final RxDouble taglineOpacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Animated gradient between two brand colors
    gradientColor1 = ColorTween(
      begin: AppColors.lightBlue,
      end: AppColors.primary,
    ).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut));
    gradientColor2 = ColorTween(
      begin: AppColors.Teal_Blue,
      end: AppColors.accent,
    ).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    animationController.addListener(() {
      color1.value = gradientColor1.value ?? AppColors.blue;
      color2.value = gradientColor2.value ?? AppColors.primary;
    });

    // Start animations
    animationController.forward();
    _startLogoAndTaglineAnimation();
    navigateToNextScreen();
  }

  void _startLogoAndTaglineAnimation() async {
    // Logo fade/scale in
    await Future.delayed(const Duration(milliseconds: 400));
    logoOpacity.value = 1.0;
    logoScale.value = 1.0;
    // Tagline fade in after logo
    await Future.delayed(const Duration(milliseconds: 800));
    taglineOpacity.value = 1.0;
  }

  Future<void> navigateToNextScreen() async {
    // Skip delay during hot reload for faster development
    if (!Get.isRegistered<ProfileController>() || Get.currentRoute == AppRoutes.initial) {
      await Future.delayed(const Duration(seconds: 4));
    }
    NotificationUtil.requestNotificationPermission();

    final token = StorageService.getToken();

    if (token != null && token.isNotEmpty) {
      Get.put(ProfileController(), permanent: true);
      
      // Check if profile is complete first - if yes, go to home
      // Also check if all steps are done (for legacy users who might not have petProfileComplete flag)
      final isProfileComplete = StorageService.isStepDone(StorageService.petProfileComplete);
      final allStepsDone = StorageService.isStepDone(StorageService.signupDone) &&
          StorageService.isStepDone(StorageService.editProfileDone) &&
          StorageService.isStepDone(StorageService.petOwnerDone);
      
      if (isProfileComplete || allStepsDone) {
        Future.microtask(() => Get.find<MapController>().selectFeature("user"));
        Get.offAllNamed(AppRoutes.home);
        return; // Important: stop checking other conditions
      }
      
      // Otherwise, check which step is incomplete and navigate there
      if (!StorageService.isStepDone(StorageService.signupDone)) {
        Get.put(SignupController(), permanent: true);
        Get.offAllNamed(AppRoutes.verifyEmailView);
      } else if (!StorageService.isStepDone(StorageService.editProfileDone)) {
        Get.offAllNamed(AppRoutes.editProfile, arguments: true);
      } else if (!StorageService.isStepDone(StorageService.petOwnershipDone)) {
        Get.offAllNamed(AppRoutes.petOwnership, arguments: true);
      } else if (!StorageService.isStepDone(StorageService.petSelectionDone)) {
        Get.offAllNamed(AppRoutes.petSelection, arguments: true);
      } else if (!StorageService.isStepDone(StorageService.petBasicDataDone)) {
        Get.offAllNamed(AppRoutes.petProfile, arguments: true);
      } else if (!StorageService.isStepDone(StorageService.petApearenceDone)) {
        Get.offAllNamed(AppRoutes.appearance, arguments: true);
      } else if (!StorageService.isStepDone(
          StorageService.petIdentificationDone)) {
        Get.offAllNamed(AppRoutes.identification, arguments: true);
      } else if (!StorageService.isStepDone(StorageService.petBehavioralDone)) {
        Get.offAllNamed(AppRoutes.behavioral, arguments: true);
      } else if (!StorageService.isStepDone(StorageService.petOwnerDone)) {
        Get.offAllNamed(AppRoutes.ownerInfo, arguments: true);
      } else {
        // All steps done, go to home
        Future.microtask(() => Get.find<MapController>().selectFeature("user"));
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
