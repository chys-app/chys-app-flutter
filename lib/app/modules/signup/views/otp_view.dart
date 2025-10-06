import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/modules/signup/controller/signup_controller.dart';
import 'package:chys/app/modules/signup/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../core/const/app_text.dart';

class VerifyOtpScreen extends StatelessWidget {
  const VerifyOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SignupController>();
    final email = Get.arguments?['isSignup'] ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const AppText(
                text: "Enter OTP",
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black,
              ),
              const SizedBox(height: 8),
              AppText(
                text: "OTP sent to $email",
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
              const SizedBox(height: 32),
              Pinput(
                controller: controller.otpController,
                length: 6,
                defaultPinTheme: PinTheme(
                    width: 48,
                    height: 56,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                        border: Border(
                      bottom: BorderSide(
                        color: AppColors.blue,
                        width: 2,
                      ),
                    ))),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                backgroundColor: AppColors.blue,
                label: "Verify OTP",
                onPressed: () async {
                  await controller.verifyOtp(email);
                },
              ),
              const SizedBox(height: 16),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.canResendOtp.value ? AppColors.blue : AppColors.blue.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: controller.canResendOtp.value
                      ? () async {
                          await controller.resendOtp(isSignup: email);
                        }
                      : null,
                  child: controller.canResendOtp.value
                      ? const Text("Resend OTP")
                      : Text("Resend in ${controller.otpSecondsRemaining.value}s"),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
