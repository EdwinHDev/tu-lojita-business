import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'item_detail_helpers.dart';

/// Sliver hero gallery with swipeable photos, dynamic collapsed item title,
/// fullscreen lightbox trigger, and RBAC-gated overflow actions menu.
class ItemDetailHeroGallery extends StatelessWidget {
  final Item item;
  final PageController pageController;
  final int currentPageIndex;
  final ValueChanged<int> onPageChanged;
  final bool isCollapsed;
  final bool canEditProducts;
  final VoidCallback onPromote;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ItemDetailHeroGallery({
    super.key,
    required this.item,
    required this.pageController,
    required this.currentPageIndex,
    required this.onPageChanged,
    required this.isCollapsed,
    required this.canEditProducts,
    required this.onPromote,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  List<String> _collectImages() {
    final allImages = <String>[];
    String norm(String s) => s.trim().replaceAll(RegExp(r'^/+'), '');
    if (item.mainImage.isNotEmpty) {
      allImages.add(item.mainImage);
    }
    for (final img in item.images) {
      if (img.isNotEmpty &&
          !allImages.any((existing) => norm(existing) == norm(img))) {
        allImages.add(img);
      }
    }
    return allImages;
  }

  @override
  Widget build(BuildContext context) {
    final allImages = _collectImages();
    final buttonBg = isCollapsed
        ? TuLojitaBrandColors.borderSubtle
        : Colors.black.withValues(alpha: 0.38);
    final buttonFg =
        isCollapsed ? TuLojitaBrandColors.inkPrimary : Colors.white;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: TuLojitaBrandColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isCollapsed ? 1 : 0,
        child: isCollapsed
            ? Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              )
            : const SizedBox.shrink(),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: buttonBg,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: buttonFg,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      actions: [
        if (canEditProducts)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: buttonBg,
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Opciones del artículo',
              icon: Icon(Icons.more_vert, color: buttonFg, size: 20),
              surfaceTintColor: Colors.transparent,
              color: TuLojitaBrandColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'promote':
                    onPromote();
                    break;
                  case 'duplicate':
                    onDuplicate();
                    break;
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'promote',
                  child: Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: TuLojitaBrandColors.amber700,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Promocionar en Home',
                        style: TextStyle(
                          fontSize: 14,
                          color: TuLojitaBrandColors.amber700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy_all_outlined,
                        size: 18,
                        color: TuLojitaBrandColors.indigo600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Duplicar Artículo',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                      SizedBox(width: 8),
                      Text('Editar Artículo', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: TuLojitaBrandColors.danger,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Eliminar Artículo',
                        style: TextStyle(
                          fontSize: 14,
                          color: TuLojitaBrandColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (allImages.isNotEmpty)
              PageView.builder(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: onPageChanged,
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  final imgUrl = resolveItemImageUrl(allImages[index]);
                  return GestureDetector(
                    onTap: () => showItemImageLightbox(context, allImages, index),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: TuLojitaBrandColors.borderSubtle,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: TuLojitaBrandColors.borderSubtle,
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
              ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.25),
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
              ),
            ),
            if (allImages.length > 1)
              Positioned(
                bottom: 14,
                right: 14,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${currentPageIndex + 1} / ${allImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
