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
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';

class EditProfile extends StatelessWidget {
  final profileController = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompleteProfile = Get.arguments ?? false;

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
        title: const Text(
          "Edit Profile",
          style: TextStyle(
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
                text: "Personal Info",
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
                text: 'Full Name',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Enter full name",
                controller: profileController.nameController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              const AppText(
                text: 'Bio',
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Tell us about yourself",
                controller: profileController.bioController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              const AppText(
                text: 'Address detail',
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
              AddressAutocompleteTextField(
                controller: profileController.streetController,
                mapsApiKey: 'AIzaSyBuWgYRQycmeaBRvBohDapMbEY-wZHre-U',
                onSuggestionClick: profileController.onSuggestionClick,
                clearButton: const Icon(Icons.clear),
                decoration: const InputDecoration(
                  hintText: "Start typing an address...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: "Enter street",
                controller: profileController.streetController,
                keyboardType: TextInputType.text,
                readOnly: true,
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
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Enter zip code",
                        controller: profileController.zipController,
                        keyboardType: TextInputType.phone,
                        readOnly: true,
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
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "City",
                        controller: profileController.cityController,
                        readOnly: true,
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
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Select State",
                        controller: profileController.stateController,
                        readOnly: true,
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
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Select country",
                        controller: profileController.countryController,
                        readOnly: true,
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
                label: "Save Profile",
                textColor: AppColors.secondary,
                onPressed: () {
                  profileController.updateProfile(isCompleteProfile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
