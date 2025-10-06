import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/widget/image/image_extension.dart';
import 'package:flutter/material.dart';

import '../../core/widget/app_button.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

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
          text: 'Subscriptions',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: AppSize.h2,
            children: [
              const AppText(
                text: "Go Premium",
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              const AppText(
                text: "Be the voice for all animals phase",
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              AppImages.discount.toImage(),
              customRow("Create Fundraising Events"),
              customRow("Donation - Tips"),
              customRow("Unlock Monetization"),
              customRow("Pro support from our team"),
              customRow("Free commercials"),
              Row(
                spacing: AppSize.h2,
                children: [
                  customContainer("Daily", "19/Day"),
                  customContainer("Weekly", "59/Week"),
                ],
              ),
              Row(
                spacing: AppSize.h2,
                children: [
                  customContainer("Monthly", "99/Month"),
                  customContainer("Yearly", "999/Year"),
                ],
              ),
              const AppText(
                text:
                    "By subscribing, you agree to the Terms of Service and Privacy Policy. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.",
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
              Row(
                children: [
                  Expanded(
                    child: Appbutton(
                      borderRadius: 16,
                      textColor: AppColors.secondary,
                      backgroundColor: AppColors.blue,
                      label: "Subscribe",
                      borderColor: Colors.transparent,
                      // onPressed: () => controller.submitPost(),
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
      ),
    );
  }

  Widget customRow(String text) {
    return Row(
      spacing: AppSize.h2,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          Icons.check,
          color: AppColors.blue,
        ),
        AppText(
          text: text,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget customContainer(String title, String subtitle) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0927650D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AppText(
            text: title,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          AppText(
            text: "\$$subtitle",
            fontSize: 14,
            fontWeight: FontWeight.w500,
          )
        ],
      ),
    ));
  }
}
