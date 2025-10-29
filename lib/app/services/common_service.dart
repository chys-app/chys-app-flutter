import 'dart:developer';

import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class CommonService {
  static String kgToLbs(num kg) {
    double lbs = kg * 2.20462;
    return lbs.toStringAsFixed(1); // or use toStringAsFixed(1) for one decimal
  }

  static String formatRemainingTime(DateTime scheduledAt) {
    final now = DateTime.now().toUtc();
    final difference = scheduledAt.difference(now);

    if (difference.isNegative) return "Starting soon";

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) return "Starts in ${days}d ${hours}h";
    if (hours > 0) return "Starts in ${hours}h ${minutes}m";
    if (minutes > 0) return "Starts in ${minutes}m";
    return "Starting now";
  }

  static bool canJoinPodcast({
    required String hostId,
    required String status,
    required DateTime scheduledAt,
  }) {
    String? userId = Get.find<ProfileController>().profile.value?.id;
    final now = DateTime.now().toUtc();

    log("userid is $userId and host id is $hostId and status is $status and scheduled at is $scheduledAt and now is $now");
    if (hostId == userId && status.toLowerCase() != 'ended') return true;
    if (status.toLowerCase() == 'live') {
      return true;
    } else if (status.toLowerCase() == 'ended') {
      showError("The host has ended the podcast");
      return false;
    } else if (status.toLowerCase() == 'scheduled') {
      if (scheduledAt.isBefore(now)) {
        showError("The host has not started the podcast yet.");
      } else {
        showError("You cannot join until the podcast goes live.");
      }
    } else {
      showError("You are not allowed to join this podcast.");
    }

    return false;
  }

  static void showError(String message) {
    Get.snackbar(
      "Access Denied",
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  static Future<void> launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $email';
    }
  }
}
