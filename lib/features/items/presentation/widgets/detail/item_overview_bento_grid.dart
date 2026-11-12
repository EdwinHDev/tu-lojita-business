import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/shimmer_widget.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'item_detail_helpers.dart';

/// Symmetric height-adaptive Bento metadata grid tailored for products,
/// pre-orders, and time-slot services with zero fixed-ratio clipping at
/// `320px @ 1.35x`.
class ItemOverviewBentoGrid extends StatelessWidget {
  final Item item;
  final bool canEditProducts;
  final bool canManageStock;
  final bool isTogglingActive;
  final VoidCallback? onToggleActive;
  final VoidCallback? onAdjustInventory;

  const ItemOverviewBentoGrid({
    super.key,
    required this.item,
    required this.canEditProducts,
    required this.canManageStock,
    this.isTogglingActive = false,
    this.onToggleActive,
    this.onAdjustInventory,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _buildVisibilityCard(),
      _buildInventoryCard(),
      _buildModalityOrFulfillmentCard(),
      _buildFinancingCard(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final useTwoColumns =
            constraints.maxWidth >= 340 || (constraints.maxWidth >= 295 && textScale <= 1.15);

        if (!useTwoColumns) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          );
        }

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisibilityCard() {
    final active = item.isActive;
    return _BentoTile(
      icon: active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      iconColor:
          active ? TuLojitaBrandColors.positive : TuLojitaBrandColors.amber700,
      iconBg: active
          ? TuLojitaBrandColors.positiveBg
          : TuLojitaBrandColors.amber50,
      title: 'Visibilidad',
      value: active ? 'Publicado' : 'Pausado',
      subtitle: active ? 'Visible en catálogo' : 'Oculto a compradores',
      actionLabel: canEditProducts && onToggleActive != null
          ? (isTogglingActive ? 'Actualizando...' : (active ? 'Pausar' : 'Publicar'))
          : null,
      onTap: canEditProducts && !isTogglingActive ? onToggleActive : null,
    );
  }

  Widget _buildInventoryCard() {
    if (!item.trackInventory) {
      return const _BentoTile(
        icon: Icons.all_inclusive_rounded,
        iconColor: TuLojitaBrandColors.indigo600,
        iconBg: TuLojitaBrandColors.indigo50,
        title: 'Inventario',
        value: 'Ilimitado',
        subtitle: 'Sin control estricto de stock',
      );
    }

    final totalStock = item.totalStockQuantity.toInt();
    final isInStock = item.isInStock;
    final activeVariantsCount = item.variants.where((v) => v.isActive).length;
    final value = isInStock
        ? (item.hasVariants ? '$totalStock uds' : '$totalStock en stock')
        : 'Agotado';
    final subtitle = item.hasVariants
        ? '$activeVariantsCount variantes activas'
        : (isInStock ? 'Disponible para venta' : 'Sin unidades disponibles');

    return _BentoTile(
      icon: Icons.inventory_2_outlined,
      iconColor:
          isInStock ? TuLojitaBrandColors.positive : TuLojitaBrandColors.danger,
      iconBg: isInStock
          ? TuLojitaBrandColors.positiveBg
          : TuLojitaBrandColors.dangerBg,
      title: 'Inventario',
      value: value,
      subtitle: subtitle,
      actionLabel:
          canManageStock && onAdjustInventory != null ? 'Ajustar' : null,
      onTap: canManageStock ? onAdjustInventory : null,
    );
  }

  Widget _buildModalityOrFulfillmentCard() {
    if (item.isServiceWithSlots) {
      final locationLabel = switch (item.serviceLocationType) {
        'HOME_SERVICE' => 'A domicilio',
        'CUSTOMER_CHOICE' => 'A elección del cliente',
        _ => 'En local',
      };
      final durationMin =
          int.tryParse('${item.slotConfig?['serviceDurationMinutes'] ?? 60}') ??
              60;
      final minNoticeH =
          int.tryParse('${item.slotConfig?['minNoticeHours'] ?? 2}') ?? 2;

      return _BentoTile(
        icon: Icons.calendar_month_outlined,
        iconColor: TuLojitaBrandColors.indigo600,
        iconBg: TuLojitaBrandColors.indigo50,
        title: 'Turnos y Modalidad',
        value: locationLabel,
        subtitle: '$durationMin min · Aviso mín. ${minNoticeH}h',
      );
    }

    if (item.preorderConfig != null &&
        (item.bookingType == 'PRE_ORDER' || item.requiresBooking)) {
      final cfg = item.preorderConfig!;
      final isPct =
          cfg['depositType']?.toString().toUpperCase() == 'PERCENTAGE';
      final depositVal =
          double.tryParse('${cfg['depositValue'] ?? 50}') ?? 50.0;
      final leadMin =
          int.tryParse('${cfg['estimatedLeadDaysMin'] ?? 7}') ?? 7;
      final leadMax =
          int.tryParse('${cfg['estimatedLeadDaysMax'] ?? 15}') ?? 15;
      final depositStr = isPct
          ? 'Anticipo ${depositVal.toStringAsFixed(0)}%'
          : 'Anticipo \$${depositVal.toStringAsFixed(2)}';

      return _BentoTile(
        icon: Icons.schedule_send_outlined,
        iconColor: TuLojitaBrandColors.amber700,
        iconBg: TuLojitaBrandColors.amber50,
        title: 'Preventa (Bajo Demanda)',
        value: depositStr,
        subtitle: '$leadMin–$leadMax días estimados',
      );
    }

    final isProduct = item.itemType == ItemType.product;
    return _BentoTile(
      icon: item.requiresBooking
          ? Icons.event_available_outlined
          : Icons.local_shipping_outlined,
      iconColor: item.requiresBooking
          ? TuLojitaBrandColors.indigo600
          : TuLojitaBrandColors.inkSecondary,
      iconBg: item.requiresBooking
          ? TuLojitaBrandColors.indigo50
          : TuLojitaBrandColors.borderSubtle,
      title: isProduct ? 'Entrega' : 'Disponibilidad',
      value: item.requiresBooking
          ? 'Requiere Reserva'
          : (isProduct ? 'Entrega Estándar' : 'Servicio Inmediato'),
      subtitle: item.requiresBooking
          ? 'Agenda sujeta a confirmación'
          : 'Despacho o atención directa',
    );
  }

  Widget _buildFinancingCard() {
    final allow = item.allowInstallments;
    final mora = item.lateFeePercentage;
    final moraLabel = mora > 0
        ? 'Recargo por mora: ${mora.toStringAsFixed(mora % 1 == 0 ? 0 : 1)}%'
        : 'Sin recargo por mora';

    return _BentoTile(
      icon: Icons.payments_outlined,
      iconColor:
          allow ? TuLojitaBrandColors.positive : TuLojitaBrandColors.inkSecondary,
      iconBg: allow
          ? TuLojitaBrandColors.positiveBg
          : TuLojitaBrandColors.borderSubtle,
      title: 'Financiamiento',
      value: allow ? 'Apto para Cuotas' : 'Solo Pago Único',
      subtitle: allow ? moraLabel : 'Pago de contado al ordenar',
    );
  }
}

class _BentoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _BentoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: itemBentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.indigo50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: TuLojitaBrandColors.indigo600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: TuLojitaBrandColors.inkSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

/// Structural Bento loading skeleton shown during uncached refreshes.
class ItemDetailLoadingSkeleton extends StatelessWidget {
  const ItemDetailLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerWidget(
          width: double.infinity,
          height: 220,
          borderRadius: BorderRadius.circular(18),
        ),
        const SizedBox(height: 14),
        ShimmerWidget(
          width: double.infinity,
          height: 150,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 12),
        ShimmerWidget(
          width: double.infinity,
          height: 110,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ShimmerWidget(
                width: double.infinity,
                height: 105,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ShimmerWidget(
                width: double.infinity,
                height: 105,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ShimmerWidget(
                width: double.infinity,
                height: 105,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ShimmerWidget(
                width: double.infinity,
                height: 105,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
