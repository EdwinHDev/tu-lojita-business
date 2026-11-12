import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store_dashboard.dart';
import '../home/home_image_resolver.dart';

/// Unified Bento activity feed for a branch: pending orders ("Por Atender")
/// and settled recent sales ("Ventas Recientes"), each permission-gated.
class StoreDetailsActivitySection extends StatelessWidget {
  final String storeId;
  final StoreDashboard dashboard;
  final bool canViewOrders;
  final bool canViewSales;
  final bool canViewFinancials;

  const StoreDetailsActivitySection({
    super.key,
    required this.storeId,
    required this.dashboard,
    required this.canViewOrders,
    required this.canViewSales,
    required this.canViewFinancials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canViewOrders) ...[
          _buildSectionHeader(
            context,
            title: 'Por Atender',
            countBadge: dashboard.stats.pendingOrdersCount > 0
                ? dashboard.stats.pendingOrdersCount
                : null,
          ),
          const SizedBox(height: 10),
          if (dashboard.pendingOrders.isEmpty)
            const _EmptyActivityCard(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              title: 'Sin órdenes pendientes por atender',
              subtitle:
                  'Las compras nuevas o en cuotas aparecerán aquí para despacharlas.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dashboard.pendingOrders.length > 5
                  ? 5
                  : dashboard.pendingOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = dashboard.pendingOrders[index];
                return _StoreActivityOrderTile(
                  storeId: storeId,
                  orderId: order.orderId.isNotEmpty ? order.orderId : order.id,
                  title: order.itemTitle,
                  subtitleDetail:
                      '${order.customerName} · ${order.time.isNotEmpty ? order.time : 'Hoy'}',
                  amount: order.amount,
                  status: order.status,
                  imageUrl: order.itemImageUrl,
                  showAmount: canViewFinancials,
                  amountPrefix: '',
                );
              },
            ),
          if (canViewSales) const SizedBox(height: 20),
        ],
        if (canViewSales) ...[
          _buildSectionHeader(context, title: 'Ventas Recientes'),
          const SizedBox(height: 10),
          if (dashboard.recentSales.isEmpty)
            const _EmptyActivityCard(
              icon: HugeIcons.strokeRoundedInvoice01,
              title: 'Sin ventas recientes hoy',
              subtitle:
                  'Las ventas que se procesen en esta sucursal aparecerán aquí en vivo.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dashboard.recentSales.length > 5
                  ? 5
                  : dashboard.recentSales.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sale = dashboard.recentSales[index];
                return _StoreActivityOrderTile(
                  storeId: storeId,
                  orderId: sale.orderId.isNotEmpty ? sale.orderId : sale.id,
                  title: sale.itemTitle,
                  subtitleDetail: sale.time.isNotEmpty ? sale.time : 'Hoy',
                  amount: sale.amount,
                  status: sale.status,
                  imageUrl: sale.itemImageUrl,
                  showAmount: canViewFinancials,
                  amountPrefix: '+',
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    int? countBadge,
  }) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: TuLojitaBrandColors.inkPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (countBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.indigo50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$countBadge',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: TuLojitaBrandColors.indigo600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/dashboard/stores/$storeId/orders'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Ver todas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.indigo600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;

  const _EmptyActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TuLojitaBrandColors.borderSubtle, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: TuLojitaBrandColors.canvas,
              shape: BoxShape.circle,
            ),
            child: HugeIcon(
              icon: icon,
              color: TuLojitaBrandColors.inkSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TuLojitaBrandColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreActivityOrderTile extends StatelessWidget {
  final String storeId;
  final String orderId;
  final String? title;
  final String subtitleDetail;
  final double amount;
  final String status;
  final String? imageUrl;
  final bool showAmount;
  final String amountPrefix;

  const _StoreActivityOrderTile({
    required this.storeId,
    required this.orderId,
    required this.title,
    required this.subtitleDetail,
    required this.amount,
    required this.status,
    required this.imageUrl,
    required this.showAmount,
    required this.amountPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final statusUpper = status.toUpperCase();
    final isApproved = statusUpper == 'APPROVED' ||
        statusUpper == 'COMPLETED' ||
        statusUpper == 'PAID' ||
        statusUpper == 'FULLY_PAID';
    final isPartiallyPaid = statusUpper == 'PARTIALLY_PAID';
    final isCancelled = statusUpper == 'CANCELLED' || statusUpper == 'REJECTED';

    final cleanOrderId = orderId.replaceAll('#', '').trim();
    final shortOrderId = cleanOrderId.length >= 8
        ? cleanOrderId.substring(0, 8).toUpperCase()
        : cleanOrderId.toUpperCase();

    final String statusLabel;
    final Color statusTextColor;
    final Color statusBgColor;

    if (isApproved) {
      statusLabel = 'Pagada';
      statusTextColor = TuLojitaBrandColors.positive;
      statusBgColor = TuLojitaBrandColors.positiveBg;
    } else if (isPartiallyPaid) {
      statusLabel = 'En Cuotas';
      statusTextColor = TuLojitaBrandColors.indigo700;
      statusBgColor = TuLojitaBrandColors.indigo50;
    } else if (isCancelled) {
      statusLabel = 'Cancelada';
      statusTextColor = TuLojitaBrandColors.danger;
      statusBgColor = TuLojitaBrandColors.dangerBg;
    } else {
      statusLabel = 'Pendiente';
      statusTextColor = TuLojitaBrandColors.amber800;
      statusBgColor = TuLojitaBrandColors.amber50;
    }

    final resolvedImage = resolveDashboardImageUrl(imageUrl);
    final displayTitle = (title != null && title!.trim().isNotEmpty)
        ? title!.trim()
        : 'Orden #$shortOrderId';

    return Material(
      color: TuLojitaBrandColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          if (cleanOrderId.isNotEmpty) {
            context.push('/dashboard/orders/$cleanOrderId');
          } else {
            context.push('/dashboard/stores/$storeId/orders');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: TuLojitaBrandColors.borderSubtle,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  color: TuLojitaBrandColors.canvas,
                  child: resolvedImage.isNotEmpty
                      ? Image.network(
                          resolvedImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _FallbackOrderIcon(
                            isApproved: isApproved,
                          ),
                        )
                      : _FallbackOrderIcon(isApproved: isApproved),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: TuLojitaBrandColors.inkPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#$shortOrderId · $subtitleDetail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 106),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showAmount) ...[
                      DualPriceText(
                        amountInUsd: amount,
                        prefix: amountPrefix,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        usdStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isApproved
                              ? TuLojitaBrandColors.positive
                              : TuLojitaBrandColors.inkPrimary,
                        ),
                        bsStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackOrderIcon extends StatelessWidget {
  final bool isApproved;

  const _FallbackOrderIcon({required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: HugeIcon(
        icon: isApproved
            ? HugeIcons.strokeRoundedCheckmarkCircle02
            : HugeIcons.strokeRoundedClock01,
        color: isApproved
            ? TuLojitaBrandColors.positive
            : TuLojitaBrandColors.indigo600,
        size: 20,
      ),
    );
  }
}
