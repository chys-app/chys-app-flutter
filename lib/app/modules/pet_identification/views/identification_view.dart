import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';

class IdentificationView extends GetView<SignupController> {
  const IdentificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isBackButton = Get.arguments ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                if (!isBackButton)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => controller.goBack(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                const SizedBox(height: 24),

                // Title
                const AppText(
                  text: 'Identification & Safety',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                const SizedBox(height: 32),

                // Microchip Number
                const AppText(
                  text: 'Microchip Number',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.microchipController,
                  hint: "Microchip Number",
                ),
                const SizedBox(height: 24),

                // Tag ID or CHYS ID
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
                  hint: "Tag ID or CHYS ID",
                ),
                const SizedBox(height: 24),

                // // Lost Status Dropdown
                // AppText(
                //   text:
                //   'Lost Status',
                //
                //   color:AppColors.purple,
                //   fontSize: 14,
                //   fontWeight: FontWeight.w400,
                //
                // ),
                //
                // const SizedBox(height: 8),
                // CustomTextField(
                //   isDropdown: true,
                //   controller: TextEditingController(),
                //   items: controller.lostStatusOptions,
                //   onDropdownChanged: (value) {
                //     if (value != null) controller.updateLostStatus(value);
                //   },
                // ),
                // // Vaccination Status Dropdown
                // const SizedBox(height: 24),

                const AppText(
                  text: 'Vaccination Status',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),

                CustomTextField(
                  isDropdown: true,
                  hint: "Vaccination Status",
                  selectedValue: controller.vaccinationStatus.value.isNotEmpty
                      ? controller.vaccinationStatus.value
                      : null,
                  items: controller.vaccinationStatusOptions,
                  onDropdownChanged: (value) {
                    if (value != null) {
                      controller.updateVaccinationStatus(value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Vet Name
                const AppText(
                  text: 'Vet Name',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.vetNameController,
                  hint: "Vet Name",
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
                  hint: "Vet Contact Number",
                ),

                // Vet Contact Number
                const SizedBox(height: 38),

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
                      child: Appbutton(
                        backgroundColor: AppColors.blue,
                        borderWidth: 0,
                        label: 'Next',
                        onPressed: () => controller.saveIdentification(),
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
