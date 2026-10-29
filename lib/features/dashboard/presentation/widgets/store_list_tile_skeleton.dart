import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_widget.dart';

class StoreListTileSkeleton extends StatelessWidget {
  const StoreListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          // Store Logo Box
          ShimmerWidget(
            width: 52,
            height: 52,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          SizedBox(width: 14),

          // Store Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 140,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 8),
                ShimmerWidget(
                  width: 190,
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerWidget(
                      width: 55,
                      height: 20,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    SizedBox(width: 10),
                    ShimmerWidget(
                      width: 75,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),

          // Trailing Chevron Indicator
          ShimmerWidget(
            width: 14,
            height: 14,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}
