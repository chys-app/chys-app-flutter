import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/widget/app_button.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotted/flutter_dotted.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../signup/controller/signup_controller.dart';

class AppearanceView extends GetView<SignupController> {
  const AppearanceView({super.key});
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
                  text: 'Appearance',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                const SizedBox(height: 16),
                // Photos Section
                const AppText(
                  text: 'Photos',
                  color: AppColors.purple,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                const SizedBox(height: 8),
                // Photo Upload Area with Preview
                Obx(() => controller.isEditProfile.value
                    ? const SizedBox.shrink()
                    : controller.photos.isEmpty
                        ? GestureDetector(
                            onTap: () => controller.pickPhotos(),
                            child: FlutterDotted(
                              color: AppColors.blue,
                              gap: 4,
                              strokeWidth: 1.5,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      AppImages.upload,
                                      height: 60,
                                      color: AppColors.blue,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Upload up to 5 Photos',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                            color: AppColors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : FlutterDotted(
                            color: AppColors.blue,
                            gap: 4,
                            strokeWidth: 1.5,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: controller.photos.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              controller.photos[index],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  controller.removePhoto(index),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors.black.withOpacity(
                                                    0.5,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (controller.photos.length < 5) ...[
                                    const SizedBox(height: 16),
                                    TextButton.icon(
                                      onPressed: () => controller.pickPhotos(),
                                      icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                      ),
                                      label: const AppText(
                                        text: 'Add More Photos',
                                        fontSize: 18,
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                const SizedBox(height: 24),
                // Color Dropdown
                const AppText(
                  text: 'Pet Color',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: "e.g, Brown or white",
                  controller: controller.petColor,
                ),
                const SizedBox(height: 24),
                // Color Dropdown
                const AppText(
                  text: 'Breed',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: controller.breedTextController,
                  hint: "Enter breed(s), e.g., Labrador, Poodle...",
                  maxLines: null, // Optional: allows multiline
                ),
                const SizedBox(height: 24),
                // Size Dropdown
                const AppText(
                  text: 'Size',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  isDropdown: true,
                  selectedValue: controller.selectedSize.value.isNotEmpty
                      ? controller.selectedSize.value
                      : null,
                  items: controller.sizeOptions,
                  onDropdownChanged: (value) {
                    if (value != null) controller.updateSize(value);
                  },
                ),
                const SizedBox(height: 24),
                // Weight Input
                const AppText(
                  text: 'Weight kg',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: "Weight in kg",
                  controller: controller.weightController,
                  keyboardType: TextInputType.number,
                  onChanged: controller.onWeightChanged,
                ),
                const SizedBox(height: 8),

                Obx(() => controller.weightInLbs.value.isNotEmpty
                    ? AppText(
                        text: "Weight in lbs: ${controller.weightInLbs.value}",
                        color: AppColors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      )
                    : SizedBox.shrink()),
                const SizedBox(height: 24),
                // Distinguishing Marks
                const AppText(
                  text: 'Distinguishing Marks',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: "e.g, white spot on chest",
                  controller: controller.marksController,
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
                      child: Appbutton(
                        backgroundColor: AppColors.blue,
                        borderWidth: 0,
                        label: 'Next',
                        onPressed: () => controller.saveAppearance(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
