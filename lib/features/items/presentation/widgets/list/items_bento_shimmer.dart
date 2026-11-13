import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import '../detail/item_detail_helpers.dart';

class ItemsBentoGridShimmer extends StatelessWidget {
  const ItemsBentoGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildCardSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildCardSkeleton()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      decoration: itemBentoCardDecoration(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: double.infinity,
            height: 110,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 80,
                  height: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                ShimmerWidget(
                  width: double.infinity,
                  height: 13,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                ShimmerWidget(
                  width: 90,
                  height: 13,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: TuLojitaBrandColors.borderMuted,
                ),
                const SizedBox(height: 8),
                ShimmerWidget(
                  width: 70,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
