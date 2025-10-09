import 'dart:developer';

import 'package:chys/app/services/common_service.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/payment_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../model/donation_model.dart';

class DonateController extends GetxController {
  var donations = <DonationModel>[].obs;
  var isLoading = false.obs;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  @override
  void onInit() {
    fetchDonations();
    super.onInit();
  }

  Future<void> updateDonation(String donationId) async {
    final amount = int.tryParse(amountController.text.trim());
    if (amount != null && amount <= 1) {
      CommonService.showError("The minimum donation amount is 1");
      return;
    }
    bool isPaid = await PaymentServices.stripePayment(
        amountController.text, donationId, Get.context!);
    log("Is paid $isPaid");
    if (isPaid) {
      fetchDonations();
      Get.back();
      Get.back();
    }
  }

  Future<void> fetchDonations() async {
    try {
      isLoading.value = true;
      final response = await ApiClient().get(ApiEndPoints.getDonations);
      final donationList = response['donations'];
      if (donationList != null && donationList is List) {
        donations.value = donationList
            .where((e) => e['isActive'] == true)
            .map((e) => DonationModel.fromJson(e))
            .toList();
      } else {
        donations.value = [];
      }
    } catch (e) {
      log("The error during fetching donation is $e");
    } finally {
      isLoading.value = false;
    }
  }
}
