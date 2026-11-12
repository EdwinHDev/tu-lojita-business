import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';

/// Sticky Bento bottom action bar giving authorized editors one-tap publish/pause
/// control and direct navigation into the item edit wizard.
class ItemOwnerBottomBar extends StatelessWidget {
  final Item item;
  final bool canEditProducts;
  final bool isTogglingActive;
  final VoidCallback onTogglePublish;
  final VoidCallback onEdit;

  const ItemOwnerBottomBar({
    super.key,
    required this.item,
    required this.canEditProducts,
    required this.isTogglingActive,
    required this.onTogglePublish,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (!canEditProducts) return const SizedBox.shrink();

    final isPublished = item.isActive;
    final secondaryColor =
        isPublished ? TuLojitaBrandColors.amber700 : TuLojitaBrandColors.positive;
    final secondaryBg =
        isPublished ? TuLojitaBrandColors.amber50 : TuLojitaBrandColors.positiveBg;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: TuLojitaBrandColors.surface,
          border: Border(
            top: BorderSide(color: TuLojitaBrandColors.borderMuted),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: isTogglingActive ? null : onTogglePublish,
                icon: isTogglingActive
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: secondaryColor,
                        ),
                      )
                    : Icon(
                        isPublished
                            ? Icons.pause_circle_outline_rounded
                            : Icons.publish_rounded,
                        size: 18,
                      ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isPublished ? 'Pausar' : 'Publicar',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryColor,
                  backgroundColor: secondaryBg,
                  side: BorderSide(
                    color: secondaryColor.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Editar Artículo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.indigo600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
