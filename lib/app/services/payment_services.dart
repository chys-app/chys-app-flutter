import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chys/app/core/const/app_secrets.dart';
import 'package:chys/app/services/common_service.dart';
import 'package:flutter/material.dart';
 
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/controllers/loading_controller.dart';
import 'http_service.dart';

class PaymentServices {
  static Future<bool> stripePayment(
    String amount,
    String donationId,
    BuildContext context, {
    VoidCallback? onSuccess,
  }) async {
    try {
      Get.find<LoadingController>().show();

      final publishableKey = AppSecrets.publishableKey;
      if (publishableKey.isEmpty) {
        log('Stripe publishable key is missing');
        CommonService.showError('Payment configuration error.');
        return false;
      }

      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();

      final price = (double.parse(amount) * 100).toInt();
      log("Price in cents: $price");

      // Step 1: Create Payment Intent
      Get.find<LoadingController>().show();
      Map<String, dynamic>? paymentIntent = await _createPaymentIntent(price);
      log("Payment intent is $paymentIntent");

      if (paymentIntent == null) {
        Get.find<LoadingController>().hide();
        CommonService.showError("Failed to create payment intent");
        return false;
      }

      // Step 2: Initialize payment sheet
      Get.find<LoadingController>().show();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          style: ThemeMode.system,
          merchantDisplayName: 'Chys',
        ),
      );

      Get.find<LoadingController>().hide(); // Dismiss before showing payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Step 3: Handle successful payment
      String transactionId = paymentIntent['id'];
      log("Transaction id is $transactionId");
      if (onSuccess != null) {
        onSuccess();
      } else {
        await updateDonation(amount, donationId);
      }
      return true;
    } catch (e) {
      Get.find<LoadingController>().hide();
      if (e is StripeException) {
        log("StripeException: ${e.error.localizedMessage}");
        CommonService.showError("Payment error: ${e.error.localizedMessage}");
      } else if (e is SocketException) {
        CommonService.showError("Network issue, please check your connection.");
      } else {
        log("Error is $e");
        CommonService.showError("An error occurred: $e");
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>?> _createPaymentIntent(
    int price,
  ) async {
    try {
      Map<String, dynamic> body = {
        "amount": price.toString(),
        "currency": "USD",
      };

      final secretKey = AppSecrets.secretKey;
      if (secretKey.isEmpty) {
        log('Stripe secret key is missing');
        return null;
      }

      var response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        headers: {
          "Authorization": "Bearer $secretKey",
          "Content-type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log("Failed to create payment intent. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("Error creating payment intent: $e");
      return null;
    }
  }

  static Future<void> updateDonation(String amount, String donationId) async {
    try {
      final response = await ApiClient().post(ApiEndPoints.updateDonation,
          {"amount": int.tryParse(amount), "donationId": donationId});
      log("Response of the donation update id $response");
    } catch (e) {
      log("The error during updating donation is $e");
    }
  }
}
