import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CatQuoteCardShimmer extends StatelessWidget {
  const CatQuoteCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.grey[300],
      ),
      child: Stack(
        children: [
          // Shimmer background
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.grey[300],
                width: double.infinity,
                height: 400,
              ),
            ),
          ),

          // Gradient overlay

          // Text shimmer
          Positioned(
            left: 20,
            right: 80,
            bottom: 80,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 60,
                color: Colors.grey[300],
              ),
            ),
          ),

          // User info shimmer
          Positioned(
            left: 20,
            bottom: 20,
            child: Row(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmerBox(width: 100, height: 12),
                    const SizedBox(height: 5),
                    shimmerBox(width: 60, height: 10),
                  ],
                )
              ],
            ),
          ),

          // Right floating icons shimmer
          Positioned(
            right: 10,
            top: 10,
            child: Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget shimmerBox({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey,
      ),
    );
  }
}
