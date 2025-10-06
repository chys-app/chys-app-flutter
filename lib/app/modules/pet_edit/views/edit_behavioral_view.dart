import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../controllers/pet_edit_controller.dart';
import '../../../routes/app_routes.dart';

class EditBehavioralView extends GetView<PetEditController> {
  const EditBehavioralView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const AppText(
                  text: 'Wellness & Care',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                const SizedBox(height: 20),

                _buildSection(
                  'Personality Traits',
                  controller.personalityController,
                  "Describe your pet's personality...",
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                _buildSection(
                  'Allergies',
                  controller.allergiesController,
                  'List any known allergies...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                _buildSection(
                  'Special Needs / Medical Conditions',
                  controller.specialNeedsController,
                  'Describe any special needs or medical conditions...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                _buildSection(
                  'Feeding Instructions',
                  controller.feedingController,
                  'Describe feeding schedule and preferences...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                _buildSection(
                  'Daily Routine / Exercise Needs',
                  controller.routineController,
                  'Describe daily activities and exercise needs...',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

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
                        onPressed: () => Get.toNamed(AppRoutes.petEditOwnerInfoFlow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    TextEditingController textController,
    String hintText, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: title,
          fontSize: 14,
          color: AppColors.purple,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: CustomTextField(
            controller: textController,
            maxLines: maxLines,
            hint: hintText,
          ),
        ),
      ],
    );
  }
}