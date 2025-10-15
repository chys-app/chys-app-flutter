import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../../signup/widgets/primary_button.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final formKey = GlobalKey<FormState>();
  final controller = Get.put(ResetPasswordController());
  bool isFormValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.purple),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const AppText(
                  text: "Reset Password",
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                ),
                const SizedBox(height: 32),
                const AppText(
                  text: "New Password",
                  fontWeight: FontWeight.w400,
                  color: AppColors.purple,
                  fontSize: 14,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: controller.newPasswordController,
                  label: 'New Password',
                  fillColor: AppColors.cultured,
                  borderColor: AppColors.gunmetal,
                  filled: true,
                  obscureText: true,
                  validator: controller.validatePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    setState(() {
                      isFormValid = formKey.currentState?.validate() ?? false;
                    });
                  },
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
                  controller: controller.confirmPasswordController,
                  label: 'Confirm Password',
                  fillColor: AppColors.cultured,
                  borderColor: AppColors.gunmetal,
                  filled: true,
                  obscureText: true,
                  validator: controller.validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    setState(() {
                      isFormValid = formKey.currentState?.validate() ?? false;
                    });
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  backgroundColor: AppColors.blue,
                  label: "Reset Password",
                  isEnabled: isFormValid,
                  onPressed: isFormValid
                      ? () async {
                          if (formKey.currentState?.validate() ?? false) {
                            await controller.changePassword();
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
