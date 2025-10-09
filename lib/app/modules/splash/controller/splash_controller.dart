import 'dart:developer';

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
    
    // Wait for the first frame to ensure GetMaterialApp is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateToNextScreen();
    });
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
      final profileController = Get.put(ProfileController(), permanent: true);
      
      try {
        // Fetch profile from backend to check completion status
        log("Fetching profile to determine completion status...");
        await profileController.fetchProfilee();
        
        // Check if user has a pet profile (indicates profile is complete)
        final hasPet = profileController.userPet.value != null;
        final hasProfile = profileController.profile.value != null;
        
        log("Profile check - hasPet: $hasPet, hasProfile: $hasProfile");
        
        // If user has both profile and pet, they've completed setup
        if (hasProfile && hasPet) {
          log("Profile complete - navigating to home");
          // Update local flags to prevent future checks
          await StorageService.setStepDone(StorageService.petProfileComplete);
          Future.microtask(() => Get.find<MapController>().selectFeature("user"));
          Get.offAllNamed(AppRoutes.home);
          return;
        }
        
        // If profile exists but no pet, check if they chose "don't have pet"
        if (hasProfile && !hasPet) {
          final userData = StorageService.getUser();
          final hasPetChoice = userData?['hasPet'] == false;
          
          if (hasPetChoice) {
            log("User chose not to have pet - navigating to home");
            await StorageService.setStepDone(StorageService.petProfileComplete);
            Future.microtask(() => Get.find<MapController>().selectFeature("user"));
            Get.offAllNamed(AppRoutes.home);
            return;
          }
        }
        
        log("Profile incomplete - checking which step to navigate to");
      } catch (e) {
        log("Error fetching profile: $e - falling back to local flags");
      }
      
      // Fallback to local flags if API call fails or profile is incomplete
      // Check which step is incomplete and navigate there
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
        // All local flags are set, assume complete and go to home
        log("All local flags set - navigating to home");
        await StorageService.setStepDone(StorageService.petProfileComplete);
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
