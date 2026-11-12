import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';

/// Structural Bento shimmer placeholder for [OrderListScreen].
class OrderListBentoShimmer extends StatelessWidget {
  final int itemCount;

  const OrderListBentoShimmer({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) => const _OrderCardSkeleton(),
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.4,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerWidget(
                width: 96,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              Spacer(),
              ShimmerWidget(
                width: 78,
                height: 24,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerWidget(
                width: 52,
                height: 52,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget(
                      width: 165,
                      height: 15,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(height: 8),
                    ShimmerWidget(
                      width: 118,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, color: TuLojitaBrandColors.borderSubtle),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget(
                      width: 82,
                      height: 18,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    SizedBox(height: 6),
                    ShimmerWidget(
                      width: 96,
                      height: 11,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
              ShimmerWidget(
                width: 68,
                height: 28,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Structural Bento shimmer placeholder for [OrderDetailsScreen].
class OrderDetailsBentoShimmer extends StatelessWidget {
  const OrderDetailsBentoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        _DetailBlockSkeleton(height: 128),
        SizedBox(height: 16),
        _DetailBlockSkeleton(height: 108),
        SizedBox(height: 16),
        _DetailBlockSkeleton(height: 146),
        SizedBox(height: 16),
        _DetailBlockSkeleton(height: 136),
      ],
    );
  }
}

class _DetailBlockSkeleton extends StatelessWidget {
  final double height;

  const _DetailBlockSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              ShimmerWidget(
                width: 34,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget(
                      width: 140,
                      height: 15,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    SizedBox(height: 6),
                    ShimmerWidget(
                      width: 96,
                      height: 11,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: height > 130 ? 18 : 14),
          const ShimmerWidget(
            width: double.infinity,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          const SizedBox(height: 10),
          const ShimmerWidget(
            width: 180,
            height: 14,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ],
      ),
    );
  }
}
