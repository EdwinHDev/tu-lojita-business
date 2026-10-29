import 'package:flutter/material.dart';
import '../../../../core/widgets/shimmer_widget.dart';

/// Skeleton for the Store Info Card in StoreDetailsScreen.
/// Replaces false/default data ("Solo Contado", "0 Productos", "Cargando...")
/// with smooth shimmers that preserve the exact layout.
class StoreHeaderCardSkeleton extends StatelessWidget {
  const StoreHeaderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
      child: Column(
        children: [
          // 1. Título de la Tienda Shimmer
          const ShimmerWidget(
            width: 170,
            height: 22,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          const SizedBox(height: 10),

          // 2. Subcategoría / Rubro Shimmer
          const ShimmerWidget(
            width: 110,
            height: 22,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(height: 12),

          // 3. Pastillas de Régimen y Catálogo Shimmer
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerWidget(
                width: 130,
                height: 28,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: 8),
              ShimmerWidget(
                width: 105,
                height: 28,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 4. Botones de Acción Rápida Shimmer (IconButtons)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerWidget(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              SizedBox(width: 14),
              ShimmerWidget(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the 3 Key Metrics Cards in StoreDetailsScreen.
/// Preserves exact height and width to prevent layout shifts when dashboard loads.
class StoreMetricsSkeleton extends StatelessWidget {
  const StoreMetricsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
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
                  color: Color(0xFF0F172A),
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
          Row(
            children: [
              Expanded(child: _buildMetricCardSkeleton()),
              const SizedBox(width: 10),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          SizedBox(height: 12),
          ShimmerWidget(
            width: 60,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          SizedBox(height: 5),
          ShimmerWidget(
            width: 48,
            height: 10,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the Recent Sales section in StoreDetailsScreen.
class StoreRecentSalesSkeleton extends StatelessWidget {
  const StoreRecentSalesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ventas Recientes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: 2,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF1F5F9),
                indent: 64,
              ),
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    // Product Thumbnail
                    ShimmerWidget(
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    SizedBox(width: 12),
                    // Item Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerWidget(
                            width: 130,
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
                    // Amount and Status Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShimmerWidget(
                          width: 50,
                          height: 14,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        SizedBox(height: 6),
                        ShimmerWidget(
                          width: 55,
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
