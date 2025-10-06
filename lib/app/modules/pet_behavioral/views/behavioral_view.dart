import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';
import '../../signup/widgets/primary_button.dart';

class BehavioralView extends GetView<SignupController> {
  const BehavioralView({super.key});

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
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back_rounded),
                ),
                SizedBox(height: 40),
                AppText(
                  text: 'Wellness & Care',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                const SizedBox(height: 20),

                // Personality Traits
                _buildSection(
                  context,
                  'Personality Traits',
                  controller.personalityController,
                  'Describe your pet\'s personality...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Allergies
                _buildSection(
                  context,
                  'Allergies',
                  controller.allergiesController,
                  'List any known allergies...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Special Needs / Medical Conditions
                _buildSection(
                  context,
                  'Special Needs / Medical Conditions',
                  controller.specialNeedsController,
                  'Describe any special needs or medical conditions...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Feeding Instructions
                _buildSection(
                  context,
                  'Feeding Instructions',
                  controller.feedingController,
                  'Describe feeding schedule and preferences...',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Daily Routine / Exercise Needs
                _buildSection(
                  context,
                  'Daily Routine / Exercise Needs',
                  controller.routineController,
                  'Describe daily activities and exercise needs...',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Navigation Buttons
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
                      child:  Appbutton(
                        backgroundColor: AppColors.blue,
                        borderWidth: 0,

                        label: 'Next',
                        onPressed:
                            () => controller.saveBehavioralAndNavigate(),                      ),
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
    BuildContext context,
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
