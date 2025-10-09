import 'package:chys/app/core/const/app_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLottieAnimation extends StatelessWidget {
  final String? jsonPath;
  final double? height;
  final double? width;
  final bool repeat;

  const CustomLottieAnimation({
    super.key,
    this.jsonPath,
    this.height,
    this.width,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    final String finalPath = (jsonPath == null || jsonPath!.trim().isEmpty)
        ? AppImages.empty
        : jsonPath!;

    return FutureBuilder<LottieComposition>(
      future: AssetLottie(
        finalPath,
      ).load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Malformed JSON or missing asset fallback
          return Lottie.asset(
            AppImages.empty, // fallback animation
            height: height,
            width: width,
            repeat: repeat,
            fit: BoxFit.contain,
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(); // or a shimmer loader
        }

        return Lottie(
          composition: snapshot.data!,
          height: height,
          width: width,
          repeat: repeat,
          fit: BoxFit.contain,
        );
      },
    );
  }
}
