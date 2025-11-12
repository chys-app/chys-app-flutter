import 'package:chys/app/core/const/app_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/const/app_colors.dart';

class ShortMessageUtils {
  static Future<void> showSuccess(String message) async {
    await Future.delayed(const Duration(milliseconds: 50));

    Get.snackbar(
      '',
      message,
      icon: const Icon(Icons.check_circle_outline, color: AppColors.secondary),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.blue,
      borderRadius: 20,
      margin: const EdgeInsets.all(15),
      colorText: AppColors.secondary,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      animationDuration: const Duration(milliseconds: 800),
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        const BoxShadow(
          color: Colors.black45,
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
      titleText: const AppText(
        text: 'Success!',
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.start,
      ),
      messageText: AppText(
        text: message,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.start,
        maxLines: 3,
      ),
    );
  }

  static Future<void> showError(String message) async {
    await Future.delayed(const Duration(milliseconds: 50));

    Get.snackbar(
      '',
      message,
      icon: const Icon(Icons.error_outline, color: AppColors.secondary),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      borderRadius: 20,
      margin: const EdgeInsets.all(15),
      colorText: AppColors.secondary,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeInCirc,
      animationDuration: const Duration(milliseconds: 800),
      snackStyle: SnackStyle.FLOATING,
      boxShadows: [
        const BoxShadow(
          color: Colors.black45,
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
      titleText: const AppText(
        text: 'Error!',
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        textAlign: TextAlign.start,
      ),
      messageText: AppText(
        text: message,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        textAlign: TextAlign.start,
        maxLines: 3,
      ),
    );
  }
}
