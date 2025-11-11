import 'package:chys/app/core/const/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controller/signup_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class BusinessSignupView extends GetView<SignupController> {
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormvalid = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(
          () => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: AppColors.gunmetal),
                                onPressed: () => Get.back(),
                              ),
                              const AppText(
                                text: "Join CHYS Business!",
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline,
                                color: AppColors.gunmetal),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const AppText(
                        text:
                            "Enter your business details to create an account.",
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: AppColors.purple,
                      ),
                      // const SizedBox(height: 32),
                      // AppText(
                      //   text: "Email",
                      //   fontWeight: FontWeight.w400,
                      //   color: AppColors.purple,
                      //   fontSize: 14,
                      // ),
                      //  SizedBox(height: 10),
                      //
                      // CustomTextField(
                      //   controller: controller.usernameController,
                      //   label: 'Username',
                      //   fillColor: AppColors.cultured,
                      //   borderColor: AppColors.gunmetal,
                      //   filled: true,
                      //   keyboardType: TextInputType.text,
                      //   textInputAction: TextInputAction.next,
                      // ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Business Name",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.nameController,
                        label: 'Business Name',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Tax ID",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.taxIdController,
                        label: 'Tax ID',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Contact Name",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.contactNameController,
                        label: 'Contact Name',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Phone Number",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.phoneController,
                        label: 'Phone Number',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Street Address",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.streetController,
                        label: 'Street Address',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.streetAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "State",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.stateController,
                        label: 'State',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Zip Code",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.zipCodeController,
                        label: 'Zip Code',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 32),
                      ValueListenableBuilder<bool>(
                        valueListenable: isFormvalid,
                        builder: (context, valid, _) {
                          return PrimaryButton(
                            backgroundColor: AppColors.blue,
                            label: "Sign Up",
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                controller.handleBusinessSignup();
                              }
                            },
                            isEnabled: valid,
                            // isLoading: controller.isLoading.value,
                          );
                        },
                      ),
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
