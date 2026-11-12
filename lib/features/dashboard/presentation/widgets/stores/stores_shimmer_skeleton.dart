import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_list_tile_skeleton.dart';

/// Structural Bento loading skeleton matching `StoresView` (`StoresHeaderBanner` +
/// `StoresSummaryBentoCard` + filter strip + store scorecard list).
class StoresShimmerSkeleton extends StatelessWidget {
  const StoresShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget(
                        width: 120,
                        height: 24,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      SizedBox(height: 6),
                      ShimmerWidget(
                        width: 145,
                        height: 13,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Row(
                  children: [
                    ShimmerWidget(
                      width: 72,
                      height: 36,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    SizedBox(width: 6),
                    ShimmerWidget(
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Bento card skeleton
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: TuLojitaBrandColors.borderSubtle,
                  width: 1.5,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerWidget(
                        width: 90,
                        height: 12,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      ShimmerWidget(
                        width: 56,
                        height: 18,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ShimmerWidget(
                    width: 150,
                    height: 28,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  SizedBox(height: 8),
                  ShimmerWidget(
                    width: 110,
                    height: 13,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerWidget(
                        width: 70,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      ShimmerWidget(
                        width: 70,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      ShimmerWidget(
                        width: 70,
                        height: 32,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter pills skeleton
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  ShimmerWidget(
                    width: 82,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  SizedBox(width: 8),
                  ShimmerWidget(
                    width: 115,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  SizedBox(width: 8),
                  ShimmerWidget(
                    width: 88,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const StoreListTileSkeleton(),
            const StoreListTileSkeleton(),
          ],
        ),
      ),
    );
  }
}
