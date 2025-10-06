import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';

class OwnerInfoView extends GetView<SignupController> {
  const OwnerInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final isBackButton = Get.arguments ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                        text: 'Owner\'s Info',
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 32),

                      // Owner's Contact Number
                      const AppText(
                        text: 'Owner\'s Contact Number',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Owner\'s Contact Number",
                        controller: controller.ownerContactController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      // Address Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText(
                            text: 'Address Details',
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          Row(
                            children: [
                              const AppText(
                                text: 'Private',
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              const SizedBox(width: 8),
                              Obx(
                                () => Switch(
                                  value: controller.isAddressPrivate.value,
                                  onChanged: (value) =>
                                      controller.isAddressPrivate.value = value,
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Street/Door/Apt Number
                      const AppText(
                        text: 'Street/ Door/ Apt Number',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      // const SizedBox(height: 8),
                      // CustomTextField(
                      //   hint: "Street/ Door/ Apt Number",
                      //   controller: controller.streetController,
                      // ),
                      const SizedBox(height: 16),
                      AddressAutocompleteTextField(
                        mapsApiKey: 'AIzaSyBuWgYRQycmeaBRvBohDapMbEY-wZHre-U',
                        onSuggestionClick: controller.onSuggestionClick,
                        clearButton: const Icon(Icons.clear),
                        decoration: const InputDecoration(
                          hintText: "Start typing an address...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      // Zip Code and City
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
                                  controller: controller.zipCodeController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                  controller: controller.cityController,
                                  selectedValue:
                                      controller.selectedCity.value.isEmpty
                                          ? null
                                          : controller.selectedCity.value,
                                  isDropdown: false,
                                  // items: controller.cities
                                  //     .map((e) => e['city']!)
                                  //     .toList(),
                                  // onDropdownChanged: (value) {
                                  //   if (value != null)
                                  //     controller.selectedCity.value = value;
                                  // },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // State and Country
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
                                  isDropdown: false,
                                  controller: controller.stateController,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const AppText(
                                  text: 'Country',
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  isDropdown: false,
                                  controller: controller.countryController,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                              onPressed: () => controller.savePetProfile(),
                            ),
                          ),
                        ],
                      ),
                      // Navigation Buttons
                    ],
                  ),
                ),
              ),
            ),
            // Map Section
          ],
        ),
      ),
    );
  }
}
