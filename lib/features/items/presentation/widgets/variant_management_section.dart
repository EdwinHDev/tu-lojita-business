import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../domain/entities/item.dart';
import '../providers/item_form_provider.dart';

class VariantManagementSection extends ConsumerStatefulWidget {
  const VariantManagementSection({super.key});

  @override
  ConsumerState<VariantManagementSection> createState() =>
      _VariantManagementSectionState();
}

class _VariantManagementSectionState
    extends ConsumerState<VariantManagementSection> {
  // Predefined commercial color presets for the Color axis (16 e-commerce essentials)
  static const List<Map<String, dynamic>> _colorPresets = [
    {'name': 'Negro', 'hex': '#000000', 'color': Color(0xFF000000)},
    {'name': 'Blanco', 'hex': '#FFFFFF', 'color': Color(0xFFFFFFFF)},
    {'name': 'Gris Plomo', 'hex': '#475569', 'color': Color(0xFF475569)},
    {'name': 'Azul Marino', 'hex': '#0F172A', 'color': Color(0xFF0F172A)},
    {'name': 'Azul Rey', 'hex': '#2563EB', 'color': Color(0xFF2563EB)},
    {'name': 'Azul Cielo', 'hex': '#38BDF8', 'color': Color(0xFF38BDF8)},
    {'name': 'Verde Oliva', 'hex': '#556B2F', 'color': Color(0xFF556B2F)},
    {'name': 'Verde Esmeralda', 'hex': '#10B981', 'color': Color(0xFF10B981)},
    {'name': 'Vino Tinto', 'hex': '#800020', 'color': Color(0xFF800020)},
    {'name': 'Rojo Carmín', 'hex': '#EF4444', 'color': Color(0xFFEF4444)},
    {'name': 'Terracota', 'hex': '#C86446', 'color': Color(0xFFC86446)},
    {'name': 'Naranja', 'hex': '#F97316', 'color': Color(0xFFF97316)},
    {'name': 'Mostaza', 'hex': '#D97706', 'color': Color(0xFFD97706)},
    {'name': 'Beige', 'hex': '#F5F5DC', 'color': Color(0xFFF5F5DC)},
    {'name': 'Marrón Café', 'hex': '#78350F', 'color': Color(0xFF78350F)},
    {'name': 'Rosa Pastel', 'hex': '#F472B6', 'color': Color(0xFFF472B6)},
  ];

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  Widget? _buildVariantImageWidget(
    String? imageRef,
    ItemFormState state, {
    double size = 36,
    double radius = 8,
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

  void _showProductImagePickerSheet({
    required BuildContext context,
    required ItemFormState state,
    required String? currentImageRef,
    required ValueChanged<String?> onImageSelected,
  }) {
    final totalImages =
        state.existingImages.length + state.selectedImages.length;

    _showAppBottomSheet(
      context: context,
      title: 'Fotos del Producto',
      subtitle: totalImages > 0
          ? 'Selecciona la foto para este color'
          : 'No has agregado fotos al producto aún',
      builder: (ctx, setSheetState) {
        if (totalImages == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedImage01,
                    size: 36,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sin fotos disponibles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sube fotos del producto en la sección "Información Básica" para poder asociarlas a cada color.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: totalImages,
              itemBuilder: (context, index) {
                final isExisting = index < state.existingImages.length;
                final imageRef = isExisting
                    ? state.existingImages[index]
                    : 'img_idx:$index';
                final isSelected = currentImageRef == imageRef ||
                    (currentImageRef != null &&
                        isExisting &&
                        currentImageRef == state.existingImages[index]);

                return GestureDetector(
                  onTap: () {
                    onImageSelected(imageRef);
                    Navigator.pop(ctx);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 3 : 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: isExisting
                              ? Image.network(
                                  _resolveImageUrl(state.existingImages[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : Image.file(
                                  state.selectedImages[
                                      index - state.existingImages.length],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                ),

                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4F46E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      bottomAction: currentImageRef != null && currentImageRef.isNotEmpty
          ? SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text(
                  'Desvincular Imagen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  onImageSelected(null);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemFormProvider);
    final notifier = ref.read(itemFormProvider.notifier);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Variantes del Artículo'),
        const SizedBox(height: 12),
        _buildCard([
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const HugeIcon(
              icon: HugeIcons.strokeRoundedLayers01,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
            title: const Text(
              'Habilitar Variantes',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Tallas, colores, materiales con precio y stock independiente',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            value: state.hasVariants,
            activeThumbColor: const Color(0xFF4F46E5),
            onChanged: (enabled) => _handleToggleVariants(enabled, state, notifier),
          ),
          if (state.hasVariants) ...[
            const Divider(height: 24),
            _buildExplanationBanner(),
            const SizedBox(height: 16),
            _buildAxesHeader(state, notifier),
            const SizedBox(height: 12),
            ...state.variantAxes.asMap().entries.map(
                  (entry) => _buildAxisCard(entry.key, entry.value, state, notifier),
                ),

            if (state.variantAxes.length < 3) ...[
              const SizedBox(height: 8),
              _buildAddAxisButton(notifier),
            ],
            if (state.variants.isNotEmpty && state.variantAxes.length > 1) ...[
              const Divider(height: 32),
              _buildVariantsHeader(state, notifier),
              const SizedBox(height: 12),
              _buildBatchActionsBar(state, notifier),
              const SizedBox(height: 16),
              ...state.variants.asMap().entries.map(
                    (entry) => _buildVariantCard(
                      entry.key,
                      entry.value,
                      state.price,
                      state,
                      notifier,
                    ),
                  ),

            ],
          ],
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildExplanationBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: Color(0xFF4F46E5),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aclaratoria de Precios: El precio de cada opción es el precio final sustitutivo de compra; NO se suma al precio base de vitrina.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF3730A3),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxesHeader(ItemFormState state, ItemFormNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'EJES DE VARIACIÓN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.variantAxes.length}/3 ejes',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddAxisButton(ItemFormNotifier notifier) {
    return OutlinedButton.icon(
      onPressed: () => _showAddAxisDialog(notifier),
      icon: const HugeIcon(
        icon: HugeIcons.strokeRoundedAdd01,
        color: Color(0xFF4F46E5),
        size: 18,
      ),
      label: const Text('Agregar Eje (Talla, Color...)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4F46E5),
        side: const BorderSide(color: Color(0xFFC7D2FE)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAxisCard(
      int index, VariantAxis axis, ItemFormState state, ItemFormNotifier notifier) {

    final isColorAxis =
        axis.name.trim().toLowerCase() == 'color' ||
        axis.name.trim().toLowerCase() == 'colores';
    final isSingleAxis = state.variantAxes.length == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HugeIcon(
                      icon: isColorAxis
                          ? HugeIcons.strokeRoundedPaintBoard
                          : HugeIcons.strokeRoundedTag01,
                      color: const Color(0xFF4F46E5),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    axis.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (isColorAxis) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Eje Color',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
                tooltip: 'Eliminar eje',
                onPressed: () => _confirmDeleteAxis(index, axis.name, notifier),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isSingleAxis) ...[
            if (axis.values.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isColorAxis
                      ? 'No has agregado colores aún.'
                      : 'No has agregado opciones aún.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: axis.values.map(
                  (val) => _buildUnifiedOptionCard(
                    val,
                    index,
                    axis,
                    isColorAxis,
                    state,
                    notifier,
                    () {
                      final newVals = List<String>.from(axis.values)..remove(val);
                      notifier.updateAxisValues(index, newVals);
                    },
                  ),
                ).toList(),
              ),
            const SizedBox(height: 8),
            if (isColorAxis)
              _buildAddColorCardButton(index, axis, notifier)
            else
              _buildAddGeneralOptionButton(index, axis, notifier),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...axis.values.map(
                  (val) => _buildPillChip(
                    val,
                    () {
                      final newVals = List<String>.from(axis.values)..remove(val);
                      notifier.updateAxisValues(index, newVals);
                    },
                  ),
                ),
                _buildAddValueChip(index, axis, isColorAxis, notifier),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillChip(String value, VoidCallback onDelete) {
    Color? chipColor;
    String displayLabel = value;
    if (value.contains('|')) {
      final parts = value.split('|');
      displayLabel = parts[0];
      if (parts.length > 1) {
        final hex = parts[1].replaceAll('#', '');
        if (hex.length == 6) {
          chipColor = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          chipColor = Color(int.parse(hex, radix: 16));
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chipColor != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 1),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              displayLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddGeneralOptionButton(
      int axisIndex, VariantAxis axis, ItemFormNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Color(0xFF4F46E5),
          size: 16,
        ),
        label: Text('Agregar opción a ${axis.name}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFC7D2FE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => _showAddValueDialog(axisIndex, axis, notifier),
      ),
    );
  }

  Widget _buildUnifiedOptionCard(
    String value,
    int axisIndex,
    VariantAxis axis,
    bool isColorAxis,
    ItemFormState state,
    ItemFormNotifier notifier,
    VoidCallback onDelete,
  ) {
    Color? chipColor;
    String displayLabel = value;
    String hexCode = '';
    String? imageUrl;

    if (value.contains('|')) {
      final parts = value.split('|');
      displayLabel = parts[0];
      if (parts.length > 1) {
        hexCode = parts[1];
        final hex = parts[1].replaceAll('#', '');
        if (hex.length == 6) {
          chipColor = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          chipColor = Color(int.parse(hex, radix: 16));
        }
      }
      if (parts.length > 2 && parts[2].trim().isNotEmpty) {
        imageUrl = parts[2].trim();
      }
    }

    // Buscar la variante correspondiente en state.variants
    int variantIndex = -1;
    ItemVariant? variant;
    for (int i = 0; i < state.variants.length; i++) {
      final v = state.variants[i];
      if (_matchesAxisValue(v.axisValues[axis.name], value)) {
        variant = v;
        variantIndex = i;
        break;
      }
    }

    final imageWidget = _buildVariantImageWidget(imageUrl, state, size: 48, radius: 10);
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final parentPrice = state.price;
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (variant?.isActive ?? true) ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (variant?.isActive ?? true)
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBD5E1),
        ),
        boxShadow: (variant?.isActive ?? true)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila Principal: Miniatura Foto, Swatch, Nombre, Checkbox Activo, Eliminar ──
          Row(
            children: [
              // 1. Selector de foto (48x48)
              GestureDetector(
                onTap: () {
                  _showProductImagePickerSheet(
                    context: context,
                    state: state,
                    currentImageRef: imageUrl,
                    onImageSelected: (newRef) {
                      final parts = value.split('|');
                      final name = parts[0];
                      final hex = parts.length > 1 ? parts[1] : '#000000';
                      final updatedVal = newRef != null && newRef.isNotEmpty
                          ? '$name|$hex|$newRef'
                          : '$name|$hex';
                      final newVals = List<String>.from(axis.values);
                      final idx = newVals.indexWhere((val) {
                        final base = val.contains('|')
                            ? val.split('|')[0].trim().toLowerCase()
                            : val.trim().toLowerCase();
                        return base == name.trim().toLowerCase();
                      });
                      if (idx != -1) {
                        newVals[idx] = updatedVal;
                        notifier.updateAxisValues(axisIndex, newVals);
                      }
                    },
                  );
                },
                child: Stack(
                  children: [
                    if (imageWidget != null)
                      imageWidget
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasImage ? Icons.edit_rounded : Icons.add_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 2. Swatch de color (si aplica)
              if (chipColor != null) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: chipColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 1.2),
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

              // 3. Nombre del color/opción
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
                        color: (variant?.isActive ?? true)
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasImage
                          ? '${hexCode.isNotEmpty ? "$hexCode • " : ""}Foto vinculada'
                          : (hexCode.isNotEmpty ? hexCode : 'Toca la foto para vincular'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: hasImage ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Checkbox de Activación
              if (variant != null && variantIndex != -1)
                Transform.scale(
                  scale: 0.85,
                  child: Checkbox(
                    value: variant.isActive,
                    activeColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      notifier.updateVariant(
                        variantIndex,
                        variant!.copyWith(isActive: val ?? true),
                      );
                    },
                  ),
                ),

              // 5. Botón Eliminar
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                tooltip: 'Eliminar opción',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),

          if (variant != null && variantIndex != -1) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // ── Fila de Inputs: Precio Opción ($) y Stepper de Stock [-] [ 1 ] [+] ──
            Row(
              children: [
                // Campo Precio
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: ValueKey('price_$variantIndex'),
                    selectAllOnFocus: false,
                    enabled: user?.canChangePrices ?? true,
                    initialValue: variant.price != null
                        ? variant.price!.toStringAsFixed(2)
                        : (parentPrice > 0 ? parentPrice.toStringAsFixed(2) : ''),
                    decoration: InputDecoration(
                      labelText: 'Precio Opción (\$)',
                      hintText: parentPrice > 0 ? parentPrice.toStringAsFixed(2) : '0.00',
                      prefixText: '\$ ',
                      labelStyle: const TextStyle(fontSize: 11),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (val) {
                      final p = double.tryParse(val);
                      notifier.updateVariant(variantIndex, variant!.copyWith(price: p));
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Stepper de Stock [-] [ Stock ] [+]
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        // Botón Menos
                        InkWell(
                          onTap: () {
                            final current = variant!.stockQuantity;
                            if (current > 0) {
                              notifier.updateVariant(
                                variantIndex,
                                variant.copyWith(stockQuantity: current - 1),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFF334155)),
                          ),
                        ),
                        // Cantidad / Input directo
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('stock_$variantIndex'),
                            selectAllOnFocus: false,
                            initialValue: variant.stockQuantity.toInt().toString(),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            onChanged: (val) {
                              final s = double.tryParse(val) ?? 0;
                              notifier.updateVariant(
                                variantIndex,
                                variant!.copyWith(stockQuantity: s),
                              );
                            },
                          ),
                        ),
                        // Botón Más
                        InkWell(
                          onTap: () {
                            final current = variant!.stockQuantity;
                            notifier.updateVariant(
                              variantIndex,
                              variant.copyWith(stockQuantity: current + 1),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddColorCardButton(
      int axisIndex, VariantAxis axis, ItemFormNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Color(0xFF4F46E5),
          size: 16,
        ),
        label: const Text('Agregar Color'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4F46E5),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFC7D2FE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => _showAddColorDialog(axisIndex, axis, notifier),
      ),
    );
  }


  Widget _buildAddValueChip(
      int axisIndex, VariantAxis axis, bool isColorAxis, ItemFormNotifier notifier) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 16, color: Color(0xFF4F46E5)),
      label: Text(
        isColorAxis ? 'Agregar color' : 'Agregar valor',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4F46E5),
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFFEEF2FF),
      side: const BorderSide(color: Color(0xFFC7D2FE)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        if (isColorAxis) {
          _showAddColorDialog(axisIndex, axis, notifier);
        } else {
          _showAddValueDialog(axisIndex, axis, notifier);
        }
      },
    );
  }

  Widget _buildVariantsHeader(ItemFormState state, ItemFormNotifier notifier) {
    final total = state.variants.length;
    final active = state.variants.where((v) => v.isActive).length;
    final isOverLimit = total > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'COMBINACIONES GENERADAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOverLimit
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$active activas de $total total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOverLimit
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        if (isOverLimit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                SizedBox(width: 6),
                Text(
                  'Supera el límite máximo de 100 variantes por artículo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBatchActionsBar(ItemFormState state, ItemFormNotifier notifier) {
    final allActive = state.variants.every((v) => v.isActive);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canChangePrice = user?.canChangePrices ?? true;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => notifier.toggleAllVariants(!allActive),
            icon: Icon(
              allActive ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
            ),
            label: Text(allActive ? 'Desactivar todas' : 'Activar todas'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          if (canChangePrice) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showBatchPriceDialog(notifier),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedCoins01,
                size: 16,
                color: Color(0xFF4F46E5),
              ),
              label: const Text('Precio a todas'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _showBatchStockDialog(notifier),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryBox01,
              size: 16,
              color: Color(0xFF4F46E5),
            ),
            label: const Text('Stock a todas'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantCard(
      int index,
      ItemVariant variant,
      double parentPrice,
      ItemFormState state,
      ItemFormNotifier notifier) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canChangePrice = user?.canChangePrices ?? true;
    final label = variant.axisValues.values
        .map((v) => v.contains('|') ? v.split('|')[0] : v)
        .join(' / ');

    Color? variantColor;
    String? variantImageRef = variant.imageUrl;

    for (final val in variant.axisValues.values) {
      if (val.contains('|')) {
        final parts = val.split('|');
        if (parts.length > 1 && variantColor == null) {
          final hex = parts[1].replaceAll('#', '');
          if (hex.length == 6) {
            variantColor = Color(int.parse('FF$hex', radix: 16));
          } else if (hex.length == 8) {
            variantColor = Color(int.parse(hex, radix: 16));
          }
        }
        if (parts.length > 2 &&
            (variantImageRef == null || variantImageRef.isEmpty)) {
          variantImageRef = parts[2].trim();
        }
      }
    }

    if (variantImageRef == null || variantImageRef.isEmpty || variantColor == null) {
      for (final axis in state.variantAxes) {
        final val = variant.axisValues[axis.name];
        if (val != null) {
          for (final axisVal in axis.values) {
            if (_matchesAxisValue(axisVal, val)) {
              if (axisVal.contains('|')) {
                final parts = axisVal.split('|');
                if (parts.length > 1 && variantColor == null) {
                  final hex = parts[1].replaceAll('#', '');
                  if (hex.length == 6) {
                    variantColor = Color(int.parse('FF$hex', radix: 16));
                  } else if (hex.length == 8) {
                    variantColor = Color(int.parse(hex, radix: 16));
                  }
                }
                if (parts.length > 2 && (variantImageRef == null || variantImageRef.isEmpty)) {
                  variantImageRef = parts[2].trim();
                }
              }
            }
          }
        }
      }
    }

    final imageWidget = _buildVariantImageWidget(variantImageRef, state,
        size: 44, radius: 8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: variant.isActive ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: variant.isActive
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: variant.isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: variant.isActive,
                activeColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  notifier.updateVariant(
                    index,
                    variant.copyWith(isActive: val ?? true),
                  );
                },
              ),
              if (imageWidget != null) ...[
                imageWidget,
                const SizedBox(width: 10),
              ],
              if (variantColor != null) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: variantColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label.isEmpty ? 'Variante ${index + 1}' : label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: variant.isActive
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              if (!variant.isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Inactiva',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('combo_price_$index'),
                  selectAllOnFocus: false,
                  enabled: canChangePrice,
                  initialValue: variant.price != null
                      ? variant.price!.toStringAsFixed(2)
                      : (parentPrice > 0 ? parentPrice.toStringAsFixed(2) : ''),
                  decoration: InputDecoration(
                    labelText: 'Precio Opción (\$)',
                    hintText: parentPrice > 0
                        ? parentPrice.toStringAsFixed(2)
                        : '0.00',
                    prefixText: '\$ ',
                    labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) {
                    final p = double.tryParse(val);
                    notifier.updateVariant(index, variant.copyWith(price: p));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey('combo_stock_$index'),
                  selectAllOnFocus: false,
                  initialValue: variant.stockQuantity.toInt().toString(),
                  decoration: InputDecoration(
                    labelText: 'Stock',
                    hintText: '0',
                    labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) {
                    final s = double.tryParse(val) ?? 0;
                    notifier.updateVariant(
                        index, variant.copyWith(stockQuantity: s));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Dialogs & Action Handlers ---

  void _handleToggleVariants(
      bool enabled, ItemFormState state, ItemFormNotifier notifier) {
    if (enabled) {
      if (state.itemId != null && (state.stockQuantity ?? 0) > 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Activar Variantes'),
            content: Text(
              'Tu stock actual (${state.stockQuantity?.toInt()} unidades) se reiniciará a 0 para que definas el inventario exacto por cada variante.\n\n¿Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.toggleVariants(true);
                },
                child: const Text('Continuar y Activar'),
              ),
            ],
          ),
        );
        return;
      }
      notifier.toggleVariants(true);
    } else {
      if (state.variants.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Desactivar Variantes'),
            content: const Text(
              'Al desactivar variantes, las configuraciones se mantendrán guardadas y el stock activo se sumará al inventario global del artículo.\n\n¿Deseas desactivarlas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  notifier.toggleVariants(false);
                },
                child: const Text('Desactivar'),
              ),
            ],
          ),
        );
        return;
      }
      notifier.toggleVariants(false);
    }
  }

  // =========================================================================
  // REUSABLE KEYBOARD-AWARE MODAL BOTTOM SHEET
  // =========================================================================
  Future<T?> _showAppBottomSheet<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget Function(BuildContext ctx, StateSetter setSheetState) builder,
    Widget? bottomAction,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
            final maxHeight = MediaQuery.of(ctx).size.height * 0.90;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ergonomic drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    // Scrollable content body (zero overflow)
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: builder(ctx, setSheetState),
                      ),
                    ),
                    // Docked bottom action in thumb zone
                    if (bottomAction != null)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: bottomAction,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 1. ADD AXIS BOTTOM SHEET (ZERO OVERFLOW)
  // =========================================================================
  void _showAddAxisDialog(ItemFormNotifier notifier) {
    final ctrl = TextEditingController();
    const suggestions = ['Talla', 'Color', 'Material', 'Capacidad', 'Modelo'];

    _showAppBottomSheet(
      context: context,
      title: 'Nuevo Eje de Variación',
      subtitle: 'Escribe el nombre del atributo o selecciona una sugerencia',
      builder: (ctx, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              selectAllOnFocus: false,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre del eje',
                hintText: 'Ej. Talla o Color',
                prefixIcon: const Icon(Icons.layers_rounded, color: Color(0xFF4F46E5), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sugerencias populares:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: suggestions
                  .map(
                    (s) => ActionChip(
                      avatar: const Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
                      label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      backgroundColor: const Color(0xFFEEF2FF),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onPressed: () {
                        setSheetState(() {
                          ctrl.text = s;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
      bottomAction: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_rounded, size: 20),
          label: const Text(
            'Crear Eje',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              notifier.addAxis(ctrl.text.trim());
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _confirmDeleteAxis(
      int index, String axisName, ItemFormNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Eje'),
        content: Text(
          '¿Estás seguro de eliminar el eje "$axisName"? Se eliminarán las variantes asociadas a sus valores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              notifier.removeAxis(index);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. ADD VALUE BOTTOM SHEET (MULTI-VALUE COMMA SEPARATED & SUGGESTIONS)
  // =========================================================================
  void _showAddValueDialog(
      int axisIndex, VariantAxis axis, ItemFormNotifier notifier) {
    final ctrl = TextEditingController();

    // Contextual size suggestions
    final lowerAxisName = axis.name.trim().toLowerCase();
    List<String> contextualSuggestions = [];
    if (lowerAxisName.contains('talla') || lowerAxisName.contains('size')) {
      contextualSuggestions = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Única'];
    } else if (lowerAxisName.contains('calzado') ||
        lowerAxisName.contains('zapato') ||
        lowerAxisName.contains('número') ||
        lowerAxisName.contains('numero')) {
      contextualSuggestions = ['36', '37', '38', '39', '40', '41', '42', '43', '44'];
    }

    _showAppBottomSheet(
      context: context,
      title: 'Agregar a "${axis.name}"',
      subtitle: 'Escribe valores separados por coma para agregar varios a la vez',
      builder: (ctx, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              selectAllOnFocus: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Valor o valores',
                hintText: 'Ej. S, M, L, XL',
                prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF4F46E5), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
                ),
              ),
              onSubmitted: (_) {
                _processAndAddValues(ctrl.text, axisIndex, axis, notifier);
              },
            ),
            if (contextualSuggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Tallas sugeridas (toca para añadir):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: contextualSuggestions
                    .where((s) => !axis.values.contains(s))
                    .map(
                      (s) => ActionChip(
                        avatar: const Icon(Icons.add, size: 14, color: Color(0xFF4F46E5)),
                        label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          final current = ctrl.text.trim();
                          setSheetState(() {
                            if (current.isEmpty) {
                              ctrl.text = s;
                            } else {
                              ctrl.text = '$current, $s';
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consejo: Puedes pegar o escribir varios valores separados por coma.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      bottomAction: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Agregar Valor(es)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            _processAndAddValues(ctrl.text, axisIndex, axis, notifier);
          },
        ),
      ),
    );
  }

  void _processAndAddValues(
      String rawInput, int axisIndex, VariantAxis axis, ItemFormNotifier notifier) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return;

    final parts = trimmed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isNotEmpty) {
      final newVals = List<String>.from(axis.values);
      for (final part in parts) {
        final cleanPart = part.trim();
        final exists = newVals.any((v) {
          final base = v.contains('|')
              ? v.split('|')[0].trim().toLowerCase()
              : v.trim().toLowerCase();
          return base == cleanPart.toLowerCase();
        });
        if (!exists) {
          newVals.add(cleanPart);
        }
      }
      notifier.updateAxisValues(axisIndex, newVals);
      Navigator.pop(context);
    }
  }

  // =========================================================================
  // 3. ADVANCED COLOR PICKER & COMMERCIAL PALETTE (16 TONES + SPECTRUM + HEX)
  // =========================================================================
  void _showAddColorDialog(
      int axisIndex, VariantAxis axis, ItemFormNotifier notifier) {
    final nameCtrl = TextEditingController();
    final hexCtrl = TextEditingController(text: '#0F172A');
    Color currentColor = const Color(0xFF0F172A);
    int selectedTab = 0; // 0: Paleta Comercial, 1: Selector Libre
    String? selectedImageRef;


    _showAppBottomSheet(
      context: context,
      title: 'Agregar Color',
      subtitle: 'Elige un tono comercial o usa el selector libre',
      builder: (ctx, setSheetState) {
        final isColorLight = currentColor.computeLuminance() > 0.82;
        final hexString = '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Preview Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isColorLight
                            ? const Color(0xFF94A3B8)
                            : Colors.black12,
                        width: isColorLight ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nameCtrl.text.trim().isEmpty
                              ? 'Nombre del color...'
                              : nameCtrl.text.trim(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: nameCtrl.text.trim().isEmpty
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hexString,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Color Name Input
            TextField(
              controller: nameCtrl,
              selectAllOnFocus: false,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre del color',
                hintText: 'Ej. Azul Marino, Palo de Rosa, Vino Tinto',
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF4F46E5), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
                ),
              ),
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: 14),

            // Tab Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setSheetState(() => selectedTab = 0),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selectedTab == 0
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.palette_rounded,
                              size: 16,
                              color: selectedTab == 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Paleta Comercial',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selectedTab == 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setSheetState(() => selectedTab = 1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: selectedTab == 1
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.colorize_rounded,
                              size: 16,
                              color: selectedTab == 1 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Selector Libre',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selectedTab == 1 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab 0: Curated Commercial Palette (16 tones)
            if (selectedTab == 0) ...[
              const Text(
                'Tonos populares de e-commerce:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colorPresets.map((preset) {
                  final presetColor = preset['color'] as Color;
                  final presetHex = preset['hex'] as String;
                  final isSelected = hexString.toUpperCase() == presetHex.toUpperCase();
                  final isPresetLight = presetColor.computeLuminance() > 0.85;

                  return GestureDetector(
                    onTap: () {
                      setSheetState(() {
                        currentColor = presetColor;
                        hexCtrl.text = presetHex;
                        if (nameCtrl.text.isEmpty ||
                            _colorPresets.any((p) => p['name'] == nameCtrl.text.trim())) {
                          nameCtrl.text = preset['name'] as String;
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: presetColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : (isPresetLight ? const Color(0xFFCBD5E1) : Colors.transparent),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: isPresetLight ? Colors.black87 : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ]
            // Tab 1: Full-Spectrum Color Picker & HEX Input
            else ...[
              ColorPicker(
                pickerColor: currentColor,
                onColorChanged: (newColor) {
                  setSheetState(() {
                    currentColor = newColor;
                    final h = '#${newColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                    hexCtrl.text = h;
                  });
                },
                colorPickerWidth: 280,
                pickerAreaHeightPercent: 0.60,
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
                labelTypes: const [],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hexCtrl,
                selectAllOnFocus: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código HEX',
                  hintText: '#005F73',
                  prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF4F46E5), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                onChanged: (val) {
                  final clean = val.replaceAll('#', '').trim();
                  if (clean.length == 6) {
                    try {
                      final parsed = Color(int.parse('FF$clean', radix: 16));
                      setSheetState(() {
                        currentColor = parsed;
                      });
                    } catch (_) {}
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Foto de la variante (opcional):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                _showProductImagePickerSheet(
                  context: context,
                  state: ref.read(itemFormProvider),
                  currentImageRef: selectedImageRef,
                  onImageSelected: (img) {
                    setSheetState(() {
                      selectedImageRef = img;
                    });
                  },
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    if (selectedImageRef != null &&
                        selectedImageRef!.isNotEmpty) ...[
                      _buildVariantImageWidget(
                              selectedImageRef, ref.read(itemFormProvider),
                              size: 36, radius: 8) ??
                          const SizedBox(),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Foto vinculada',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Color(0xFFEF4444)),
                        onPressed: () {
                          setSheetState(() {
                            selectedImageRef = null;
                          });
                        },
                      ),
                    ] else ...[
                      const Icon(Icons.add_photo_alternate_outlined,
                          size: 20, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Seleccionar foto del producto...',
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: Color(0xFF94A3B8)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
      bottomAction: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_rounded, size: 20),
          label: const Text(
            'Guardar Color',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            final name = nameCtrl.text.trim();
            final hex =
                '#${currentColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            if (name.isNotEmpty) {
              final formatted =
                  selectedImageRef != null && selectedImageRef!.isNotEmpty
                      ? '$name|$hex|$selectedImageRef'
                      : '$name|$hex';
              final newVals = List<String>.from(axis.values);
              final idx = newVals.indexWhere((val) {
                final base = val.contains('|')
                    ? val.split('|')[0].trim().toLowerCase()
                    : val.trim().toLowerCase();
                return base == name.toLowerCase();
              });
              if (idx != -1) {
                newVals[idx] = formatted;
              } else {
                newVals.add(formatted);
              }
              notifier.updateAxisValues(axisIndex, newVals);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }


  // =========================================================================
  // 4. BATCH ACTIONS BOTTOM SHEETS (PRICE & STOCK)
  // =========================================================================
  void _showBatchPriceDialog(ItemFormNotifier notifier) {
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    if (user != null && !user.canChangePrices) {
      return;
    }

    final ctrl = TextEditingController();

    _showAppBottomSheet(
      context: context,
      title: 'Aplicar Precio Masivo',
      subtitle: 'Se aplicará a todas las opciones activas',
      builder: (ctx, setSheetState) {
        return TextField(
          controller: ctrl,
          autofocus: true,
          selectAllOnFocus: false,
          decoration: InputDecoration(
            labelText: 'Precio para variantes activas',
            hintText: 'Ej. 25.00',
            prefixText: '\$ ',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        );
      },
      bottomAction: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.flash_on_rounded, size: 20),
          label: const Text(
            'Aplicar a Todas',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            final p = double.tryParse(ctrl.text);
            if (p != null) {
              notifier.batchUpdatePrice(p, true);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _showBatchStockDialog(ItemFormNotifier notifier) {
    final ctrl = TextEditingController();

    _showAppBottomSheet(
      context: context,
      title: 'Aplicar Stock Masivo',
      subtitle: 'Se aplicará a todas las opciones activas',
      builder: (ctx, setSheetState) {
        return TextField(
          controller: ctrl,
          autofocus: true,
          selectAllOnFocus: false,
          decoration: InputDecoration(
            labelText: 'Stock para variantes activas',
            hintText: 'Ej. 20',
            prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF4F46E5)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          keyboardType: TextInputType.number,
        );
      },
      bottomAction: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.flash_on_rounded, size: 20),
          label: const Text(
            'Aplicar a Todas',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            final s = double.tryParse(ctrl.text);
            if (s != null) {
              notifier.batchUpdateStock(s, true);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}

bool _matchesAxisValue(String? a, String? b) {
  if (a == null || b == null) return false;
  if (a == b) return true;
  final cleanA = a.contains('|') ? a.split('|')[0].trim() : a.trim();
  final cleanB = b.contains('|') ? b.split('|')[0].trim() : b.trim();
  return cleanA.toLowerCase() == cleanB.toLowerCase();
}

