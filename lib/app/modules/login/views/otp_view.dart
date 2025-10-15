import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../signup/widgets/primary_button.dart';
import '../controllers/reset_password_controller.dart';

class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final otpController = TextEditingController();
  String? email;
  bool isOtpValid = false;
  final resetPasswordController = Get.put(ResetPasswordController());

  @override
  void initState() {
    super.initState();
    email = Get.arguments?['email'] ?? '';
    resetPasswordController.email.value = email ?? '';
  }

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
                color: AppColors.purple,
              ),
              const SizedBox(height: 32),
              Pinput(
                controller: otpController,
                length: 6,
                onChanged: (value) {
                  setState(() {
                    isOtpValid = value.length == 6;
                  });
                },
                defaultPinTheme: PinTheme(
                  width: 48,
                  height: 56,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cultured,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.gunmetal.withOpacity(0.3)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                backgroundColor: AppColors.blue,
                label: "Verify OTP",
                isEnabled: isOtpValid,
                onPressed: isOtpValid
                    ? () async {
                        resetPasswordController.otp.value = otpController.text;
                        await resetPasswordController.verifyOtp();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
