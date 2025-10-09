import 'dart:developer';

import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/short_message_utils.dart';
import 'package:flutter/material.dart';
 
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class ResetPasswordController extends GetxController {
  final email = ''.obs;
  final otp = ''.obs;
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    email.value = Get.arguments?['email'] ?? '';
    otp.value = Get.arguments?['otp'] ?? '';
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void resetPassword() {
    final emailVal = email.value;
    final passwordVal = newPasswordController.text;
    print('Email: $emailVal, Password: $passwordVal');
    // Add actual reset logic here
  }

  Future<void> sendOtp() async {
    try {
      if (email.value.isEmpty) {
        ShortMessageUtils.showError("Please enter your email");
        return;
      }
      Get.find<LoadingController>().show();
      final response = await ApiClient().post(
        ApiEndPoints.sendOtp,
        {"email": email.value},
      );
      log("Response is $response");
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showSuccess("OTP sent!");
      Get.toNamed(AppRoutes.otp, arguments: {'email': email.value});
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Error sending OTP');
    }
  }

  Future<void> verifyOtp() async {
    try {
      if (email.value.isEmpty || otp.value.isEmpty) {
        ShortMessageUtils.showError("Email and OTP required");
        return;
      }
      Get.find<LoadingController>().show();
      final response = await ApiClient().post(
        ApiEndPoints.verifyOtp,
        {"email": email.value, "otp": otp.value},
      );
      Get.find<LoadingController>().hide();

      ShortMessageUtils.showSuccess("OTP verified!");
      Get.toNamed(AppRoutes.resetPassword,
          arguments: {'email': email.value, 'otp': otp.value});
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Error verifying OTP');
    }
  }

  Future<void> resendOtp() async {
    try {
      if (email.value.isEmpty) {
        ShortMessageUtils.showError('Please enter your email');
        return;
      }
      Get.find<LoadingController>().show();
      final response = await ApiClient().post(
        ApiEndPoints.sendOtp,
        {"email": email.value},
      );
      Get.find<LoadingController>().hide();

      ShortMessageUtils.showSuccess('OTP resent!');
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Error resending OTP');
    }
  }

  Future<void> changePassword() async {
    try {
      if (email.value.isEmpty || newPasswordController.text.isEmpty) {
        ShortMessageUtils.showError('Email and new password required');
        return;
      }
      Get.find<LoadingController>().show();
      final response = await ApiClient().post(
        ApiEndPoints.resetPassword,
        {
          "email": email.value,
          "newPassword": newPasswordController.text,
        },
      );
      Get.find<LoadingController>().hide();

      ShortMessageUtils.showSuccess("Password changed!");
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.find<LoadingController>().hide();
      ShortMessageUtils.showError('Error changing password');
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
