import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/splash_controller.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final SplashController controller = Get.put(SplashController());
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: Colors.white,
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     colors: [controller.color1.value, controller.color2.value],
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //   ),
        // ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() => AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: controller.logoOpacity.value,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 600),
                      scale: controller.logoScale.value,
                      child: SizedBox(
                        height: AppSize.getHeight(
                            60), // ~40% of screen height is usually enough
                        child: Image.asset(
                          AppImages.appLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )),
              // const SizedBox(height: 32),
              // Obx(() => AnimatedOpacity(
              //       duration: const Duration(milliseconds: 600),
              //       opacity: controller.logoOpacity.value,
              //       child: const AppText(
              //         text: 'Welcome to Chys',
              //         fontSize: 28,
              //         fontWeight: FontWeight.bold,
              //         color: Colors.white,
              //         textAlign: TextAlign.center,
              //       ),
              //     )),
              // const SizedBox(height: 12),
              // Obx(() => AnimatedOpacity(
              //       duration: const Duration(milliseconds: 600),
              //       opacity: controller.taglineOpacity.value,
              //       child: const AppText(
              //         text: 'A vibrant community for pet lovers',
              //         fontSize: 16,
              //         color: Colors.white,
              //         textAlign: TextAlign.center,
              //       ),
              //     )),
            ],
          ),
        ),
      ),
    );
  }
}
