import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'item_detail_helpers.dart';

/// Bento card listing configured item variants with dual-currency prices, SKUs,
/// stock badges, and an optional quick-management sheet trigger.
class ItemVariantsBentoSection extends StatelessWidget {
  final Item item;
  final bool canManageVariants;
  final VoidCallback? onManageVariants;

  const ItemVariantsBentoSection({
    super.key,
    required this.item,
    required this.canManageVariants,
    this.onManageVariants,
  });

  @override
  Widget build(BuildContext context) {
    if (!item.hasVariants || item.variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: itemBentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.style_outlined,
                    size: 18,
                    color: TuLojitaBrandColors.indigo600,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Variantes (${item.variants.length})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (canManageVariants && onManageVariants != null)
                TextButton.icon(
                  onPressed: onManageVariants,
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  label: const Text(
                    'Gestionar Variantes',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: TuLojitaBrandColors.indigo600,
                    backgroundColor: TuLojitaBrandColors.indigo50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: item.variants.length,
            separatorBuilder: (_, _) => const Divider(
              height: 18,
              color: TuLojitaBrandColors.borderSubtle,
            ),
            itemBuilder: (context, index) =>
                _VariantRowTile(item: item, variant: item.variants[index], index: index),
          ),
        ],
      ),
    );
  }
}

class _VariantRowTile extends StatelessWidget {
  final Item item;
  final ItemVariant variant;
  final int index;

  const _VariantRowTile({
    required this.item,
    required this.variant,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final label = formatVariantCombinationLabel(variant.axisValues);
    final effectivePrice = variant.price ?? item.price;
    final hasDiscount = variant.discountPrice != null &&
        variant.discountPrice! > 0 &&
        variant.discountPrice! < effectivePrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VariantThumb(variant: variant, item: item),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    label.isNotEmpty ? label : 'Variante ${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: variant.isActive
                          ? TuLojitaBrandColors.inkPrimary
                          : TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                  if (!variant.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.borderSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Pausada',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DualPriceText(
                    amountInUsd: hasDiscount ? variant.discountPrice! : effectivePrice,
                    isInline: true,
                    useScaleDown: true,
                    usdStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasDiscount
                          ? TuLojitaBrandColors.positive
                          : (variant.price != null
                              ? TuLojitaBrandColors.indigo600
                              : TuLojitaBrandColors.inkSecondary),
                    ),
                    bsStyle: const TextStyle(
                      fontSize: 11,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                  if (variant.sku != null && variant.sku!.isNotEmpty)
                    Text(
                      'SKU: ${variant.sku}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _buildStockChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockChip() {
    if (!item.trackInventory) {
      return _stockBadge(
        label: 'Ilimitado',
        bg: TuLojitaBrandColors.borderSubtle,
        fg: TuLojitaBrandColors.inkSecondary,
        border: TuLojitaBrandColors.borderMuted,
      );
    }
    if (variant.stockQuantity <= 0) {
      return _stockBadge(
        label: 'Agotado',
        bg: TuLojitaBrandColors.dangerBg,
        fg: TuLojitaBrandColors.danger,
        border: const Color(0xFFFCA5A5),
      );
    }
    return _stockBadge(
      label: '${variant.stockQuantity.toInt()} en stock',
      bg: TuLojitaBrandColors.positiveBg,
      fg: TuLojitaBrandColors.positive,
      border: const Color(0xFFA7F3D0),
    );
  }

  Widget _stockBadge({
    required String label,
    required Color bg,
    required Color fg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _VariantThumb extends StatelessWidget {
  final ItemVariant variant;
  final Item item;

  const _VariantThumb({required this.variant, required this.item});

  String? _resolveVariantImage() {
    String? imgUrl = variant.imageUrl;
    if (imgUrl == null || imgUrl.isEmpty) {
      for (final val in variant.axisValues.values) {
        if (val.contains('|')) {
          final parts = val.split('|');
          if (parts.length > 2 && parts[2].trim().isNotEmpty) {
            imgUrl = parts[2].trim();
            break;
          }
        }
      }
    }
    if (imgUrl != null && imgUrl.startsWith('img_idx:')) {
      final idx = int.tryParse(imgUrl.replaceFirst('img_idx:', ''));
      if (idx != null && idx >= 0 && idx < item.images.length) {
        return item.images[idx];
      }
      return item.mainImage;
    }
    return (imgUrl != null && imgUrl.isNotEmpty) ? imgUrl : item.mainImage;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveItemImageUrl(_resolveVariantImage());
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TuLojitaBrandColors.borderMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: resolved.isNotEmpty
          ? Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.image_outlined,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            )
          : const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
    );
  }
}
