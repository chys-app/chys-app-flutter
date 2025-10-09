import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/widget/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../signup/controller/signup_controller.dart';

class PetOwnershipView extends GetView<SignupController> {
  const PetOwnershipView({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompleteProfile = Get.arguments ?? false;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spacer to push content to center
              const Spacer(),

              // Center Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image
                  Image.asset(
                    AppImages.image1,
                    height: 200,
                    width: 200,
                  ),
                  const SizedBox(height: 48),

                  // Option Buttons
                  Row(
                    children: [
                      // I have a pet button
                      Expanded(
                        child: Obx(() => Appbutton(
                              label: 'I have a pet',
                              onPressed: () =>
                                  controller.selectPetOwnership(true),
                              backgroundColor: controller.hasPet.value
                                  ? AppColors.blue
                                  : Colors.white,
                              textColor: controller.hasPet.value
                                  ? Colors.white
                                  : Colors.black,
                              borderWidth: 1,
                            )),
                      ),
                      const SizedBox(width: 16),
                      // I don't have a pet button
                      Expanded(
                        child: Obx(() => Appbutton(
                              label: "I don't have a pet",
                              onPressed: () =>
                                  controller.selectPetOwnership(false),
                              backgroundColor: !controller.hasPet.value &&
                                      controller.hasSelectedPetOwnership.value
                                  ? AppColors.blue
                                  : Colors.white,
                              textColor: !controller.hasPet.value &&
                                      controller.hasSelectedPetOwnership.value
                                  ? Colors.white
                                  : Colors.black,
                              borderWidth: 0,
                            )),
                      ),
                    ],
                  ),
                ],
              ),

              // Spacer to push navigation buttons to bottom
              const Spacer(),

              // Navigation Buttons
              Row(
                children: [
                  // Back button
                  Expanded(
                    child: Container(),
                  ),
                  const SizedBox(width: 16),
                  // Next button
                  Expanded(
                    child: Obx(() => Appbutton(
                          label: 'Next',
                          onPressed: controller.hasSelectedPetOwnership.value
                              ? () => controller.proceedFromPetOwnership()
                              : null,
                          textColor: Colors.black,
                          borderWidth: 0,
                          borderColor: Colors.white,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
