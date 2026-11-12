import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'item_detail_helpers.dart';

/// Primary Bento header card presenting item badges, title, BCV exchange pill,
/// dual-currency pricing, quick price adjustment trigger, and RBAC-gated unit
/// profitability breakdown.
class ItemPriceProfitCard extends ConsumerWidget {
  final Item item;
  final bool canChangePrices;
  final bool canViewSensitiveFinances;
  final VoidCallback? onAdjustPrice;

  const ItemPriceProfitCard({
    super.key,
    required this.item,
    required this.canChangePrices,
    required this.canViewSensitiveFinances,
    this.onAdjustPrice,
  });

  bool get _hasDiscount =>
      item.discountPrice != null &&
      item.discountPrice! > 0 &&
      item.discountPrice! < item.price;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeConfig = ref.watch(exchangeRateProvider).asData?.value;
    final showBcvPill =
        exchangeConfig != null && PriceFormatter.isDualEnabled(exchangeConfig);

    final bool isProduct = item.itemType == ItemType.product;
    final bool isNonMonetary = item.priceType == PriceType.free ||
        item.priceType == PriceType.onDemand;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: itemBentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PillBadge(
                label: isProduct ? 'Producto' : 'Servicio',
                bgColor: TuLojitaBrandColors.indigo50,
                fgColor: TuLojitaBrandColors.indigo600,
                borderColor: TuLojitaBrandColors.indigo100,
              ),
              _PillBadge(
                label: item.isActive ? 'Publicado' : 'Pausado',
                bgColor: item.isActive
                    ? TuLojitaBrandColors.positiveBg
                    : TuLojitaBrandColors.borderSubtle,
                fgColor: item.isActive
                    ? TuLojitaBrandColors.positive
                    : TuLojitaBrandColors.inkSecondary,
                borderColor: item.isActive
                    ? const Color(0xFFA7F3D0)
                    : TuLojitaBrandColors.borderMuted,
              ),
              if (item.isAgeRestricted)
                const _PillBadge(
                  label: '+18',
                  bgColor: TuLojitaBrandColors.dangerBg,
                  fgColor: TuLojitaBrandColors.danger,
                  borderColor: Color(0xFFFCA5A5),
                ),
              if (showBcvPill)
                _PillBadge(
                  label:
                      'Tasa BCV: ${PriceFormatter.formatRateValue(exchangeConfig.rate, symbol: exchangeConfig.symbol)}',
                  bgColor: TuLojitaBrandColors.canvas,
                  fgColor: TuLojitaBrandColors.inkSecondary,
                  borderColor: TuLojitaBrandColors.borderMuted,
                  icon: Icons.currency_exchange_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TuLojitaBrandColors.inkPrimary,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildPriceDisplay(),
              if (canChangePrices && !isNonMonetary && onAdjustPrice != null)
                OutlinedButton.icon(
                  onPressed: onAdjustPrice,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedEdit02,
                    size: 15,
                    color: TuLojitaBrandColors.indigo600,
                  ),
                  label: const Text(
                    'Ajustar Precio',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TuLojitaBrandColors.indigo600,
                    side: const BorderSide(color: TuLojitaBrandColors.indigo100),
                    backgroundColor: TuLojitaBrandColors.indigo50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          if (canViewSensitiveFinances && !isNonMonetary && item.price > 0) ...[
            const SizedBox(height: 14),
            _buildUnitProfitabilityBox(),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (item.priceType == PriceType.free) {
      return const Text(
        'Gratis',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: TuLojitaBrandColors.positive,
        ),
      );
    }
    if (item.priceType == PriceType.onDemand) {
      return const Text(
        'A consultar',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: TuLojitaBrandColors.indigo600,
        ),
      );
    }

    const usdHeroStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: TuLojitaBrandColors.inkPrimary,
      letterSpacing: -0.5,
    );
    const bsHeroStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: TuLojitaBrandColors.inkSecondary,
    );

    if (item.hasVariants && item.hasDifferentVariantPrices) {
      final range = item.variantPriceRange;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rango según variante',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DualPriceText(
                amountInUsd: range.min,
                prefix: 'Desde ',
                usdStyle: usdHeroStyle.copyWith(fontSize: 20),
                bsStyle: bsHeroStyle,
                useScaleDown: true,
              ),
              const Text(
                '–',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
              DualPriceText(
                amountInUsd: range.max,
                usdStyle: usdHeroStyle.copyWith(fontSize: 20),
                bsStyle: bsHeroStyle,
                useScaleDown: true,
              ),
            ],
          ),
        ],
      );
    }

    if (_hasDiscount) {
      final discountPct =
          (((item.price - item.discountPrice!) / item.price) * 100).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DualPriceText(
                amountInUsd: item.discountPrice!,
                prefix: item.priceType == PriceType.startingAt ? 'Desde ' : '',
                usdStyle: usdHeroStyle.copyWith(
                  color: TuLojitaBrandColors.positive,
                ),
                bsStyle: bsHeroStyle,
                useScaleDown: true,
              ),
              _PillBadge(
                label: '-$discountPct%',
                bgColor: TuLojitaBrandColors.positiveBg,
                fgColor: TuLojitaBrandColors.positive,
                borderColor: const Color(0xFFA7F3D0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          DualPriceText(
            amountInUsd: item.price,
            prefix: 'Antes: ',
            isInline: true,
            useScaleDown: true,
            usdStyle: const TextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              color: TuLojitaBrandColors.inkSecondary,
            ),
            bsStyle: const TextStyle(
              fontSize: 11,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ],
      );
    }

    return DualPriceText(
      amountInUsd: item.price,
      prefix: item.priceType == PriceType.startingAt ? 'Desde ' : '',
      usdStyle: usdHeroStyle,
      bsStyle: bsHeroStyle,
      useScaleDown: true,
    );
  }

  Widget _buildUnitProfitabilityBox() {
    final publicPrice = _hasDiscount ? item.discountPrice! : item.price;
    final double netUnit = item.basePrice > 0 && !_hasDiscount
        ? item.basePrice
        : (publicPrice - item.commissionAmount > 0
            ? publicPrice - item.commissionAmount
            : publicPrice);
    final double commUnit = _hasDiscount
        ? (publicPrice - netUnit > 0 ? publicPrice - netUnit : 0)
        : (item.commissionAmount > 0
            ? item.commissionAmount
            : (publicPrice - netUnit > 0 ? publicPrice - netUnit : 0));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TuLojitaBrandColors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAnalytics01,
                size: 14,
                color: TuLojitaBrandColors.indigo600,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Rentabilidad por unidad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
              if (item.commissionRate > 0)
                Text(
                  'Comisión ${item.commissionRate.toStringAsFixed(item.commissionRate % 1 == 0 ? 0 : 1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TuLojitaBrandColors.inkSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _ProfitRow(
            label: 'Precio público',
            amountUsd: publicPrice,
            valueColor: TuLojitaBrandColors.inkPrimary,
          ),
          const SizedBox(height: 6),
          _ProfitRow(
            label: 'Comisión plataforma',
            amountUsd: commUnit,
            prefix: commUnit > 0 ? '- ' : '',
            valueColor: TuLojitaBrandColors.inkSecondary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: TuLojitaBrandColors.borderMuted),
          ),
          _ProfitRow(
            label: 'Tu ingreso neto',
            amountUsd: netUnit,
            valueColor: TuLojitaBrandColors.positive,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }
}

class _ProfitRow extends StatelessWidget {
  final String label;
  final double amountUsd;
  final String prefix;
  final Color valueColor;
  final bool isHighlighted;

  const _ProfitRow({
    required this.label,
    required this.amountUsd,
    this.prefix = '',
    required this.valueColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: isHighlighted
                  ? TuLojitaBrandColors.inkPrimary
                  : TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: DualPriceText(
            amountInUsd: amountUsd,
            prefix: prefix,
            crossAxisAlignment: CrossAxisAlignment.end,
            useScaleDown: true,
            usdStyle: TextStyle(
              fontSize: isHighlighted ? 14 : 12,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
            ),
            bsStyle: const TextStyle(
              fontSize: 11,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color fgColor;
  final Color borderColor;
  final IconData? icon;

  const _PillBadge({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.borderColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
