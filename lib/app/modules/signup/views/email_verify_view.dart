import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_text.dart';
import '../controller/signup_controller.dart';
import '../widgets/primary_button.dart';

class EmailVerificationScreen extends StatelessWidget {
  final signupController = Get.find<SignupController>();
  EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.arrow_back)),
              ),
              // Header
              const SizedBox(height: 24),

              Text(
                "Email Verification",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Message
              AppText(
                text:
                    "We’ve sent a verification link to your email. Please click the ‘Verify’ button after verifying your email, or tap ‘Retry’ if you haven’t received it yet.",
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800]!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Verify Button
              PrimaryButton(
                label: "I've Verified",
                onPressed: () {
                  signupController.verifyUsingEmail();
                },
              ),
              const SizedBox(height: 16),

              // Retry Button
              PrimaryButton(
                label: "Resend Email",
                backgroundColor: Colors.grey[600],
                onPressed: () {
                  signupController.resendEmail();
                },
              ),

              const Spacer(),

              // Optional Footer Text
              const AppText(
                text: "Didn’t receive the email? Check your spam folder.",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
