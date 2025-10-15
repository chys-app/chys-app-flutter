import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/modules/donate/controller/donate_controller.dart';
import 'package:chys/app/modules/donate/model/donation_model.dart';
import 'package:chys/app/widget/image/image_extension.dart';
import 'package:chys/app/widget/shimmer/compain_item_shimmer.dart';
import 'package:chys/app/widget/shimmer/lottie_animation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class DonateView extends StatelessWidget {
  final controller = Get.find<DonateController>();
  DonateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const AppText(
          text: 'Donate',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const CompainItemShimmer();
          } else if (controller.donations.isEmpty) {
            return const Center(
              child: CustomLottieAnimation(),
            );
          } else {
            return GridView.builder(
              itemCount: controller.donations.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                return Obx(() {
                  final data = controller.donations[index];
                  return _campaignItem(data);
                });
              },
            );
          }
        }),
      ),
    );
  }

  Widget _campaignItem(DonationModel donation) {
    double progress = 0;
    if ((donation.targetAmount ?? 0) > 0) {
      progress = (donation.collectedAmount ?? 0) / donation.targetAmount!;
      if (progress > 1) progress = 1;
    }
    return InkWell(
      onTap: () {
        Get.toNamed(AppRoutes.donateDetail, arguments: donation);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dummy image placeholder
            donation.image!.toNetworkImage(),
            const SizedBox(height: 10),
            Text(
              donation.title ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Collected ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "\$${donation.collectedAmount!.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
