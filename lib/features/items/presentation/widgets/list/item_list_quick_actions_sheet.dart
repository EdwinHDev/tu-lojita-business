import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_notifier.dart';
import 'package:tu_lojita_business/features/items/presentation/widgets/promote_item_sheet.dart';
import '../detail/item_detail_helpers.dart';
import '../detail/item_quick_actions_sheets.dart';

Future<void> showItemListQuickActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String storeId,
  required Item item,
  required bool canEditProducts,
  required bool canChangePrices,
  required bool canManageStock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TuLojitaBrandColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return _ItemListQuickActionsSheetContent(
        parentContext: context,
        ref: ref,
        storeId: storeId,
        item: item,
        canEditProducts: canEditProducts,
        canChangePrices: canChangePrices,
        canManageStock: canManageStock,
      );
    },
  );
}

class _ItemListQuickActionsSheetContent extends StatelessWidget {
  final BuildContext parentContext;
  final WidgetRef ref;
  final String storeId;
  final Item item;
  final bool canEditProducts;
  final bool canChangePrices;
  final bool canManageStock;

  const _ItemListQuickActionsSheetContent({
    required this.parentContext,
    required this.ref,
    required this.storeId,
    required this.item,
    required this.canEditProducts,
    required this.canChangePrices,
    required this.canManageStock,
  });

  bool get _hasActiveDiscount =>
      item.discountPrice != null &&
      item.discountPrice! > 0 &&
      item.discountPrice! < item.price;

  @override
  Widget build(BuildContext context) {
    final activePrice = _hasActiveDiscount
        ? item.discountPrice!
        : (item.hasDifferentVariantPrices
            ? item.variantPriceRange.min
            : item.price);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Item Summary Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          DualPriceText(
                            amountInUsd: activePrice,
                            prefix: item.hasDifferentVariantPrices
                                ? 'Desde '
                                : null,
                            usdStyle: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                            bsStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TuLojitaBrandColors.inkMuted,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: TuLojitaBrandColors.danger,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.favoritesCount} favoritos',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TuLojitaBrandColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(
              height: 1,
              color: TuLojitaBrandColors.borderMuted,
            ),
            const SizedBox(height: 10),
            // 1. Ajustar Precio (canChangePrices)
            if (canChangePrices)
              _ActionTile(
                tileKey: const Key('quick_action_adjust_price'),
                icon: Icons.attach_money_rounded,
                iconColor: TuLojitaBrandColors.primary,
                iconBgColor: TuLojitaBrandColors.primarySoft,
                title: 'Ajustar Precio',
                subtitle: 'Precio base y oferta con vista previa ~ Bs.',
                onTap: () async {
                  Navigator.of(context).pop();
                  final updated =
                      await showQuickPriceSheet(parentContext, item);
                  if (updated != null && parentContext.mounted) {
                    ref
                        .read(itemListProvider.notifier)
                        .upsertItem(storeId, updated);
                  }
                },
              ),
            // 2. Ajustar Stock / Gestionar Variantes (canManageStock o variantes con canChangePrices)
            if (item.itemType == ItemType.product &&
                (canManageStock ||
                    (item.hasVariants &&
                        item.variants.isNotEmpty &&
                        canChangePrices)))
              _ActionTile(
                tileKey: const Key('quick_action_adjust_stock'),
                icon: item.hasVariants && item.variants.isNotEmpty
                    ? Icons.tune_rounded
                    : Icons.inventory_2_outlined,
                iconColor: TuLojitaBrandColors.primary,
                iconBgColor: TuLojitaBrandColors.primarySoft,
                title: item.hasVariants && item.variants.isNotEmpty
                    ? 'Gestionar Variantes'
                    : 'Ajustar Stock',
                subtitle: item.hasVariants && item.variants.isNotEmpty
                    ? 'Stock, precio y estado por combinación'
                    : 'Existencias disponibles del producto',
                onTap: () async {
                  Navigator.of(context).pop();
                  final Item? updated;
                  if (item.hasVariants && item.variants.isNotEmpty) {
                    updated = await showQuickVariantsSheet(
                      parentContext,
                      item,
                      canChangePrices: canChangePrices,
                      canManageStock: canManageStock,
                    );
                  } else {
                    updated = await showQuickStockSheet(parentContext, item);
                  }
                  if (updated != null && parentContext.mounted) {
                    ref
                        .read(itemListProvider.notifier)
                        .upsertItem(storeId, updated);
                  }
                },
              ),
            // 3. Publicar / Pausar (canEditProducts)
            if (canEditProducts)
              _ActionTile(
                tileKey: const Key('quick_action_toggle_publish'),
                icon: item.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                iconColor: item.isActive
                    ? TuLojitaBrandColors.amber700
                    : TuLojitaBrandColors.positive,
                iconBgColor: item.isActive
                    ? TuLojitaBrandColors.amber50
                    : TuLojitaBrandColors.positiveBg,
                title:
                    item.isActive ? 'Pausar artículo' : 'Publicar artículo',
                subtitle: item.isActive
                    ? 'Ocultar temporalmente en la tienda'
                    : 'Mostrar nuevamente a los compradores',
                titleColor: item.isActive
                    ? TuLojitaBrandColors.amber700
                    : TuLojitaBrandColors.positive,
                onTap: () async {
                  Navigator.of(context).pop();
                  if (item.isActive) {
                    final confirmed = await showItemUnpublishConfirmDialog(
                      parentContext,
                      item,
                    );
                    if (!confirmed || !parentContext.mounted) return;
                  }
                  try {
                    await ref
                        .read(itemListProvider.notifier)
                        .toggleItemActive(storeId, item);
                    if (parentContext.mounted) {
                      NotificationService.showSuccess(
                        parentContext,
                        item.isActive
                            ? 'Artículo pausado'
                            : 'Artículo publicado',
                      );
                    }
                  } catch (e) {
                    if (parentContext.mounted) {
                      NotificationService.showError(
                        parentContext,
                        e.toString().replaceAll('Exception: ', ''),
                      );
                    }
                  }
                },
              ),
            // 4. Promocionar en el Home (canEditProducts)
            if (canEditProducts)
              _ActionTile(
                tileKey: const Key('quick_action_promote'),
                icon: Icons.stars_rounded,
                iconColor: TuLojitaBrandColors.amber700,
                iconBgColor: TuLojitaBrandColors.amber50,
                title: 'Promocionar en el Home',
                subtitle: 'Destaca este artículo en la vitrina principal',
                onTap: () {
                  Navigator.of(context).pop();
                  PromoteItemSheet.show(parentContext, item, storeId);
                },
              ),
            // 5. Editar artículo (canEditProducts)
            if (canEditProducts)
              _ActionTile(
                tileKey: const Key('quick_action_edit'),
                icon: Icons.edit_outlined,
                iconColor: TuLojitaBrandColors.primary,
                iconBgColor: TuLojitaBrandColors.primarySoft,
                title: 'Editar artículo',
                subtitle: 'Abrir el formulario completo del artículo',
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await parentContext.push(
                    '/dashboard/stores/$storeId/items/new',
                    extra: item,
                  );
                  if (result == true && parentContext.mounted) {
                    await ref
                        .read(itemListProvider.notifier)
                        .refreshSingleItem(storeId, item.id);
                  }
                },
              ),
            // 6. Duplicar artículo (canEditProducts)
            if (canEditProducts)
              _ActionTile(
                tileKey: const Key('quick_action_duplicate'),
                icon: Icons.copy_rounded,
                iconColor: TuLojitaBrandColors.inkPrimary,
                iconBgColor: TuLojitaBrandColors.background,
                title: 'Duplicar artículo',
                subtitle: 'Crear una copia con sus imágenes y configuración',
                onTap: () async {
                  Navigator.of(context).pop();
                  final result = await parentContext.push(
                    '/dashboard/stores/$storeId/items/new',
                    extra: {'duplicateFrom': item},
                  );
                  if (result == true && parentContext.mounted) {
                    await ref
                        .read(itemListProvider.notifier)
                        .loadInitial(storeId);
                  }
                },
              ),
            // 7. Eliminar artículo (canEditProducts)
            if (canEditProducts)
              _ActionTile(
                tileKey: const Key('quick_action_delete'),
                icon: Icons.delete_outline_rounded,
                iconColor: TuLojitaBrandColors.danger,
                iconBgColor: TuLojitaBrandColors.dangerBg,
                title: 'Eliminar artículo',
                subtitle: 'Borrar permanentemente del catálogo',
                titleColor: TuLojitaBrandColors.danger,
                onTap: () async {
                  Navigator.of(context).pop();
                  final confirmed =
                      await _showDeleteConfirmDialog(parentContext, item);
                  if (!confirmed || !parentContext.mounted) return;
                  try {
                    await ref
                        .read(itemListProvider.notifier)
                        .deleteItem(storeId, item.id);
                    if (parentContext.mounted) {
                      NotificationService.showSuccess(
                        parentContext,
                        'Artículo eliminado exitosamente',
                      );
                    }
                  } catch (e) {
                    if (parentContext.mounted) {
                      NotificationService.showError(
                        parentContext,
                        e.toString().replaceAll('Exception: ', ''),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(
    BuildContext context,
    Item item,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TuLojitaBrandColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Eliminar artículo?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: TuLojitaBrandColors.inkPrimary,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${item.title}"? Esta acción no se puede deshacer.',
          style: const TextStyle(
            fontSize: 14,
            color: TuLojitaBrandColors.inkSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TuLojitaBrandColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _ActionTile extends StatelessWidget {
  final Key? tileKey;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ActionTile({
    this.tileKey,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: tileKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: itemBentoCardDecoration(
              color: TuLojitaBrandColors.surface,
              borderColor: TuLojitaBrandColors.borderMuted,
              radius: 14,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: titleColor ?? TuLojitaBrandColors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: TuLojitaBrandColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: TuLojitaBrandColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
