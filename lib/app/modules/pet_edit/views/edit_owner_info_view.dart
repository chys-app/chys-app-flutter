import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../controllers/pet_edit_controller.dart';
import 'package:google_maps_places_autocomplete_widgets/widgets/address_autocomplete_textfield.dart';

class EditOwnerInfoView extends GetView<PetEditController> {
  const EditOwnerInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    // Refresh address fields when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshAddressFields();
    });
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
                      const SizedBox(height: 24),
                      const AppText(
                        text: "Owner's Info",
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 32),

                      const AppText(
                        text: "Owner's Contact Number",
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hint: "Owner's Contact Number",
                        controller: controller.ownerContactController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      const AppText(
                        text: 'Street/ Door/ Apt Number',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 16),
                      AddressAutocompleteTextField(
                        mapsApiKey: 'AIzaSyBuWgYRQycmeaBRvBohDapMbEY-wZHre-U',
                        onSuggestionClick: controller.onSuggestionClick,
                        clearButton: const Icon(Icons.clear),
                        decoration: const InputDecoration(
                          hintText: 'Start typing an address...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            text: 'Address Details',
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
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
                                  text: 'Zip Code',
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  hint: 'Zip Code',
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
                      const SizedBox(height: 16),

                      const AppText(
                        text: 'City',
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.cityController,
                        isDropdown: false,
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
                              label: 'Save',
                              onPressed: () => controller.savePetProfile(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}