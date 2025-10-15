import 'package:chys/app/services/common_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validators/form_validators.dart';
import '../../../routes/app_routes.dart';
import '../../signup/widgets/primary_button.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isFormValid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // Ensure LoginController is available
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      builder: (controller) {
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
                        const SizedBox(
                          height: 50,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText(
                              text: "Welcome Back!",
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.black,
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline),
                              onPressed: () {
                                CommonService.launchEmail("support@chys.app");
                              },
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerRight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const AppText(
                          text: "Login to your account",
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
                        LoginTextField(
                          controller: controller.emailController,
                          label: 'Email',
                          onChanged: (value) {
                            controller.emailText = value;
                            isFormValid.value =
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
                        LoginTextField(
                          controller: controller.passwordController,
                          label: 'Password',
                          onChanged: (value) {
                            controller.passwordText = value;
                            isFormValid.value =
                                formKey.currentState?.validate() ?? false;
                          },
                          fillColor: AppColors.cultured,
                          borderColor: AppColors.gunmetal,
                          filled: true,
                          obscureText: !controller.showPassword.value,
                          validator: FormValidators.validatePassword,
                          textInputAction: TextInputAction.done,
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Get.toNamed(AppRoutes.forgetPassword);
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ValueListenableBuilder<bool>(
                          valueListenable: isFormValid,
                          builder: (context, valid, _) {
                            return PrimaryButton(
                              backgroundColor: AppColors.blue,
                              label: "Login",
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  controller.handleLogin();
                                }
                              },
                              isEnabled: valid,
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
                                  text: 'Login With Google',
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
                                  text: 'Login With Apple',
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
                            onTap: controller.navigateToSignup,
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color:
                                          AppColors.onBackground.withOpacity(0.7),
                                    ),
                                children: const [
                                  TextSpan(
                                    text: "Sign up!",
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
