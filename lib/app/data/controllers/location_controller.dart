import 'dart:developer';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../models/user_location_model.dart';

class LocationController extends GetxController {
  RxDouble latitude = 0.0.obs;
  RxDouble longitude = 0.0.obs;

  Rxn<UserLocationModel> locationData = Rxn<UserLocationModel>();

  @override
  void onInit() {
    super.onInit();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    await Future.delayed(const Duration(seconds: 5));
    log("Attempting to get location...");
    bool serviceEnabled;
    LocationPermission permission;

    // Location services check
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Error", "Location services are disabled.");
      return;
    }

    // Permission check
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Permission Denied", "Location permission is denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Permission Denied", "Permissions are permanently denied.");
      return;
    }

    // Get location
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    latitude.value = position.latitude;
    longitude.value = position.longitude;

    log("Latitude: ${latitude.value}, Longitude: ${longitude.value}");

    // Fetch address
    await _getAddressDetails();
  }

  Future<void> _getAddressDetails() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude.value,
        longitude.value,
      );

      if (placemarks.isNotEmpty) {
        locationData.value = UserLocationModel.fromPlacemark(placemarks.first);
        log("Location Model Updated: ${locationData.value}");
      } else {
        Get.snackbar("Error", "No address found");
      }
    } catch (e) {
      log("Error getting address: $e");
      Get.snackbar("Error", "Failed to get address.");
    }
  }
}
