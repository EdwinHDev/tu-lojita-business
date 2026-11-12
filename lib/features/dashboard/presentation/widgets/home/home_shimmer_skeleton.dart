import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';

/// Structural Bento loading skeleton matching the Home KPI carousel,
/// horizontal operational shortcuts strip, and sales chart card.
class HomeShimmerSkeleton extends StatelessWidget {
  const HomeShimmerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Bento KPI Carousel / Grid Skeleton
            if (isWide)
              Row(
                children: const [
                  Expanded(child: _KpiSlideSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: _KpiSlideSkeleton()),
                ],
              )
            else
              Row(
                children: [
                  Expanded(flex: 9, child: const _KpiSlideSkeleton()),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 1,
                    child: ShimmerWidget(
                      width: double.infinity,
                      height: 210,
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 18),

            // 2. Horizontal Operational Shortcuts Strip Skeleton
            const ShimmerWidget(
              width: 130,
              height: 16,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, _) => Container(
                  width: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: TuLojitaBrandColors.borderSubtle,
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerWidget(
                        width: 36,
                        height: 36,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      SizedBox(height: 8),
                      ShimmerWidget(
                        width: 58,
                        height: 11,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Sales Chart Bento Card Skeleton
            Container(
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
                        width: 140,
                        height: 18,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      ShimmerWidget(
                        width: 96,
                        height: 28,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  ShimmerWidget(
                    width: double.infinity,
                    height: 46,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  SizedBox(height: 16),
                  ShimmerWidget(
                    width: double.infinity,
                    height: 150,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiSlideSkeleton extends StatelessWidget {
  const _KpiSlideSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerWidget(
                width: 96,
                height: 12,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              ShimmerWidget(
                width: 48,
                height: 20,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerWidget(
                width: 130,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              SizedBox(height: 6),
              ShimmerWidget(
                width: 90,
                height: 12,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ShimmerWidget(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShimmerWidget(
                  width: double.infinity,
                  height: 36,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
