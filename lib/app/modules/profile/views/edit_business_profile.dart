import 'dart:io';

import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/core/widget/app_button.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:chys/app/widget/image/svg_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditBusinessProfile extends StatefulWidget {
  EditBusinessProfile({super.key});

  @override
  State<EditBusinessProfile> createState() => _EditBusinessProfileState();
}

class _EditBusinessProfileState extends State<EditBusinessProfile> {
  late final ProfileController profileController;

  @override
  void initState() {
    super.initState();
    profileController = Get.find<ProfileController>();
  }

  @override
  Widget build(BuildContext context) {
    // Detect if this is part of registration flow
    final isRegistrationFlow = Get.arguments is bool && Get.arguments == true;
    final isCompleteProfile = isRegistrationFlow;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isRegistrationFlow ? "Complete Business Profile" : "Edit Business Profile",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const AppText(
                text: "Business Info",
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  children: [
                    Obx(() {
                      final imagePath =
                          profileController.profilePhoto.value?.path ??
                              profileController.imagePath.value;

                      return Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: imagePath.isEmpty
                                  ? const NetworkImage(
                                      "https://i.pravatar.cc/150?img=6")
                                  : imagePath.startsWith("http")
                                      ? NetworkImage(imagePath)
                                      : FileImage(File(imagePath))
                                          as ImageProvider,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () {
                                  // trigger image picker here
                                  profileController
                                      .pickImage(); // implement this method
                                },
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.blue,
                                  child: Center(
                                      child: AppImages.edit
                                          .toSvg(color: AppColors.secondary)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const AppText(
                text: 'Business Name',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Enter business name",
                controller: profileController.nameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              const AppText(
                text: 'Business Description',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Tell us about your business",
                controller: profileController.bioController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              const AppText(
                text: 'Website',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Enter business website",
                controller: profileController.websiteController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              const AppText(
                text: 'Tax ID',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Enter business tax ID",
                controller: profileController.taxIdController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              const AppText(
                text: 'Business Address',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              const AppText(
                text: 'Street/ Door/ Apt Number',
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Enter street address",
                controller: profileController.streetController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Zip Code',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Zip Code",
                        controller: profileController.zipController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'City',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "City",
                        controller: profileController.cityController,
                      ),
                    ],
                  ))
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'State',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Select State",
                        controller: profileController.stateController,
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: 'Country',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Select country",
                        controller: profileController.countryController,
                      ),
                    ],
                  ))
                ],
              ),
              const SizedBox(height: 24),
              Appbutton(
                width: Get.width,
                borderColor: AppColors.blue,
                backgroundColor: AppColors.blue,
                borderWidth: 0,
                label: isRegistrationFlow ? "Complete Business Profile" : "Save Business Profile",
                textColor: AppColors.secondary,
                onPressed: () {
                  profileController.updateProfile(isCompleteProfile, isBusinessProfile: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
