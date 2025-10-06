import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/const/app_text.dart';
import '../../data/controllers/location_controller.dart';

class AddressFromCoordinates extends StatelessWidget {
  const AddressFromCoordinates({super.key});

  @override
  Widget build(BuildContext context) {
    final LocationController locationController =
        Get.find<LocationController>();

    return Obx(() {
      final location = locationController.locationData.value;

      if (location == null) {
        return const AppText(text: "Fetching address...");
      }

      return AppText(
        text:
            "${location.street}, ${location.city}, ${location.state}, ${location.country}, ${location.zipCode}",
      );
    });
  }
}
