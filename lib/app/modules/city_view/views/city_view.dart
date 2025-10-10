import 'package:chys/app/core/const/app_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';

class CityView extends GetView<SignupController> {
  const CityView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.goBack(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              // Spacer to push content to center
              const Spacer(),

              // Center Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image
                    Image.asset(
                      AppImages.onboard,
                      height: 250,
                      width: 250,
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const AppText(
                      text: 'Your City',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const AppText(
                      text: 'See the pets in your neighborhood',
                      fontSize: 14,
                      color: AppColors.purple,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),

              // Spacer to push button to bottom
              const Spacer(),

              // Add a Pet Button
              Center(
                child: Appbutton(
                  width: Get.width * 0.7,
                  borderColor: AppColors.blue,
                  backgroundColor: AppColors.blue,
                  borderWidth: 0,
                  label: "Add a Pet",
                  onPressed: () {
                    Get.toNamed('/pet-selection', arguments: true);
                  },
                ),
              ),
              const SizedBox(height: 16),


              // Let's Go Button
              Appbutton(
                width: Get.width,
                borderColor: AppColors.blue,
                backgroundColor: AppColors.blue,
                borderWidth: 0,
                label: "Let's Go!",
                onPressed: () => controller.finishSignup(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
