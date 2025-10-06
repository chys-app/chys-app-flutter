import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostPreviewShimmer extends StatelessWidget {
  const PostPreviewShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar shimmer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      shimmerCircle(size: 36),
                      const SizedBox(width: 12),
                      shimmerCircle(size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            shimmerBox(width: 100, height: 16),
                            const SizedBox(height: 6),
                            shimmerBox(width: 60, height: 12),
                          ],
                        ),
                      ),
                      shimmerBox(width: 80, height: 28, radius: 16),
                    ],
                  ),
                ),
                // Media shimmer
                Expanded(
                  child: Center(
                    child: shimmerBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.height * 0.35,
                      radius: 16,
                    ),
                  ),
                ),
                // Bottom content shimmer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description shimmer
                      shimmerBox(width: double.infinity, height: 18),
                      const SizedBox(height: 8),
                      shimmerBox(width: double.infinity, height: 18),
                      const SizedBox(height: 8),
                      shimmerBox(width: 180, height: 18),
                      const SizedBox(height: 16),
                      // Stats shimmer
                      Row(
                        children: [
                          shimmerIcon(),
                          const SizedBox(width: 8),
                          shimmerBox(width: 40, height: 12),
                          const SizedBox(width: 24),
                          shimmerIcon(),
                          const SizedBox(width: 8),
                          shimmerBox(width: 40, height: 12),
                          const SizedBox(width: 24),
                          shimmerIcon(),
                          const SizedBox(width: 8),
                          shimmerBox(width: 40, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Action buttons shimmer
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  shimmerCircle(size: 48),
                  const SizedBox(height: 8),
                  shimmerBox(width: 32, height: 16),
                  const SizedBox(height: 16),
                  shimmerCircle(size: 48),
                  const SizedBox(height: 8),
                  shimmerBox(width: 32, height: 16),
                  const SizedBox(height: 16),
                  shimmerCircle(size: 48),
                  const SizedBox(height: 16),
                  shimmerCircle(size: 48),
                  const SizedBox(height: 8),
                  shimmerBox(width: 32, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget shimmerBox({double width = 100, double height = 16, double radius = 8}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget shimmerCircle({double size = 32}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget shimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
      ),
    );
  }
} 