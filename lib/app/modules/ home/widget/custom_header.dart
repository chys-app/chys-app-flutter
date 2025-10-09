import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

Widget buildCustomHeader() {
  final mapController = Get.find<MapController>();
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Enhanced logo with blue border
      InkWell(
        onTap: () => Get.toNamed(AppRoutes.profile),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            // color: const Color(0xFF0095F6),
            borderRadius: BorderRadius.circular(25),

          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                AppImages.logo,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
      
      // Clean action buttons without background
      Row(
        children: [
          _buildCleanIconButton(
            icon: Icons.settings,
            onTap: mapController.onSettingsTap,
          ),
          const SizedBox(width: 16),
          _buildCleanIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: mapController.onNotificationsTap,
          ),
        ],
      ),
    ],
  );
}

Widget _buildPodcastButton() {
  return GestureDetector(
    onTap: () => Get.toNamed(AppRoutes.invitePodcast),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0095F6),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0095F6).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Podcast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildCleanIconButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      child: Icon(
        icon,
        size: 28,
        color: Colors.black,
      ),
    ),
  );
}

Widget _buildEnhancedIconButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 22,
        color: const Color(0xFF262626),
      ),
    ),
  );
}

Widget _buildIconButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Icon(
      icon,
      size: 24,
      color: const Color(0xFF262626),
    ),
  );
}
