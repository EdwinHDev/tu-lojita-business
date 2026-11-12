import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shimmer_widget.dart';

/// Skeleton for StoreDetailsIdentityCard.
/// Completely free of fixed-width row overflow on 320px viewports and free of ProviderScope.
class StoreHeaderCardSkeleton extends StatelessWidget {
  const StoreHeaderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerWidget(
                width: 56,
                height: 56,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidget(
                      width: 160,
                      height: 18,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    SizedBox(height: 8),
                    ShimmerWidget(
                      width: 110,
                      height: 13,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ShimmerWidget(
                width: 78,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              ShimmerWidget(
                width: 102,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              ShimmerWidget(
                width: 96,
                height: 26,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for StoreDetailsMetricsBento preserving 'Métricas Clave' header and standalone testability.
class StoreMetricsSkeleton extends StatelessWidget {
  const StoreMetricsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Métricas Clave',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: TuLojitaBrandColors.inkPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Hoy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.indigo50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: TuLojitaBrandColors.indigo100,
                width: 1.5,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidget(
                  width: 110,
                  height: 13,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 12),
                ShimmerWidget(
                  width: 145,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCardSkeleton()),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCardSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle, width: 1.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: 30,
            height: 30,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(height: 10),
          ShimmerWidget(
            width: 56,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          SizedBox(height: 5),
          ShimmerWidget(
            width: 68,
            height: 10,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for StoreDetailsActivitySection.
class StoreRecentSalesSkeleton extends StatelessWidget {
  const StoreRecentSalesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas Recientes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: TuLojitaBrandColors.inkPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TuLojitaBrandColors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: 2,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: TuLojitaBrandColors.borderSubtle,
                indent: 64,
              ),
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    ShimmerWidget(
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerWidget(
                            width: 120,
                            height: 14,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          SizedBox(height: 6),
                          ShimmerWidget(
                            width: 80,
                            height: 11,
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShimmerWidget(
                          width: 48,
                          height: 14,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        SizedBox(height: 6),
                        ShimmerWidget(
                          width: 54,
                          height: 16,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
