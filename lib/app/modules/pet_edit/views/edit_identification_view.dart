import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../controllers/pet_edit_controller.dart';
import '../../../routes/app_routes.dart';

class EditIdentificationView extends GetView<PetEditController> {
  const EditIdentificationView({super.key});

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
                  text: 'Identification & Safety',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                const SizedBox(height: 32),

                const AppText(
                  text: 'Microchip Number',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.microchipController,
                  hint: 'Microchip Number',
                ),
                const SizedBox(height: 24),

                const AppText(
                  text: 'Tag ID or CHYS ID',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.tagIdController,
                  keyboardType: TextInputType.text,
                  hint: 'Tag ID or CHYS ID',
                ),
                const SizedBox(height: 24),

                const AppText(
                  text: 'Vaccination Status',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  isDropdown: true,
                  hint: 'Vaccination Status',
                  selectedValue: controller.vaccinationStatus.value.isNotEmpty
                      ? controller.vaccinationStatus.value
                      : null,
                  items: controller.vaccinationOptions,
                  onDropdownChanged: (value) {
                    if (value != null) controller.selectVaccinationStatus(value);
                  },
                ),
                const SizedBox(height: 24),

                const AppText(
                  text: 'Vet Name',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.vetNameController,
                  hint: 'Vet Name',
                ),
                const SizedBox(height: 24),

                const AppText(
                  text: 'Vet Contact Number',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.vetContactController,
                  hint: 'Vet Contact Number',
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 38),
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
                        onPressed: () => Get.toNamed(AppRoutes.petEditBehavioralFlow),
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
}