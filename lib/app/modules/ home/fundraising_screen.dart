import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/data/models/post.dart';
import 'package:chys/app/modules/%20home/home_controller.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:chys/app/widget/image/svg_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/const/app_colors.dart';
import '../../core/utils/app_size.dart';
import '../../core/widget/app_button.dart';

class FundraisingScreen extends StatelessWidget {
  final controller = Get.find<HomeController>();
  FundraisingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments as Posts;
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
          text: 'Fund arise',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(child: AppImages.love.toSvg(color: Colors.red)),
            const SizedBox(height: 16),
            Center(
              child: AppText(
                text: 'Your generosity can make a difference!',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 16),
            AppText(
              text: argument.description,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            AppText(
              text: argument.description,
              fontSize: 13,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      text: "Enter the amount you wish to contribute",
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      keyboardType: TextInputType.number,
                      label: "Enter amount",
                      controller: controller.amountController,
                    ),
                    const SizedBox(height: 8),
                    const AppText(
                      text:
                          "Your contribution helps us reach more people and do more impactful work",
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Appbutton(
                    borderRadius: 16,
                    textColor: AppColors.secondary,
                    backgroundColor: AppColors.blue,
                    label: "Contribute Now",
                    borderColor: Colors.transparent,
                    onPressed: () {
                      controller.fundRaise(argument.id, context);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(
              height: AppSize.h2,
            )
          ],
        ),
      ),
    );
  }
}
