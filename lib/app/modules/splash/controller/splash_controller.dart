import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../services/storage_service.dart';

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
  late final bool _hasShownSplash;

  bool get hasShownSplash => _hasShownSplash;

  @override
  void onInit() {
    super.onInit();
    _hasShownSplash = StorageService.isStepDone(StorageService.splashShown);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (_hasShownSplash) {
      Future.microtask(() => navigateToNextScreen(skipDelay: true));
      return;
    }

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

  Future<void> waitForInitialDelay({required bool skipDelay}) async {
    if (!skipDelay) {
      await Future.delayed(const Duration(seconds: 2));
    }
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

  Future<void> navigateToNextScreen({bool skipDelay = false}) async {
    try {
      await waitForInitialDelay(skipDelay: skipDelay);

      final hasShownSplash =
          StorageService.isStepDone(StorageService.splashShown);
      if (!hasShownSplash) {
        await StorageService.setStepDone(StorageService.splashShown);
      }

      final token = StorageService.getToken();
      final nextRoute =
          token != null && token.isNotEmpty ? AppRoutes.home : AppRoutes.login;

      log('Navigating from splash to $nextRoute');
      Get.offAllNamed(nextRoute);
    } catch (e, stackTrace) {
      log("Splash navigation failed: $e", stackTrace: stackTrace);
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
