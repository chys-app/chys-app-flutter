import 'dart:developer';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/validators/form_validators.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';

class PetProfileView extends GetView<SignupController> {
  const PetProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final isBackButton = arguments is bool ? arguments : false;
    final petData = arguments is Map<String, dynamic> ? arguments : null;
    
    // Populate form with pet data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (petData != null) {
        controller.populatePetFormData(petData);
      }
    });

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
                  // Back Button
                  if (!isBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => controller.goBack(),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  const SizedBox(height: 40),
                  // Title
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
                  Obx(() => controller.isEditProfile.value
                      ? const SizedBox.shrink()
                      : Center(
                          child: GestureDetector(
                            onTap: () => controller.pickPetPhoto(),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Circular image container
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade100,
                                    image: photo != null
                                        ? DecorationImage(
                                            image: FileImage(photo),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: photo == null
                                      ? const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 40,
                                          color: AppColors.blue,
                                        )
                                      : null,
                                ),

                                // Edit icon if image is set
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
                        )),
                  // Pet Name
                  const AppText(
                    text: 'Pet Name',
                    fontWeight: FontWeight.w400,
                    color: AppColors.purple,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    hint: "Enter Pet Name",
                    controller: controller.nameController,
                    validator: FormValidators.validateUsername,
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
                    hint: "Select sex",
                    isDropdown: true,
                    selectedValue: (() {
                      final v = controller.selectedSex.value.trim();
                      if (v.toLowerCase() == 'male') return 'Male ♂';
                      if (v.toLowerCase() == 'female') return 'Female ♀';
                      return null;
                    })(),
                    items: const [
                      'Male ♂',
                      'Female ♀',
                    ],
                    onDropdownChanged: (value) {
                      controller.selectedSex.value = value!.split(' ')[0];
                      log("Selected state ${controller.selectedSex.value}");
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
                    hint: "DD / MM / YYYY",
                    controller: controller.dobController,
                    readOnly: true,
                    onFieldTap: () => controller.selectDate(context),
                    suffixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  // After Date of Birth field
                  const SizedBox(height: 24),

                  // Spayed/Neutered Checkbox
                  Row(
                    children: [
                      Obx(() => Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.isSpayedNeutered.value
                                  ? AppColors.blue
                                  : Colors.transparent,
                              border: Border.all(
                                color: controller.isSpayedNeutered.value
                                    ? AppColors.blue
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    controller.isSpayedNeutered.toggle(),
                                borderRadius: BorderRadius.circular(12),
                                child: controller.isSpayedNeutered.value
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                            ),
                          )),
                      const SizedBox(width: 12),
                      const AppText(
                        text: 'Sprayed/Neutered',
                        fontSize: 14,
                        color: AppColors.purple,
                        fontWeight: FontWeight.w400,
                      ),
                    ],
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
                    hint: "Tell us about your pet",
                    controller: controller.bioController,
                    validator: FormValidators.validateUsername,
                  ),
                  SizedBox(height: Get.height / 25),
                  // Navigation Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Appbutton(
                          backgroundColor: Colors.white,
                          borderColor: Colors.white,
                          onPressed: () => controller.goBack(),
                          label: 'Back',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Appbutton(
                          backgroundColor: Colors.white,
                          borderColor: Colors.white,
                          label: 'Next',
                          onPressed: () => controller.savePetProfile1(),
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