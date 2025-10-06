import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validators/form_validators.dart';
import '../../../routes/app_routes.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../../signup/widgets/primary_button.dart';
import '../controllers/reset_password_controller.dart';

class ForgetPasswordView extends StatefulWidget {
  @override
  State<ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<ForgetPasswordView> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isFormValid = false;
  final resetPasswordController = Get.put(ResetPasswordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.purple),
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
                  text: "Forgot Password",
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                ),
                const SizedBox(height: 8),
                const AppText(
                  text: "Enter your email to receive an OTP.",
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: AppColors.purple,
                ),
                const SizedBox(height: 32),
                const AppText(
                  text: "Email",
                  fontWeight: FontWeight.w400,
                  color: AppColors.purple,
                  fontSize: 14,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: emailController,
                  label: 'Email',
                  fillColor: AppColors.cultured,
                  borderColor: AppColors.gunmetal,
                  filled: true,
                  validator: FormValidators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
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
                  label: "Send OTP",
                  isEnabled: isFormValid,
                  onPressed: isFormValid
                      ? () async {
                          if (formKey.currentState?.validate() ?? false) {
                            resetPasswordController.email.value = emailController.text.trim();
                            await resetPasswordController.sendOtp();
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
