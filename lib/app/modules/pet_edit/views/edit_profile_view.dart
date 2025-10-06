import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../controllers/pet_edit_controller.dart';
import '../../../routes/app_routes.dart';

class EditPetProfileView extends GetView<PetEditController> {
  const EditPetProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          final photo = controller.petPhoto.value;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  const AppText(
                    text: 'Profile',
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 10),
                  const AppText(
                    text: 'Basic Info',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),

                  // Pet Photo
                  Center(
                    child: GestureDetector(
                      onTap: () => controller.pickPetPhoto(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade100,
                            ),
                            child: ClipOval(
                              child: () {
                                if (photo != null) {
                                  return Image.file(
                                    photo,
                                    fit: BoxFit.cover,
                                  );
                                }
                                final String? netUrl = (controller.networkImageUrl.value != null && controller.networkImageUrl.value!.isNotEmpty)
                                    ? controller.networkImageUrl.value
                                    : ((controller.petData.value?.profilePic != null && controller.petData.value!.profilePic!.isNotEmpty)
                                        ? controller.petData.value!.profilePic
                                        : null);
                                if (netUrl != null) {
                                  return Image.network(
                                    netUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 40,
                                        color: AppColors.blue,
                                      );
                                    },
                                  );
                                }
                                return const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: AppColors.blue,
                                );
                              }(),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const AppText(
                    text: 'Pet Name',
                    fontWeight: FontWeight.w400,
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hint: 'Enter Pet Name',
                    controller: controller.nameController,
                  ),
                  const SizedBox(height: 24),

                  const AppText(
                    text: 'Sex',
                    fontWeight: FontWeight.w400,
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hint: 'Select sex',
                    isDropdown: true,
                    items: const ['Male ♂', 'Female ♀'],
                    selectedValue: (() {
                      final v = controller.selectedSex.value.trim();
                      if (v.toLowerCase() == 'male') return 'Male ♂';
                      if (v.toLowerCase() == 'female') return 'Female ♀';
                      return null;
                    })(),
                    onDropdownChanged: (value) {
                      if (value != null) {
                        controller.selectSex(value.split(' ')[0]);
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                  const AppText(
                    text: 'Date of Birth',
                    fontWeight: FontWeight.w400,
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hint: 'DD / MM / YYYY',
                    controller: controller.dobController,
                    readOnly: true,
                    onFieldTap: () => controller.selectDate(context),
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const AppText(
                    text: 'Bio',
                    fontWeight: FontWeight.w400,
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    maxLines: 5,
                    hint: 'Tell us about your pet',
                    controller: controller.bioController,
                  ),

                  SizedBox(height: Get.height / 25),
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
                          onPressed: () => Get.toNamed(AppRoutes.petEditAppearanceFlow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}