import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import '../detail/item_detail_helpers.dart';

class ItemBentoGridCard extends StatelessWidget {
  final Item item;
  final bool canShowQuickActions;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const ItemBentoGridCard({
    super.key,
    required this.item,
    required this.canShowQuickActions,
    required this.onTap,
    this.onMoreTap,
  });

  bool get _hasActiveDiscount =>
      item.discountPrice != null &&
      item.discountPrice! > 0 &&
      item.discountPrice! < item.price;

  int get _discountPercentage {
    if (!_hasActiveDiscount || item.price <= 0) return 0;
    return (((item.price - item.discountPrice!) / item.price) * 100)
        .round()
        .clamp(1, 99);
  }

  ({String label, Color bgColor, Color fgColor, Color borderColor})
      _resolvePriorityBadge() {
    if (!item.isActive) {
      return (
        label: 'Pausado',
        bgColor: TuLojitaBrandColors.dangerBg,
        fgColor: TuLojitaBrandColors.danger,
        borderColor: TuLojitaBrandColors.danger.withValues(alpha: 0.3),
      );
    }
    if (item.isOutOfStock) {
      return (
        label: 'Agotado',
        bgColor: TuLojitaBrandColors.amber50,
        fgColor: TuLojitaBrandColors.amber700,
        borderColor: TuLojitaBrandColors.amber700.withValues(alpha: 0.35),
      );
    }
    if (item.trackInventory && item.totalStockQuantity <= 3) {
      return (
        label: 'Stock bajo',
        bgColor: TuLojitaBrandColors.amber50,
        fgColor: TuLojitaBrandColors.amber700,
        borderColor: TuLojitaBrandColors.amber700.withValues(alpha: 0.35),
      );
    }
    if (_hasActiveDiscount) {
      return (
        label: 'Oferta -$_discountPercentage%',
        bgColor: TuLojitaBrandColors.positiveBg,
        fgColor: TuLojitaBrandColors.positive,
        borderColor: TuLojitaBrandColors.positive.withValues(alpha: 0.35),
      );
    }
    return (
      label: 'Publicado',
      bgColor: TuLojitaBrandColors.positiveBg,
      fgColor: TuLojitaBrandColors.positive,
      borderColor: TuLojitaBrandColors.positive.withValues(alpha: 0.3),
    );
  }

  String _resolveOperationalMeta() {
    if (item.isServiceWithSlots) {
      return 'Servicio · Citas';
    }
    if (item.itemType == ItemType.service) {
      return 'Servicio';
    }
    if (item.preorderConfig != null) {
      return 'Pre-orden';
    }
    if (item.trackInventory) {
      return 'Producto · Stock: ${item.totalStockQuantity.toInt()}';
    }
    return 'Producto · Ilimitado';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveItemImageUrl(item.mainImage);
    final badge = _resolvePriorityBadge();
    final metaLabel = _resolveOperationalMeta();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('bento_item_card_${item.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: itemBentoCardDecoration(
            color: TuLojitaBrandColors.surface,
            borderColor: !item.isActive
                ? TuLojitaBrandColors.borderSubtle
                : TuLojitaBrandColors.borderMuted,
            radius: 16,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Media Zone
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Opacity(
                          opacity: item.isActive ? 1.0 : 0.65,
                          child: Container(
                            color: TuLojitaBrandColors.background,
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildMediaPlaceholder(),
                                  )
                                : _buildMediaPlaceholder(),
                          ),
                        ),
                        // Top-left Priority Operational Badge (no emojis)
                        Positioned(
                          top: 8,
                          left: 8,
                          right: canShowQuickActions ? 42 : 8,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: badge.bgColor.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badge.borderColor),
                              ),
                              child: Text(
                                badge.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: badge.fgColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Top-right Quick Actions Trigger (⋮)
                        if (canShowQuickActions && onMoreTap != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: Key('item_card_more_${item.id}'),
                                customBorder: const CircleBorder(),
                                onTap: onMoreTap,
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: TuLojitaBrandColors.inkPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Bottom Overlays: Variant count & Favorites
                        if ((item.hasVariants && item.variants.isNotEmpty) ||
                            item.favoritesCount > 0)
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (item.hasVariants &&
                                    item.variants.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TuLojitaBrandColors.inkPrimary
                                          .withValues(alpha: 0.78),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.variants.length} var.',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (item.favoritesCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: TuLojitaBrandColors.borderMuted,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.favorite_rounded,
                                          size: 11,
                                          color: TuLojitaBrandColors.danger,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${item.favoritesCount}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                TuLojitaBrandColors.inkPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 2. Meta & Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: TuLojitaBrandColors.primary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TuLojitaBrandColors.inkPrimary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 3. Bottom Price Block
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(
                      height: 10,
                      thickness: 1,
                      color: TuLojitaBrandColors.borderMuted,
                    ),
                    _buildPriceFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder() {
    final isService = item.itemType == ItemType.service;
    return Center(
      child: Icon(
        isService
            ? Icons.design_services_outlined
            : Icons.inventory_2_outlined,
        size: 32,
        color: TuLojitaBrandColors.inkMuted,
      ),
    );
  }

  Widget _buildPriceFooter() {
    if (item.priceType == PriceType.free) {
      return const Text(
        'Gratis',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: TuLojitaBrandColors.positive,
        ),
      );
    }

    if (item.priceType == PriceType.onDemand) {
      return const Text(
        'Bajo presupuesto',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: TuLojitaBrandColors.inkSecondary,
        ),
      );
    }

    if (_hasActiveDiscount) {
      return Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DualPriceText(
            amountInUsd: item.discountPrice!,
            usdStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: TuLojitaBrandColors.positive,
            ),
            bsStyle: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
          Text(
            '\$${item.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: TuLojitaBrandColors.inkMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    final displayPrice = item.hasDifferentVariantPrices
        ? item.variantPriceRange.min
        : item.price;
    final prefix = item.hasDifferentVariantPrices ||
            item.priceType == PriceType.startingAt
        ? 'Desde '
        : null;

    return DualPriceText(
      amountInUsd: displayPrice,
      prefix: prefix,
      usdStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: TuLojitaBrandColors.inkPrimary,
      ),
      bsStyle: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: TuLojitaBrandColors.inkSecondary,
      ),
    );
  }
}
