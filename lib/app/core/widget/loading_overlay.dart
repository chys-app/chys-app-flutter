import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  const LoadingOverlay({Key? key, required this.isLoading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    return Stack(
      children: [
        // Transparent barrier
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.2), // Slight dim, adjust as needed
          ),
        ),
        // Centered Lottie animation
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Lottie.asset(
              'assets/json/loading.json',
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
} 