import 'package:chys/app/core/const/app_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';

class PetSelectionView extends GetView<SignupController> {
  const PetSelectionView({super.key});
  @override
  Widget build(BuildContext context) {
    final isBackButton = Get.arguments ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                if (!isBackButton)
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                const SizedBox(height: 80),
                // AppText(
                //   text: 'What type of pet do you have?',
                //   fontSize: 16,
                //   color: AppColors.purple,
                //   fontWeight: FontWeight.w600,
                // ),
                const SizedBox(height: 40),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPetOption(
                        label: 'Dog',
                        isSelected: controller.selectedPetType.value == 'dog',
                        onTap: () => controller.selectPetType('dog'),
                        imagePath: 'assets/images/dog.png',
                      ),
                      const SizedBox(width: 40),
                      _buildPetOption(
                        label: 'Cat',
                        isSelected: controller.selectedPetType.value == 'cat',
                        onTap: () => controller.selectPetType('cat'),
                        imagePath: 'assets/images/cat.png',
                      ),
                    ],
                  ),
                ),
                Center(
                  child: _buildPetOption(
                    label: 'Other',
                    isSelected: controller.selectedPetType.value == 'Other',
                    onTap: () => controller.selectPetType('Other'),
                    imagePath: AppImages.other,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Appbutton(
                        backgroundColor: Colors.white,
                        borderColor: Colors.white,
                        onPressed: () => Get.back(),
                        label: 'Back',
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      child: Appbutton(
                        backgroundColor: Colors.white,
                        borderColor: Colors.white,
                        label: 'Next',
                        onPressed: controller.proceedFromPetSelection,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required String imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.blue : Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
