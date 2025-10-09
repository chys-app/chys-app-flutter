import 'package:chys/app/core/const/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/validators/form_validators.dart';
import '../controller/signup_controller.dart';
import '../widgets/custom_checkbox_tile.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class SignupView extends GetView<SignupController> {
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
                          const AppText(
                            text: "Join CHYS!",
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.black,
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
                            "Enter your pet’s details and your email to create an account",
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
                        text: "Full Name",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.nameController,
                        label: 'Full Name',
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
                        text: "Email",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: controller.emailController,
                        label: 'Email',
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        validator: FormValidators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Password",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        validator: FormValidators.validatePassword,
                        controller: controller.passwordController,
                        label: 'Password',
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        obscureText: !controller.showPassword.value,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showPassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.purple,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const AppText(
                        text: "Confirm Password",
                        fontWeight: FontWeight.w400,
                        color: AppColors.purple,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        obscureText: !controller.showConfirmPassword.value,
                        validator: (value) =>
                            FormValidators.validateConfirmPassword(
                          value,
                          controller.passwordController.text,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showConfirmPassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.purple,
                          ),
                          onPressed: controller.toggleConfirmPasswordVisibility,
                        ),
                        onChanged: (_) {
                          isFormvalid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                        controller: controller.confirmPasswordController,
                        label: 'Confirm Password',
                        fillColor: AppColors.cultured,
                        borderColor: AppColors.gunmetal,
                        filled: true,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 32),
                      CustomCheckboxTile(
                        value: controller.agreePolicy1.value,
                        onChanged: (v) => controller.agreePolicy1.value = v!,
                        text:
                            "I agree to the data processing policy of the service",
                        onTextTap: () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text('Data Processing Policy'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      text:
                                          'By creating an account, you consent to the collection, processing, and storage of your personal information in accordance with this Agreement and our Privacy Policy.\n\nWhat we collect:\n- Account information (email, username, password)\n- User-generated content\n- Device and usage data\n\nHow we use your data:\n- To create and manage your account\n- To provide personalized features and services\n- To improve system performance and user experience\n- To communicate with you regarding updates, promotions, or service-related matters\n\nWe do not sell your personal data to third parties. Data may be shared with third-party service providers solely for functionality, hosting, analytics, or customer support, and always under strict confidentiality obligations.',
                                      fontSize: 14,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      CustomCheckboxTile(
                        value: controller.agreePolicy2.value,
                        onChanged: (v) => controller.agreePolicy2.value = v!,
                        text: "I accept the End-User License Agreement",
                        onTextTap: () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text(
                                  'End-User License Agreement (EULA)'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      text:
                                          'We grant you a limited, revocable, non-exclusive, non-transferable, and non-sublicensable license to use the App solely for your personal, non-commercial use, in accordance with this Agreement.\n\nRestrictions:\n- You agree that you will not: Copy, modify, reverse-engineer, decompile, disassemble, or create derivative works from the App; Rent, lease, lend, sell, sublicense, or otherwise distribute the App to any third party; Use the App in any unlawful manner, for any unlawful purpose, or in any manner inconsistent with this Agreement; Introduce malicious code or compromise the App\'s functionality or security.\n\nThe App and all intellectual property rights therein are owned by Chys or its licensors. You are granted only a limited license to use the App, and no ownership or intellectual property rights are transferred to you under this Agreement.',
                                      fontSize: 14,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      CustomCheckboxTile(
                        value: controller.agreePolicy3.value,
                        onChanged: (v) => controller.agreePolicy3.value = v!,
                        text:
                            "I agree with the Policy on Child Safety Standards",
                        onTextTap: () {
                          Get.dialog(
                            AlertDialog(
                              title: const Text(
                                  'Policy on Child Safety Standards'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      text:
                                          'Chys is committed to maintaining a safe, respectful, and age-appropriate environment for all users.\n\nMinimum Age Requirement:\n- Chys is not intended for use by children under the age of 16. By creating an account, users confirm that they are at least 16 years of age. Users between 16 and 17 years of age may use Chys only with the consent and supervision of a parent or legal guardian. We do not knowingly collect personal information from children under 16. If we become aware that a child under 16 has provided personal data, we will take steps to delete the information and suspend or terminate the associated account.\n\nParental Supervision & Responsibility:\n- Parents and guardians are encouraged to monitor their child\'s use of Chys. We recommend that: Parents set privacy settings appropriately for minors; Children are educated on online safety and respectful behavior; Parents report any concerns to us immediately.\n\nContent Moderation:\n- Chys implements content moderation protocols to help prevent harmful, abusive, or inappropriate material from being shared on the platform. This includes: Flagging systems for inappropriate content; Regular content reviews by moderation staff or automated filters; Prompt response to user reports of abuse, harassment, or unsafe interactions.',
                                      fontSize: 14,
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
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
                                controller.handleSignup();
                              }
                            },
                            isEnabled: valid,
                            // isLoading: controller.isLoading.value,
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: () {
                          controller.loginWithGoogle();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                text: 'Signup With Google',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          controller.signInWithApple();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppText(
                                text: 'Signup With Apple',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                    color:
                                        AppColors.onBackground.withOpacity(0.7),
                                  ),
                              children: const [
                                TextSpan(
                                  text: "Log in!",
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
