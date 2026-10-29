import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/entities/item.dart';
import '../../../../core/config/envs.dart';
import '../providers/item_list_notifier.dart';
import '../../../../core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final String storeId;
  final Item item;

  const ItemDetailScreen({super.key, required this.storeId, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  late Item _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentItem;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildMetadataCards(),
                  if (item.hasVariants && item.variants.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildVariantsSection(),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionHeader('Descripción del Artículo'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Configuración de Cuotas'),
                  const SizedBox(height: 10),
                  _buildInstallmentsSection(),
                  if (item.attributes != null &&
                      item.attributes!['properties'] != null &&
                      (item.attributes!['properties'] as List).isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionHeader('Especificaciones Técnicas'),
                    const SizedBox(height: 10),
                    _buildPropertiesSection(List<Map<String, dynamic>>.from(item.attributes!['properties'])),
                  ],
                  if (item.customizationGroups.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildSectionHeader('Grupos de Personalización'),
                    const SizedBox(height: 10),
                    ...item.customizationGroups.map((group) => _buildCustomizationGroupCard(group)),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final item = _currentItem;
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canEditProducts = user?.canEditProducts ?? true;
    final allImages = <String>[];
    String norm(String s) => s.trim().replaceAll(RegExp(r'^/+'), '');
    if (item.mainImage.isNotEmpty) {
      allImages.add(item.mainImage);
    }
    for (final img in item.images) {
      if (img.isNotEmpty &&
          (allImages.isEmpty || norm(img) != norm(item.mainImage)) &&
          !allImages.any((existing) => norm(existing) == norm(img))) {
        allImages.add(img);
      }
    }

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (allImages.isNotEmpty)
              PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                itemCount: allImages.length,
                itemBuilder: (context, index) {
                  final imgUrl = _resolveImageUrl(allImages[index]);
                  return GestureDetector(
                    onTap: () => _openImageLightbox(context, allImages, index),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1F5F9),
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
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.image_outlined, size: 64, color: Color(0xFF94A3B8)),
              ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            if (allImages.length > 1) ...[
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      allImages.length,
                      (index) {
                        final isSelected = _currentPageIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: isSelected ? 22 : 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 16,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPageIndex + 1} / ${allImages.length}',
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
          ],
        ),
      ),
      actions: [
        if (canEditProducts)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
              surfaceTintColor: Colors.transparent,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await context.push('/dashboard/stores/${widget.storeId}/items/new', extra: item);
                  if (result == true && mounted && context.mounted) {
                    ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
                    context.pop(true);
                  }
                } else if (value == 'delete') {
                  if (context.mounted) {
                    _confirmDeleteItem(context, item);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
                      SizedBox(width: 8),
                      Text('Editar Artículo', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final item = _currentItem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.itemType == ItemType.product ? 'PRODUCTO' : 'SERVICIO',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            if (item.isFeatured) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 11, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'DESTACADO',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        _buildPriceSection(),
      ],
    );
  }

  Widget _buildPriceSection() {
    final item = _currentItem;
    final double displayBasePrice = item.price;
    final double? discountPrice = item.discountPrice;
    final hasDiscount = discountPrice != null;

    String priceTypeLabel = '';
    String priceText = '';
    String? discountText;

    if (item.hasDifferentVariantPrices) {
      priceTypeLabel = 'Rango de Precios';
      final range = item.variantPriceRange;
      priceText = '\$${range.min.toStringAsFixed(2)} - \$${range.max.toStringAsFixed(2)}';
    } else {
      switch (item.priceType) {
        case PriceType.free:
          priceText = 'Gratis';
          break;
        case PriceType.onDemand:
          priceText = 'A consultar';
          break;
        case PriceType.negotiable:
          priceTypeLabel = 'Precio Negociable';
          priceText = '\$${displayBasePrice.toStringAsFixed(2)}';
          if (hasDiscount) {
            discountText = '\$${discountPrice.toStringAsFixed(2)}';
          }
          break;
        case PriceType.startingAt:
          priceTypeLabel = 'Precio Inicial';
          priceText = '\$${displayBasePrice.toStringAsFixed(2)}';
          if (hasDiscount) {
            discountText = '\$${discountPrice.toStringAsFixed(2)}';
          }
          break;
        case PriceType.fixed:
          priceText = '\$${displayBasePrice.toStringAsFixed(2)}';
          if (hasDiscount) {
            discountText = '\$${discountPrice.toStringAsFixed(2)}';
          }
          break;
      }
    }

    final isSpecialType = item.priceType == PriceType.free || item.priceType == PriceType.onDemand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (priceTypeLabel.isNotEmpty && !isSpecialType)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              priceTypeLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 1.0,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              priceText,
              style: TextStyle(
                fontSize: hasDiscount && discountText != null ? 18 : 26,
                fontWeight: FontWeight.w800,
                color: hasDiscount && discountText != null ? const Color(0xFF94A3B8) : const Color(0xFF4F46E5),
                decoration: hasDiscount && discountText != null ? TextDecoration.lineThrough : null,
              ),
            ),
            if (hasDiscount && discountText != null) ...[
              const SizedBox(width: 8),
              Text(
                discountText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMetadataCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.3,
      children: [
        _buildPublishCard(),
        _buildStockCard(),
        _buildBookingCard(),
      ],
    );
  }

  Widget _buildPublishCard() {
    final item = _currentItem;
    final bool active = item.isActive;

    return _buildStatusCardTemplate(
      icon: active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      iconColor: active ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      bgColor: active ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      title: 'Estado Público',
      desc: active ? 'Publicado' : 'Despublicado',
    );
  }

  Widget _buildStockCard() {
    final item = _currentItem;
    final bool track = item.trackInventory;
    final bool inStock = item.isInStock;
    final double stock = item.totalStockQuantity;
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canManageStock = user?.canManageStock ?? true;

    IconData icon;
    Color iconColor;
    Color bgColor;
    String title;
    String desc;

    if (!track) {
      icon = Icons.all_inclusive_rounded;
      iconColor = const Color(0xFF475569);
      bgColor = const Color(0xFFF1F5F9);
      title = 'Inventario';
      desc = 'Ilimitado';
    } else if (inStock) {
      icon = Icons.inventory_2_outlined;
      iconColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFECFDF5);
      title = item.hasVariants
          ? 'Stock (${item.variants.where((v) => v.isActive).length} var.)'
          : 'Stock Disponible';
      desc = '${stock.toInt()} unidades';
    } else {
      icon = Icons.inventory_2_outlined;
      iconColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
      title = item.hasVariants ? 'Variantes' : 'Inventario';
      desc = 'Agotado';
    }

    final cardWidget = _buildStatusCardTemplate(
      icon: icon,
      iconColor: iconColor,
      bgColor: bgColor,
      title: title,
      desc: desc,
    );

    if (track && canManageStock) {
      return InkWell(
        onTap: () => _showQuickStockDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            cardWidget,
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 10, color: Color(0xFF4F46E5)),
                    SizedBox(width: 2),
                    Text(
                      'Ajustar',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return cardWidget;
  }

  Future<void> _showQuickStockDialog(BuildContext context) async {
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canManageStock = user?.canManageStock ?? true;
    if (!canManageStock) {
      NotificationService.showWarning(context, 'No tienes permisos para modificar el inventario.');
      return;
    }

    if (_currentItem.hasVariants && _currentItem.variants.isNotEmpty) {
      final controllers = <String, TextEditingController>{};
      for (int i = 0; i < _currentItem.variants.length; i++) {
        final v = _currentItem.variants[i];
        final key = v.id ?? 'var_$i';
        controllers[key] = TextEditingController(text: v.stockQuantity.toInt().toString());
      }

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ajustar Stock de Variantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _currentItem.variants.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                final key = v.id ?? 'var_$i';
                final label = v.axisValues.values
                    .map((val) => val.contains('|') ? val.split('|')[0] : val)
                    .join(' / ');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label.isNotEmpty ? label : 'Variante #${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: controllers[key],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        try {
          final updatedVariants = _currentItem.variants.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            final key = v.id ?? 'var_$i';
            final qty = double.tryParse(controllers[key]?.text ?? '') ?? v.stockQuantity;
            return {
              if (v.id != null) 'id': v.id,
              'sku': v.sku,
              'price': v.price,
              'stockQuantity': qty,
              'isActive': v.isActive,
              'axisValues': v.axisValues,
            };
          }).toList();

          final updated = await ref.read(itemRepositoryProvider).updateItem(
            _currentItem.id,
            {'variants': updatedVariants},
          );
          if (mounted) {
            setState(() => _currentItem = updated);
            ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
            if (context.mounted) {
              NotificationService.showSuccess(context, 'Stock de variantes actualizado.');
            }
          }
        } catch (e) {
          if (mounted && context.mounted) {
            NotificationService.showError(context, 'Error al actualizar stock: $e');
          }
        }
      }
    } else {
      final currentQty = (_currentItem.stockQuantity ?? 0).toInt();
      final controller = TextEditingController(text: currentQty.toString());
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ajustar Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentItem.title,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad en Stock',
                  hintText: '0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        try {
          final newQty = double.tryParse(controller.text) ?? _currentItem.stockQuantity;
          final updated = await ref.read(itemRepositoryProvider).updateItem(
            _currentItem.id,
            {'stockQuantity': newQty},
          );
          if (mounted) {
            setState(() => _currentItem = updated);
            ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
            if (context.mounted) {
              NotificationService.showSuccess(context, 'Stock actualizado correctamente.');
            }
          }
        } catch (e) {
          if (mounted && context.mounted) {
            NotificationService.showError(context, 'Error al actualizar stock: $e');
          }
        }
      }
    }
  }

  Widget _buildBookingCard() {
    final item = _currentItem;
    final bool requires = item.requiresBooking;

    return _buildStatusCardTemplate(
      icon: requires ? Icons.calendar_month_outlined : Icons.offline_bolt_outlined,
      iconColor: requires ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
      bgColor: requires ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
      title: item.itemType == ItemType.product ? 'Entrega' : 'Disponibilidad',
      desc: requires ? 'Requiere Reserva' : 'Servicio Inmediato',
    );
  }

  Widget _buildStatusCardTemplate({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildInstallmentsSection() {
    final item = _currentItem;
    final bool allowed = item.allowInstallments;
    final double fee = item.lateFeePercentage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allowed ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allowed ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: allowed ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allowed ? Icons.credit_card_outlined : Icons.credit_card_off_outlined,
              color: allowed ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allowed ? 'Apto para Pagos en Cuotas' : 'Solo Pago Único',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: allowed ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allowed
                      ? 'Los clientes pueden adquirir este artículo mediante financiamiento fraccionado. Recargo por mora establecido: ${fee.toStringAsFixed(1)}%.'
                      : 'Este artículo no acepta financiamiento en cuotas; requiere liquidación en una sola transacción.',
                  style: TextStyle(
                    fontSize: 12,
                    color: allowed ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesSection(List<Map<String, dynamic>> properties) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: properties.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final prop = properties[index];
          final key = prop['key'] as String;
          final type = prop['type'] as String;
          final value = prop['value'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildPropertyValue(type, value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPropertyValue(String type, dynamic value) {
    if (value == null) return const Text('N/A');

    switch (type) {
      case 'LIST':
        final list = List<String>.from(value);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.map((e) => _buildBadge(e)).toList(),
        );
      case 'COLOR_LIST':
        final list = List<String>.from(value);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((e) => _buildColorCircle(e)).toList(),
        );
      case 'BOOLEAN':
        return HugeIcon(
          icon: value == true ? HugeIcons.strokeRoundedTick01 : HugeIcons.strokeRoundedCancel01,
          color: value == true ? Colors.green : Colors.red,
          size: 18,
        );
      default:
        return Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 13),
        );
    }
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
    );
  }

  Widget _buildColorCircle(String hex) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _parseHexColor(hex),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _buildCustomizationGroupCard(CustomizationGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (group.minSelect > 0 || group.maxSelect > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${group.minSelect > 0 ? "Mín: ${group.minSelect}" : ""} ${group.maxSelect > 0 ? "Máx: ${group.maxSelect}" : ""}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...group.options.map((opt) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    opt.name,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  Text(
                    opt.price > 0 ? '+\$${opt.price.toStringAsFixed(2)}' : 'Incluido',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: opt.price > 0 ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    final item = _currentItem;
    final activeCount = item.variants.where((v) => v.isActive).length;
    final totalCount = item.variants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Variantes del Producto'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                '$activeCount de $totalCount activas',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        if (item.variantAxes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.variantAxes.map((axis) {
              final cleanValues = axis.values.map((v) {
                return v.contains('|') ? v.split('|')[0].trim() : v.trim();
              }).join(', ');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${axis.name}: $cleanValues',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: item.variants.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final variant = item.variants[index];
              final label = variant.axisValues.values.map((v) {
                return v.contains('|') ? v.split('|')[0].trim() : v.trim();
              }).join(' / ');
              final effectivePrice = variant.price ?? item.price;
              final isDepleted = item.trackInventory && variant.stockQuantity <= 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _buildVariantThumb(variant, item),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  label.isNotEmpty ? label : 'Variante ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: variant.isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!variant.isActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Pausada',
                                    style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                '\$${effectivePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: variant.price != null ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                ),
                              ),
                              if (variant.sku != null && variant.sku!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'SKU: ${variant.sku}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!item.trackInventory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ilimitado',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      )
                    else if (isDepleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: const Text(
                          'Agotado',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: Text(
                          '${variant.stockQuantity.toInt()} en stock',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVariantThumb(ItemVariant variant, Item item) {
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

    Widget content;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      if (imgUrl.startsWith('img_idx:')) {
        final idx = int.tryParse(imgUrl.replaceFirst('img_idx:', ''));
        if (idx != null && idx < item.images.length) {
          content = Image.network(
            _resolveImageUrl(item.images[idx]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8)),
          );
        } else {
          content = Image.network(
            _resolveImageUrl(item.mainImage),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8)),
          );
        }
      } else {
        content = Image.network(
          _resolveImageUrl(imgUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8)),
        );
      }
    } else if (item.mainImage.isNotEmpty) {
      content = Image.network(
        _resolveImageUrl(item.mainImage),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8)),
      );
    } else {
      content = const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF94A3B8));
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context, Item item) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirmar Eliminación',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Eliminar Artículo?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Estás seguro de que deseas eliminar "${item.title}"? Esta acción no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true && mounted && context.mounted) {
      try {
        await ref.read(itemListProvider.notifier).deleteItem(widget.storeId, item.id);
        if (mounted && context.mounted) {
          NotificationService.showSuccess(context, 'Artículo eliminado exitosamente');
          context.pop(true);
        }
      } catch (e) {
        if (mounted && context.mounted) {
          NotificationService.showError(context, 'Error al eliminar: $e');
        }
      }
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  void _openImageLightbox(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (ctx) {
        return _ItemImageLightboxDialog(
          images: images,
          initialIndex: initialIndex,
          resolveImageUrl: _resolveImageUrl,
        );
      },
    );
  }
}

class _ItemImageLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String Function(String) resolveImageUrl;

  const _ItemImageLightboxDialog({
    required this.images,
    required this.initialIndex,
    required this.resolveImageUrl,
  });

  @override
  State<_ItemImageLightboxDialog> createState() => _ItemImageLightboxDialogState();
}

class _ItemImageLightboxDialogState extends State<_ItemImageLightboxDialog> {
  late final PageController _modalController;
  late int _modalPageIndex;

  @override
  void initState() {
    super.initState();
    _modalPageIndex = widget.initialIndex;
    _modalController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _modalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _modalController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _modalPageIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imgUrl = widget.resolveImageUrl(widget.images[index]);
              return Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 200,
                      color: const Color(0xFF1E293B),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                          SizedBox(height: 8),
                          Text(
                            'No se pudo cargar la imagen',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_modalPageIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

