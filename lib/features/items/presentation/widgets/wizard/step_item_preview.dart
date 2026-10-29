import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';

class StepItemPreview extends ConsumerStatefulWidget {
  final String storeId;

  const StepItemPreview({
    super.key,
    required this.storeId,
  });

  @override
  ConsumerState<StepItemPreview> createState() => _StepItemPreviewState();
}

class _StepItemPreviewState extends ConsumerState<StepItemPreview>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _imagePageController = PageController();
  int _activeImagePage = 0;

  // Variant simulation state
  final Map<String, String> _simulatedAxisValues = {};
  int _simulatedQuantity = 1;
  DateTime _simulatedSelectedDate = DateTime.now();
  String? _simulatedSelectedSlotId;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  Color? _parseVariantColor(String value) {
    if (value.contains('|')) {
      final parts = value.split('|');
      if (parts.length > 1) {
        final hex = parts[1].trim().replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
    } else {
      final hex = value.trim().replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  String _getVariantDisplayLabel(String value) {
    if (value.contains('|')) {
      return value.split('|')[0].trim();
    }
    return value.trim();
  }

  bool _matchesAxisValue(String? a, String? b) {
    if (a == null || b == null) return false;
    if (a == b) return true;
    final cleanA = a.contains('|') ? a.split('|')[0].trim() : a.trim();
    final cleanB = b.contains('|') ? b.split('|')[0].trim() : b.trim();
    return cleanA.toLowerCase() == cleanB.toLowerCase();
  }

  String? _parseVariantImageUrl(String value) {
    if (value.contains('|')) {
      final parts = value.split('|');
      if (parts.length > 2 && parts[2].trim().isNotEmpty) {
        return parts[2].trim();
      }
    }
    return null;
  }

  String? _resolveVariantImageUrl(ItemFormState state, VariantAxis axis, String val) {
    final fromVal = _parseVariantImageUrl(val);
    if (fromVal != null && fromVal.isNotEmpty) return fromVal;
    for (final v in state.variants) {
      if (_matchesAxisValue(v.axisValues[axis.name], val) &&
          v.imageUrl != null &&
          v.imageUrl!.isNotEmpty) {
        return v.imageUrl;
      }
    }
    return null;
  }

  bool _isAxisValueAvailable(ItemFormState state, VariantAxis axis, String val) {
    if (!state.trackInventory) return true;
    final activeForValue = state.variants.where((v) {
      if (!v.isActive) return false;
      if (!_matchesAxisValue(v.axisValues[axis.name], val)) return false;
      for (final entry in _simulatedAxisValues.entries) {
        if (entry.key != axis.name &&
            !_matchesAxisValue(v.axisValues[entry.key], entry.value)) {
          return false;
        }
      }
      return true;
    }).toList();

    if (activeForValue.isEmpty) return true;
    return activeForValue.any((v) => v.stockQuantity > 0);
  }

  ItemVariant? _getSimulatedVariant(ItemFormState state) {
    if (!state.hasVariants || state.variantAxes.isEmpty || state.variants.isEmpty) {
      return null;
    }
    for (final variant in state.variants) {
      bool matches = true;
      for (final axis in state.variantAxes) {
        final selectedVal = _simulatedAxisValues[axis.name];
        if (selectedVal != null &&
            !_matchesAxisValue(variant.axisValues[axis.name], selectedVal)) {
          matches = false;
          break;
        }
      }
      if (matches) return variant;
    }
    return null;
  }

  Widget? _buildVariantImageWidget(
    String? imageRef,
    ItemFormState state, {
    double size = 48,
    double radius = 10,
  }) {
    if (imageRef == null || imageRef.isEmpty) return null;

    Widget imageContent;
    if (imageRef.startsWith('img_idx:')) {
      final idx = int.tryParse(imageRef.replaceFirst('img_idx:', ''));
      if (idx != null) {
        if (idx < state.existingImages.length) {
          imageContent = Image.network(
            _resolveImageUrl(state.existingImages[idx]),
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.image_not_supported_outlined,
              size: size * 0.5,
              color: const Color(0xFF94A3B8),
            ),
          );
        } else {
          final fileIdx = idx - state.existingImages.length;
          if (fileIdx >= 0 && fileIdx < state.selectedImages.length) {
            imageContent = Image.file(
              state.selectedImages[fileIdx],
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                size: size * 0.5,
                color: const Color(0xFF94A3B8),
              ),
            );
          } else {
            return null;
          }
        }
      } else {
        return null;
      }
    } else {
      imageContent = Image.network(
        _resolveImageUrl(imageRef),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported_outlined,
          size: size * 0.5,
          color: const Color(0xFF94A3B8),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageContent,
      ),
    );
  }

  void _showFullScreenImageViewer(BuildContext context, String imageRef, ItemFormState state) {
    Widget imageWidget;
    if (imageRef.startsWith('img_idx:')) {
      final idx = int.tryParse(imageRef.replaceFirst('img_idx:', ''));
      if (idx != null && idx >= state.existingImages.length) {
        final fileIdx = idx - state.existingImages.length;
        if (fileIdx >= 0 && fileIdx < state.selectedImages.length) {
          imageWidget = Image.file(
            state.selectedImages[fileIdx],
            fit: BoxFit.contain,
          );
        } else {
          imageWidget = const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white70);
        }
      } else if (idx != null && idx < state.existingImages.length) {
        imageWidget = Image.network(
          _resolveImageUrl(state.existingImages[idx]),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          },
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white70),
        );
      } else {
        imageWidget = const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white70);
      }
    } else {
      imageWidget = Image.network(
        _resolveImageUrl(imageRef),
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white70),
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: imageWidget,
                ),
              ),
              Positioned(
                top: MediaQuery.of(ctx).padding.top + 16,
                right: 16,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(itemFormProvider);
    final storeState = ref.watch(storeDetailsProvider).forStore(widget.storeId);

    // Initialize simulated axes with first available value if empty
    if (state.hasVariants) {
      for (final axis in state.variantAxes) {
        if (!_simulatedAxisValues.containsKey(axis.name) && axis.values.isNotEmpty) {
          _simulatedAxisValues[axis.name] = axis.values.first;
        }
      }
    }

    final matchedVariant = _getSimulatedVariant(state);
    final variantPrice = matchedVariant?.price;
    final variantDiscountPrice = matchedVariant?.discountPrice;
    final bool hasVariantDiscount = variantDiscountPrice != null && variantDiscountPrice > 0;

    final double activePrice;
    if (hasVariantDiscount) {
      activePrice = variantDiscountPrice;
    } else if (variantPrice != null && variantPrice > 0) {
      activePrice = variantPrice;
    } else if (state.discountPrice != null && state.discountPrice! > 0) {
      activePrice = state.discountPrice!;
    } else {
      activePrice = state.price;
    }

    final double? originalPrice;
    if (hasVariantDiscount) {
      originalPrice = variantPrice ?? state.price;
    } else if (state.discountPrice != null && state.discountPrice! > 0) {
      originalPrice = state.price;
    } else {
      originalPrice = null;
    }

    final categoryMatches = storeState.categories.where((c) => c.id == state.categoryId);
    final categoryName = categoryMatches.isNotEmpty
        ? categoryMatches.first.name
        : 'General';

    final isServiceWithSlots = state.itemType == ItemType.service &&
        state.requiresBooking;
    final isPreOrderProduct = state.itemType == ItemType.product &&
        state.requiresBooking;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de aviso de previsualización
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: const Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedEye,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vista previa interactiva: Así se presentará tu artículo a los compradores en la app.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TARJETA PRINCIPAL ESTILO APP CLIENTE
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Carrusel de Imágenes
                _buildImageCarousel(state),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges de Categoría y Estado
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildBadge(
                            label: categoryName,
                            bgColor: const Color(0xFFEEF2FF),
                            textColor: const Color(0xFF4F46E5),
                          ),
                          if (state.isFeatured)
                            _buildBadge(
                              label: '★ Destacado',
                              bgColor: const Color(0xFFFEF3C7),
                              textColor: const Color(0xFFD97706),
                            ),
                          if (state.isAgeRestricted)
                            _buildBadge(
                              label: '+18 Adultos',
                              bgColor: const Color(0xFFFEE2E2),
                              textColor: const Color(0xFFDC2626),
                            ),
                          if (state.requiresBooking)
                            _buildBadge(
                              label: 'Reserva requerida',
                              bgColor: const Color(0xFFEDE9FE),
                              textColor: const Color(0xFF7C3AED),
                            ),
                          _buildBadge(
                            label: state.isActive ? 'Público' : 'Borrador',
                            bgColor: state.isActive
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFF1F5F9),
                            textColor: state.isActive
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Título del artículo
                      Text(
                        state.title.trim().isEmpty ? 'Nombre del Artículo' : state.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Precios y Descuentos
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            state.priceType == PriceType.free
                                ? 'GRATIS'
                                : '\$${activePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: state.priceType == PriceType.free
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (originalPrice != null && originalPrice > activePrice) ...[
                            const SizedBox(width: 10),
                            Text(
                              '\$${originalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${(((originalPrice - activePrice) / originalPrice) * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Pagos en cuotas
                      if (state.allowInstallments && activePrice > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                size: 15,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Disponible en cuotas flexibles (+multa por retraso: ${state.lateFeePercentage.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      _buildAvailabilityBadge(state, matchedVariant),

                      // Pre-Order Info Card (Preventa)
                      if (isPreOrderProduct) ...[
                        const SizedBox(height: 16),
                        _buildPreOrderInfoCard(state, activePrice),
                      ],

                      // Servicio: Selector de Turnos y Agenda de Citas (1:1 con app cliente)
                      if (isServiceWithSlots) ...[
                        const SizedBox(height: 16),
                        _buildServiceBookingSection(state),
                      ],

                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 14),

                      // Simulador Interactivo de Variantes (Solo productos físicos con variantes)
                      if (!isServiceWithSlots && state.hasVariants && state.variantAxes.isNotEmpty) ...[
                        _buildVariantSimulator(state, activePrice),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 14),
                      ],

                      // Descripción
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.description.trim().isEmpty
                            ? 'Sin descripción redactada aún.'
                            : state.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),

                      // Grupos de Personalización / Extras
                      if (state.customizationGroups.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 14),
                        const Text(
                          'Personalizaciones y Extras incluidos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...state.customizationGroups.map((group) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (group.minSelect > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Obligatorio',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (group.options.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: group.options.map((opt) {
                                      return Chip(
                                        padding: EdgeInsets.zero,
                                        label: Text(
                                          '${opt.name}${opt.price > 0 ? " (+\$${opt.price.toStringAsFixed(2)})" : ""}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],

                      // Propiedades Adicionales
                      if (state.attributes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 14),
                        const Text(
                          'Ficha Técnica y Propiedades',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.attributes.entries.map((entry) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value}',
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
                      const SizedBox(height: 20),
                      // Botón de acción interactivo (idéntico a la experiencia en app de clientes)
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HugeIcon(
                                    icon: isServiceWithSlots
                                        ? HugeIcons.strokeRoundedCalendar03
                                        : (isPreOrderProduct
                                            ? HugeIcons.strokeRoundedDeliveryBox01
                                            : HugeIcons.strokeRoundedShoppingBag02),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    isServiceWithSlots
                                        ? (_simulatedSelectedSlotId != null
                                            ? 'Reservar Cita • \$${activePrice.toStringAsFixed(2)}'
                                            : 'Selecciona un Horario')
                                        : (isPreOrderProduct
                                            ? 'Reservar en Preventa • \$${activePrice.toStringAsFixed(2)}'
                                            : 'Agregar al Carrito • \$${activePrice.toStringAsFixed(2)}'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Resumen de Inventario y Publicación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isServiceWithSlots
                            ? const Color(0xFF7C3AED)
                            : (isPreOrderProduct
                                ? const Color(0xFFD97706)
                                : const Color(0xFF10B981)))
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: isServiceWithSlots
                        ? HugeIcons.strokeRoundedCalendar03
                        : (isPreOrderProduct
                            ? HugeIcons.strokeRoundedDeliveryBox01
                            : HugeIcons.strokeRoundedPackage),
                    color: isServiceWithSlots
                        ? const Color(0xFF7C3AED)
                        : (isPreOrderProduct
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isServiceWithSlots
                            ? 'Servicio con agenda de turnos (${(state.slotConfig['slots'] as List?)?.length ?? 0} configurados)'
                            : (isPreOrderProduct
                                ? 'Producto en Preventa (${state.preorderConfig['maxPreOrderUnits'] ?? 0} cupos máx.)'
                                : (state.trackInventory
                                    ? (state.hasVariants
                                        ? (matchedVariant != null
                                            ? 'Stock de la variante seleccionada: ${matchedVariant.stockQuantity.toInt()} unidades'
                                            : 'Inventario controlado por ${state.variants.length} variantes')
                                        : 'Stock disponible: ${state.stockQuantity?.toInt() ?? 0} unidades')
                                    : 'Stock ilimitado (Sin control de existencias)')),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.isActive
                            ? 'El artículo será visible inmediatamente tras publicar.'
                            : 'Guardado como borrador (no visible para clientes).',
                        style: TextStyle(
                          fontSize: 11,
                          color: state.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
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
    );
  }

  // --- CARRUSEL DE IMÁGENES ---
  Widget _buildImageCarousel(ItemFormState state) {
    final totalImages = state.existingImages.length + state.selectedImages.length;

    if (totalImages == 0) {
      return Container(
        height: 240,
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 8),
              Text(
                'Sin fotos seleccionadas',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _imagePageController,
            itemCount: totalImages,
            onPageChanged: (i) => setState(() => _activeImagePage = i),
            itemBuilder: (context, index) {
              final bool isExisting = index < state.existingImages.length;
              if (isExisting) {
                return Image.network(
                  _resolveImageUrl(state.existingImages[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFCBD5E1),
                    child: const Icon(Icons.broken_image, size: 36, color: Colors.white),
                  ),
                );
              } else {
                return Image.file(
                  state.selectedImages[index - state.existingImages.length],
                  fit: BoxFit.cover,
                );
              }
            },
          ),
        ),

        // Dots indicator
        if (totalImages > 1)
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalImages, (index) {
                  final isActive = index == _activeImagePage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  // --- SIMULADOR DE VARIANTES ---
  Widget _buildVariantSimulator(ItemFormState state, double activePrice) {
    final hasAnyAvailableVariant = !state.trackInventory ||
        state.variants.any((v) => v.isActive && v.stockQuantity > 0);

    if (!hasAnyAvailableVariant) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto agotado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Todas las variantes de este artículo se encuentran agotadas actualmente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Opciones del producto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Toca para simular',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...state.variantAxes.map((axis) {
          final isColorAxis = axis.name.trim().toLowerCase() == 'color' ||
              axis.name.trim().toLowerCase() == 'colores' ||
              axis.values.any((v) => v.contains('#'));
          final currentVal = _simulatedAxisValues[axis.name];

          final displayedValues = axis.values.where((val) {
            if (!state.trackInventory) return true;
            return _isAxisValueAvailable(state, axis, val);
          }).toList();

          if (displayedValues.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      axis.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    if (currentVal != null)
                      Text(
                        _getVariantDisplayLabel(currentVal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      )
                    else
                      const Text(
                        '* Requerido',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isColorAxis) ...[
                  // Filas estilizadas de variantes de color (exactas a la app de clientes)
                  Column(
                    children: displayedValues.map((val) {
                      final isSelected = currentVal != null && _matchesAxisValue(currentVal, val);
                      final isAvailable = _isAxisValueAvailable(state, axis, val);
                      final displayLabel = _getVariantDisplayLabel(val);
                      final color = _parseVariantColor(val);
                      final imageUrl = _resolveVariantImageUrl(state, axis, val);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: isAvailable
                              ? () => setState(() => _simulatedAxisValues[axis.name] = val)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEEF2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                // 1. Miniatura con zoom opcional (48x48)
                                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () => _showFullScreenImageViewer(context, imageUrl, state),
                                    child: Stack(
                                      children: [
                                        _buildVariantImageWidget(
                                          imageUrl,
                                          state,
                                          size: 48,
                                          radius: 10,
                                        ) ?? const SizedBox.shrink(),
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.55),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.zoom_in_rounded,
                                              size: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],

                                // 2. Color Swatch circular con borde
                                if (color != null) ...[
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],

                                // 3. Nombre del color y estado
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        displayLabel,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isAvailable
                                              ? (isSelected
                                                  ? const Color(0xFF312E81)
                                                  : const Color(0xFF1E293B))
                                              : const Color(0xFF94A3B8),
                                          decoration: isAvailable
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isAvailable)
                                        const Text(
                                          'No disponible',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFEF4444),
                                          ),
                                        )
                                      else if (isSelected)
                                        const Text(
                                          'Seleccionado',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 4. Contador de cantidad [-] [ 1 ] [+]
                                _buildRowStepper(
                                  isSelected: isSelected,
                                  isAvailable: isAvailable,
                                  quantity: _simulatedQuantity,
                                  onTapSelect: () => setState(() => _simulatedAxisValues[axis.name] = val),
                                  onIncrease: () => setState(() => _simulatedQuantity++),
                                  onDecrease: () => setState(() {
                                    if (_simulatedQuantity > 1) _simulatedQuantity--;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // Regular Axis (Text chip wrap estilo app de clientes)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: displayedValues.map((val) {
                      final isSelected = currentVal != null && _matchesAxisValue(currentVal, val);
                      final isAvailable = _isAxisValueAvailable(state, axis, val);
                      final displayLabel = _getVariantDisplayLabel(val);

                      return GestureDetector(
                        onTap: isAvailable
                            ? () => setState(() => _simulatedAxisValues[axis.name] = val)
                            : null,
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEEF2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4F46E5)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              displayLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),

        // Barra de Acción / Total Simulado
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total simulado',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${(activePrice * _simulatedQuantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedShoppingBag02,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Agregar al Carrito',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityBadge(ItemFormState state, ItemVariant? variant) {
    final isServiceWithSlots = state.itemType == ItemType.service &&
        state.requiresBooking;
    final isPreOrderProduct = state.itemType == ItemType.product &&
        state.requiresBooking;

    if (isServiceWithSlots) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  size: 13,
                  color: Color(0xFF4F46E5),
                ),
                SizedBox(width: 5),
                Text(
                  'CITA / AGENDA',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Turnos disponibles',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF4F46E5),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    if (isPreOrderProduct) {
      final config = state.preorderConfig;
      final maxUnits = config['maxPreOrderUnits'] as int?;
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PREVENTA',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              maxUnits != null && maxUnits > 0
                  ? 'Cupos disponibles ($maxUnits restantes)'
                  : 'Fabricación bajo encargo disponible',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    if (!state.trackInventory) {
      return Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedTick01,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'En stock (Ilimitado)',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (state.hasVariants) {
      if (variant == null) {
        return const Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
              color: Color(0xFF6B7280),
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              'Selecciona las opciones para ver disponibilidad',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        );
      }

      final stock = variant.stockQuantity;
      if (stock <= 0) {
        return Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: Colors.redAccent,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Agotado en esta opción',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        );
      } else if (stock <= 5) {
        return Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedAlert01,
              color: Colors.deepOrange,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '¡Apurate, solo quedan ${stock.toInt()} unidades!',
              style: TextStyle(
                color: Colors.deepOrange.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedTick01,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'En stock (${stock.toInt()} disponibles)',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        );
      }
    }

    final stock = state.stockQuantity ?? 0;
    if (stock <= 0) {
      return Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            color: Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Agotado',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedTick01,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'En stock (${stock.toInt()} unidades)',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRowStepper({
    required bool isSelected,
    required bool isAvailable,
    required int quantity,
    required VoidCallback onTapSelect,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    if (!isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Agotado',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón Menos
          InkWell(
            onTap: isSelected && quantity > 1 ? onDecrease : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected && quantity > 1
                    ? const Color(0xFFF1F5F9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.remove_rounded,
                size: 14,
                color: isSelected && quantity > 1
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          // Indicador de Cantidad
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              isSelected ? '$quantity' : '1',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
          // Botón Más
          InkWell(
            onTap: isSelected ? onIncrease : onTapSelect,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.add_rounded,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPreOrderInfoCard(ItemFormState state, double activePrice) {
    final config = state.preorderConfig;
    final leadMin = config['estimatedLeadDaysMin'] ?? 7;
    final leadMax = config['estimatedLeadDaysMax'] ?? 15;
    final depositType = config['depositType'] ?? 'PERCENTAGE';
    final depositVal = (config['depositValue'] ?? 50.0) is num
        ? (config['depositValue'] as num).toDouble()
        : 50.0;

    final double depositAmount;
    final String depositLabel;
    if (depositType == 'FIXED_AMOUNT') {
      depositAmount = depositVal;
      depositLabel = '\$${depositVal.toStringAsFixed(2)} fijo';
    } else {
      depositAmount = (activePrice * depositVal) / 100.0;
      depositLabel = '${depositVal.toInt()}% (\$${depositAmount.toStringAsFixed(2)})';
    }
    final remainingBalance = (activePrice - depositAmount).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDeliveryBox01,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Artículo Bajo Pedido (Preventa)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      'Tiempo estimado: $leadMin - $leadMax días hábiles',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pago Inicial / Seña Requerida:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    Text(
                      depositLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                if (remainingBalance > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saldo restante contra entrega:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      Text(
                        '\$${remainingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceBookingSection(ItemFormState state) {
    final config = state.slotConfig;
    final minNoticeHours = config['minNoticeHours'] ?? 2;
    final durationMinutes = config['serviceDurationMinutes'] ?? 60;
    final rawSlots = (config['slots'] as List?) ?? [];
    final slots = rawSlots.whereType<Map>().map((s) => Map<String, dynamic>.from(s)).toList();

    // Filter slots for the selected simulation date
    final selectedWeekday = _simulatedSelectedDate.weekday;
    final selectedDateStr =
        '${_simulatedSelectedDate.year}-${_simulatedSelectedDate.month.toString().padLeft(2, '0')}-${_simulatedSelectedDate.day.toString().padLeft(2, '0')}';

    final matchingSlots = slots.where((s) {
      if (s['isActive'] == false) return false;
      final specificDate = s['specificDate']?.toString();
      if (specificDate != null && specificDate.isNotEmpty) {
        return specificDate == selectedDateStr;
      }
      final dayVal = s['dayOfWeek'];
      if (dayVal == null) return true; // Repeats all days
      return dayVal == selectedWeekday;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agenda y Horarios de Citas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Duración aprox: $durationMinutes min • Mín. ${minNoticeHours}h de aviso',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector horizontal de fechas (14 días próximos)
          const Text(
            'Selecciona el día:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = date.year == _simulatedSelectedDate.year &&
                    date.month == _simulatedSelectedDate.month &&
                    date.day == _simulatedSelectedDate.day;

                final dayNames = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
                final monthNames = [
                  'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
                  'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
                ];

                final dayName = dayNames[date.weekday - 1];
                final monthName = monthNames[date.month - 1];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _simulatedSelectedDate = date;
                      _simulatedSelectedSlotId = null;
                    });
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Horarios Disponibles
          const Text(
            'Horarios para la fecha seleccionada:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 10),

          if (matchingSlots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8), size: 30),
                  SizedBox(height: 6),
                  Text(
                    'No hay turnos configurados para esta fecha.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Configura más turnos en el paso anterior o toca otro día.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matchingSlots.asMap().entries.map((entry) {
                final idx = entry.key;
                final slot = entry.value;
                final slotId = slot['id']?.toString() ?? 'slot_$idx';
                final startTime = slot['startTime']?.toString() ?? '';
                final endTime = slot['endTime']?.toString() ?? '';
                final label = slot['label']?.toString() ?? 'Turno';
                final isSelected = _simulatedSelectedSlotId == slotId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _simulatedSelectedSlotId = isSelected ? null : slotId;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                        width: isSelected ? 2 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Disponible',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$startTime - $endTime',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
