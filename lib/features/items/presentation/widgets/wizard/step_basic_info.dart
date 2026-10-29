import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/create_store_category_modal.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_form_provider.dart';

class StepBasicInfo extends ConsumerStatefulWidget {
  final String storeId;
  final GlobalKey<FormState> formKey;

  const StepBasicInfo({
    super.key,
    required this.storeId,
    required this.formKey,
  });

  @override
  ConsumerState<StepBasicInfo> createState() => _StepBasicInfoState();
}

class _StepBasicInfoState extends ConsumerState<StepBasicInfo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final notifier = ref.read(itemFormProvider.notifier);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: Color(0xFF1E293B),
              ),
              title: const Text('Tomar Foto'),
              onTap: () async {
                Navigator.pop(context);
                final photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (photo != null) {
                  notifier.addImages([File(photo.path)]);
                }
              },
            ),
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlbum01,
                color: Color(0xFF1E293B),
              ),
              title: const Text('Elegir de Galería'),
              onTap: () async {
                Navigator.pop(context);
                final images = await picker.pickMultiImage(imageQuality: 85);
                if (images.isNotEmpty) {
                  notifier.addImages(
                    images.map((e) => File(e.path)).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(itemFormProvider);
    final notifier = ref.read(itemFormProvider.notifier);
    final storeState = ref.watch(storeDetailsProvider).forStore(widget.storeId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Multimedia Section
            _buildSectionHeader(
              title: 'Fotografías del Artículo',
              subtitle: 'Añade fotos atractivas y selecciona la foto principal con la estrella.',
            ),
            const SizedBox(height: 12),
            _buildImagePicker(state, notifier),

            const SizedBox(height: 24),

            // Identidad y Clasificación
            _buildSectionHeader(
              title: 'Información General',
              subtitle: 'Nombre, descripción y categoría donde se mostrará a los clientes.',
            ),
            const SizedBox(height: 12),
            _buildCard([
              // Title
              TextFormField(
                key: ValueKey('title_${state.itemId ?? "new"}'),
                selectAllOnFocus: false,
                initialValue: state.title,
                decoration: _inputDecoration('Título del artículo', hint: 'Ej. Camiseta de algodón premium'),
                style: const TextStyle(fontSize: 15),
                onChanged: notifier.onTitleChanged,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa un título descriptivo para el artículo'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                key: ValueKey('desc_${state.itemId ?? "new"}'),
                selectAllOnFocus: false,
                initialValue: state.description,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Descripción detallada',
                  hint: 'Describe materiales, características principales, uso recomendado...',
                ),
                style: const TextStyle(fontSize: 15),
                onChanged: notifier.onDescriptionChanged,
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Escribe al menos 10 caracteres de descripción'
                    : null,
              ),
              const SizedBox(height: 16),

              // Item Type Dropdown
              DropdownButtonFormField<ItemType>(
                key: ValueKey('itemType_${state.itemId ?? "new"}'),
                initialValue: state.itemType,
                decoration: _inputDecoration('Tipo de artículo'),
                items: [
                  DropdownMenuItem(
                    value: ItemType.product,
                    child: _dropdownItem(HugeIcons.strokeRoundedShoppingBasket01, 'Producto Físico'),
                  ),
                  DropdownMenuItem(
                    value: ItemType.service,
                    child: _dropdownItem(HugeIcons.strokeRoundedCustomerService, 'Servicio / Reserva'),
                  ),
                ],
                onChanged: (v) => notifier.onItemTypeChanged(v!),
              ),
              const SizedBox(height: 16),

              // Category Selector with quick create button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('cat_${state.itemId ?? "new"}'),
                      initialValue: state.categoryId,
                      decoration: _inputDecoration('Categoría de la tienda'),
                      isExpanded: true,
                      items: storeState.categories.map((e) {
                        return DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => notifier.onCategoryIdChanged(v),
                      validator: (v) => v == null ? 'Selecciona una categoría' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 52,
                    margin: const EdgeInsets.only(top: 2),
                    child: TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => CreateStoreCategoryModal(
                            storeId: widget.storeId,
                            onSuccess: () {
                              ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
                            },
                          ),
                        );
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        size: 18,
                        color: Color(0xFF4F46E5),
                      ),
                      label: const Text(
                        'Nueva',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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

  Widget _buildImagePicker(ItemFormState state, ItemFormNotifier notifier) {
    final int totalImages = state.existingImages.length + state.selectedImages.length;
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages + 1,
        itemBuilder: (context, index) {
          if (index == totalImages) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: Color(0xFF64748B)),
                    SizedBox(height: 6),
                    Text(
                      'Añadir',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final bool isExisting = index < state.existingImages.length;
          final bool isPrimary = state.primaryImageIndex == index;

          return Stack(
            children: [
              GestureDetector(
                onTap: () => notifier.setPrimaryImage(index),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isPrimary
                        ? Border.all(color: const Color(0xFF4F46E5), width: 2.5)
                        : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: isExisting
                        ? Image.network(
                            _resolveImageUrl(state.existingImages[index]),
                            fit: BoxFit.cover,
                            width: 100,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFCBD5E1),
                              child: const Icon(Icons.broken_image, color: Colors.white),
                            ),
                          )
                        : Image.file(
                            state.selectedImages[index - state.existingImages.length],
                            fit: BoxFit.cover,
                            width: 100,
                            height: 120,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 18,
                child: GestureDetector(
                  onTap: () => notifier.removeImage(
                    isExisting ? index : index - state.existingImages.length,
                    isExisting: isExisting,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
              if (isPrimary)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Principal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _dropdownItem(dynamic iconData, String text) {
    return Row(
      children: [
        HugeIcon(icon: iconData, size: 20, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}
