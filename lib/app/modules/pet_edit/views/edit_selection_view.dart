import 'package:chys/app/core/const/app_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../controllers/pet_edit_controller.dart';
import '../../../routes/app_routes.dart';

class EditPetSelectionView extends GetView<PetEditController> {
  const EditPetSelectionView({super.key});
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
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPetOption(
                        label: 'Dog',
                        isSelected: controller.selectedPetType.value.toLowerCase() == 'dog',
                        onTap: () => controller.selectPetType('Dog'),
                        imagePath: 'assets/images/dog.png',
                      ),
                      const SizedBox(width: 40),
                      _buildPetOption(
                        label: 'Cat',
                        isSelected: controller.selectedPetType.value.toLowerCase() == 'cat',
                        onTap: () => controller.selectPetType('Cat'),
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
                  children: [
                    Expanded(
                      child: Appbutton(
                        onPressed: () => controller.goBack(),
                        label: 'Back',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Appbutton(
                        backgroundColor: AppColors.blue,
                        borderWidth: 0,
                        label: 'Next',
                        onPressed: () => Get.toNamed(AppRoutes.petEditProfileFlow),
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