import 'dart:developer';
import 'dart:io';

import 'package:chys/app/services/http_service.dart';
import 'package:chys/app/services/payment_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/const/app_colors.dart';
import '../../core/controllers/loading_controller.dart';
import '../../services/custom_Api.dart';
import '../../services/short_message_utils.dart';
import 'widget/instagram_story_editor.dart';

class BusinessHomeController extends GetxController {
  // Add logic later
  final CustomApiService _apiService = Get.put(CustomApiService());
  final selectedMedia = Rxn<File>();
  final TextEditingController amountController = TextEditingController();
  final isLoading = false.obs;

  Future<File> convertUint8ListToFile(Uint8List data, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(data);
    return file;
  }



  Future<void> pickMedia({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? media = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (media != null) {
        // Show the Instagram-like story editor
        await Navigator.of(Get.context!).push(
          MaterialPageRoute(
            builder: (context) => InstagramStoryEditor(
              imageFile: File(media.path),
              onSave: (File editedImage) {
                selectedMedia.value = editedImage;
                Navigator.of(context).pop();
                // Automatically upload the story after editing
                uploadStory();
              },
              onCancel: () {
                selectedMedia.value = null;
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      log("Failed $e");
      ShortMessageUtils.showError('Failed to pick or edit media');
    }
  }


  Future<void> uploadStory() async {
    if (selectedMedia.value == null) {
      ShortMessageUtils.showError('Please select a media file');
      return;
    }

    try {
      isLoading.value = true;
      Get.find<LoadingController>().show();

      final result = await _apiService.uploadStory(
        mediaFile: selectedMedia.value!,
        caption: '', // Keep existing API structure
      );

      if (result['success'] == true) {
        await ShortMessageUtils.showSuccess("Story uploaded successfully!");
        selectedMedia.value = null;
      } else {
        ShortMessageUtils.showError(
            result['message'] ?? 'Failed to upload story');
      }
    } catch (e) {
      log("Upload error $e");
      await ShortMessageUtils.showError('Failed to upload story');
    } finally {
      isLoading.value = false;
      Get.find<LoadingController>().hide();
    }
  }


  Future<void> fundRaise(String postId, BuildContext context) async {
    final amount = int.tryParse(amountController.text.trim());
    if (amount != null && amount <= 1) {
      ShortMessageUtils.showError("The minimum fundraising  is 1");
      return;
    }
    try {
      Get.find<LoadingController>().show();
      PaymentServices.stripePayment(
          amountController.text.trim(), "dummy_donationId", context,
          onSuccess: () async {
        await ApiClient().post("${ApiEndPoints.fundRaise}/post/$postId", {
          "amount": amountController.text.trim(),
        });
      });
      Get.find<LoadingController>().hide();
      Get.back();
    } catch (e) {
      Get.find<LoadingController>().hide();
      log("The error is $e");
    }
  }

  @override
  void onClose() {
    // captionController.dispose(); // This line is removed
    super.onClose();
  }
}
