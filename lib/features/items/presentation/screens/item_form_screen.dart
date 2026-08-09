import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/property_template.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/item_form_provider.dart';
import '../providers/item_list_notifier.dart';
import '../../../dashboard/presentation/providers/store_details_notifier.dart';
import '../../../../core/config/envs.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../dashboard/presentation/widgets/create_store_category_modal.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final String storeId;
  final Item? item;

  const ItemFormScreen({super.key, required this.storeId, this.item});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _attrKeyController = TextEditingController();
  final _attrValueController = TextEditingController();

  bool _showManualProperties = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.item != null) {
        ref.read(itemFormProvider.notifier).initForEditing(widget.item!);
      }
      ref.read(storeDetailsProvider.notifier).loadData(widget.storeId);
    });
  }

  @override
  void dispose() {
    _attrKeyController.dispose();
    _attrValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final notifier = ref.read(itemFormProvider.notifier);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedCamera01, color: Color(0xFF1E293B)),
              title: const Text('Tomar Foto'),
              onTap: () async {
                Navigator.pop(context);
                final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (photo != null) {
                  notifier.addImages([File(photo.path)]);
                }
              },
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedAlbum01, color: Color(0xFF1E293B)),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(itemFormProvider.notifier).submit(widget.storeId);
  }

  void _addAttribute() {
    if (_attrKeyController.text.isEmpty || _attrValueController.text.isEmpty) return;
    ref.read(itemFormProvider.notifier).addAttribute(
      _attrKeyController.text.trim(),
      _attrValueController.text.trim(),
    );
    _attrKeyController.clear();
    _attrValueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemFormProvider);
    final notifier = ref.read(itemFormProvider.notifier);
    final storeState = ref.watch(storeDetailsProvider).forStore(widget.storeId);

    ref.listen(itemFormProvider, (previous, next) {
      if (next.isSuccess) {
        ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
        ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
        context.pop(true);
        NotificationService.showSuccess(context, 'Item guardado exitosamente');
      }
      final error = next.errorMessage;
      if (error != null) {
        NotificationService.showError(context, error);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${widget.item != null ? 'Editar' : 'Nuevo'} ${state.itemType == ItemType.product ? 'Producto' : 'Servicio'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Multimedia'),
              const SizedBox(height: 12),
              _buildImagePicker(state),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Información General'),
              const SizedBox(height: 12),
              _buildCard([
                _buildTextField(
                  initialValue: state.title,
                  label: 'Título del artículo',
                  hint: 'Ej. Camiseta de algodón premium',
                  onChanged: notifier.onTitleChanged,
                  validator: (v) => (v == null || v.isEmpty) ? 'Ingresa un título' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  initialValue: state.description,
                  label: 'Descripción',
                  hint: 'Describe las características principales...',
                  maxLines: 4,
                  onChanged: notifier.onDescriptionChanged,
                  validator: (v) => (v == null || v.length < 10) ? 'Mínimo 10 caracteres' : null,
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Clasificación'),
              const SizedBox(height: 12),
              _buildCard([
                DropdownButtonFormField<ItemType>(
                  key: ValueKey('${state.itemId ?? "new"}_itemType'),
                  initialValue: state.itemType,
                  decoration: _inputDecoration('Tipo de artículo'),
                  items: [
                    DropdownMenuItem(value: ItemType.product, child: _dropdownItem(HugeIcons.strokeRoundedShoppingBasket01, 'Producto Físico')),
                    DropdownMenuItem(value: ItemType.service, child: _dropdownItem(HugeIcons.strokeRoundedCustomerService, 'Servicio / Reserva')),
                  ],
                  onChanged: (v) => notifier.onItemTypeChanged(v!),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('${state.itemId ?? "new"}_categoryId'),
                        initialValue: state.categoryId,
                        decoration: _inputDecoration('Categoría de la tienda'),
                        isExpanded: true,
                        items: storeState.categories.map((e) => DropdownMenuItem(
                          value: e.id, 
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) => notifier.onCategoryIdChanged(v),
                        validator: (v) => v == null ? 'Categoría requerida' : null,
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
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 20, color: Color(0xFF4F46E5)),
                        label: const Text('Nueva', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Precios y Ofertas'),
              const SizedBox(height: 12),
              _buildCard([
                DropdownButtonFormField<PriceType>(
                  key: ValueKey('${state.itemId ?? "new"}_priceType'),
                  initialValue: state.priceType,
                  decoration: _inputDecoration('Tipo de precio'),
                  items: [
                    DropdownMenuItem(value: PriceType.fixed, child: _dropdownItem(HugeIcons.strokeRoundedCircleLock01, 'Precio Fijo')),
                    DropdownMenuItem(value: PriceType.startingAt, child: _dropdownItem(HugeIcons.strokeRoundedCursorMagicSelection01, 'Precio "Desde"')),
                    DropdownMenuItem(value: PriceType.negotiable, child: _dropdownItem(HugeIcons.strokeRoundedChat01, 'Negociable')),
                    DropdownMenuItem(value: PriceType.onDemand, child: _dropdownItem(HugeIcons.strokeRoundedCustomerService, 'Bajo Pedido')),
                    DropdownMenuItem(value: PriceType.free, child: _dropdownItem(HugeIcons.strokeRoundedStar, 'Gratis')),
                  ],
                  onChanged: (v) => notifier.onPriceTypeChanged(v!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        initialValue: state.price == 0 ? '' : state.price.toString(),
                        label: 'Precio Base',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                        prefix: const Text('\$ ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        onChanged: (v) => notifier.onPriceChanged(double.tryParse(v) ?? 0),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Precio inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        initialValue: state.discountPrice?.toString() ?? '',
                        label: 'Precio Oferta',
                        hint: 'Opcional',
                        keyboardType: TextInputType.number,
                        prefix: const Text('\$ ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        onChanged: (v) => notifier.onDiscountPriceChanged(double.tryParse(v)),
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Inventario y Logística'),
              const SizedBox(height: 12),
              _buildCard([
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Controlar stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('El sistema descontará unidades automáticamente', style: TextStyle(fontSize: 12)),
                  value: state.trackInventory,
                  activeThumbColor: const Color(0xFF4F46E5),
                  onChanged: (v) => notifier.onTrackInventoryChanged(v),
                ),
                if (state.trackInventory) ...[
                  const Divider(height: 24),
                  _buildTextField(
                    initialValue: state.stockQuantity?.toString() ?? '',
                    label: 'Cantidad disponible',
                    hint: 'Ej. 50',
                    keyboardType: TextInputType.number,
                    onChanged: (v) => notifier.onStockQuantityChanged(double.tryParse(v)),
                  ),
                ],
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Configuraciones de Negocio'),
              const SizedBox(height: 12),
              _buildCard([
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Producto Publicado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Visible públicamente para los clientes en la app', style: TextStyle(fontSize: 12)),
                  value: state.isActive,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (v) => notifier.onIsActiveChanged(v),
                ),
                const Divider(height: 24),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Producto Destacado', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Aparecerá en las primeras secciones de la tienda', style: TextStyle(fontSize: 12)),
                  value: state.isFeatured,
                  activeThumbColor: const Color(0xFFF59E0B),
                  onChanged: (v) => notifier.onIsFeaturedChanged(v),
                ),
                const Divider(height: 24),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Requiere Reserva', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Obliga al cliente a elegir fecha y hora', style: TextStyle(fontSize: 12)),
                  value: state.requiresBooking,
                  activeThumbColor: const Color(0xFF4F46E5),
                  onChanged: (v) => notifier.onRequiresBookingChanged(v),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Pagos Parcelados'),
              const SizedBox(height: 12),
              _buildCard([
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permitir pagos en cuotas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('El cliente podrá pagar este producto en partes', style: TextStyle(fontSize: 12)),
                  value: state.allowInstallments,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (v) {
                    if (v && storeState.store != null && !storeState.store!.allowPartialPayments) {
                      NotificationService.showError(context, 'Debes habilitar los pagos parciales en la configuración de la tienda primero.');
                      return;
                    }
                    notifier.onAllowInstallmentsChanged(v);
                  },
                ),
                if (state.allowInstallments) ...[
                  const Divider(height: 24),
                  _buildTextField(
                    initialValue: state.lateFeePercentage == 0 ? '' : state.lateFeePercentage.toString(),
                    label: 'Porcentaje de multa por retraso',
                    hint: 'Ej. 5.0',
                    keyboardType: TextInputType.number,
                    prefix: const Icon(Icons.percent, size: 16, color: Color(0xFF64748B)),
                    onChanged: (v) => notifier.onLateFeePercentageChanged(double.tryParse(v) ?? 0),
                  ),
                ],
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Propiedades Adicionales'),
              const SizedBox(height: 12),
              _buildAttributesSection(state),

              const SizedBox(height: 24),
              _buildSectionTitle('Opciones de Personalización'),
              const SizedBox(height: 12),
              _buildCustomizationsSection(state),
              const SizedBox(height: 100), // Space for FAB
              _buildSubmitButton(state),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
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
      child: Column(children: children),
    );
  }



  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5)),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

  Widget _buildImagePicker(ItemFormState state) {
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedImageAdd01, color: Color(0xFF64748B)),
                    SizedBox(height: 4),
                    Text('Añadir', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                onTap: () => ref.read(itemFormProvider.notifier).setPrimaryImage(index),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: isPrimary ? Border.all(color: const Color(0xFF4F46E5), width: 2) : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                  onTap: () => ref.read(itemFormProvider.notifier).removeImage(
                    isExisting ? index : index - state.existingImages.length,
                    isExisting: isExisting,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
              if (isPrimary)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Principal', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  Widget _buildAttributesSection(ItemFormState state) {
    if (state.isLoadingTemplates) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.categoryId == null) {
      return _buildCard([
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Selecciona una categoría para añadir propiedades específicas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ),
      ]);
    }

    return _buildCard([
      if (state.availableTemplates.isNotEmpty) ...[
        ...state.availableTemplates.map((template) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildDynamicInput(template, state),
          );
        }),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('PROPIEDADES EXTRA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
      ],
      _buildManualAttributeEntry(state),
    ]);
  }

  Widget _buildDynamicInput(PropertyTemplate template, ItemFormState state) {
    final value = state.attributes[template.name];

    switch (template.type) {
      case PropertyType.boolean:
        return SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(template.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          value: value ?? false,
          activeThumbColor: const Color(0xFF4F46E5),
          onChanged: (v) => ref.read(itemFormProvider.notifier).onAttributeChanged(template.name, v),
        );

      case PropertyType.list:
      case PropertyType.colorList:
        final List<String> list = List<String>.from(value ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
            const SizedBox(height: 8),
            _buildListEditor(
              template.name, 
              list, 
              isColor: template.type == PropertyType.colorList,
            ),
          ],
        );

      case PropertyType.number:
        return _buildTextField(
          initialValue: value?.toString() ?? '',
          label: template.name,
          hint: template.config?['unit'] ?? '0.00',
          keyboardType: TextInputType.number,
          onChanged: (v) => ref.read(itemFormProvider.notifier).onAttributeChanged(template.name, double.tryParse(v) ?? 0),
        );

      case PropertyType.dropdown:
        final List<String> options = List<String>.from(template.config?['options'] ?? []);
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: _inputDecoration(template.name),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: (v) => ref.read(itemFormProvider.notifier).onAttributeChanged(template.name, v),
        );

      default:
        return _buildTextField(
          initialValue: value?.toString() ?? '',
          label: template.name,
          hint: 'Escribe aquí...',
          onChanged: (v) => ref.read(itemFormProvider.notifier).onAttributeChanged(template.name, v),
        );
    }
  }

  Widget _buildListEditor(String key, List<String> currentList, {bool isColor = false}) {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: _inputDecoration(isColor ? 'Código Hex (ej: #FF0000)' : 'Añadir elemento...').copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF4F46E5)),
                    onPressed: () {
                      if (controller.text.isEmpty) return;
                      final newList = [...currentList, controller.text.trim()];
                      ref.read(itemFormProvider.notifier).onAttributeChanged(key, newList);
                      controller.clear();
                    },
                  ),
                ),
                onFieldSubmitted: (v) {
                  if (v.isEmpty) return;
                  final newList = [...currentList, v.trim()];
                  ref.read(itemFormProvider.notifier).onAttributeChanged(key, newList);
                  controller.clear();
                },
              ),
            ),
          ],
        ),
        if (currentList.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentList.map((item) {
              return Chip(
                avatar: isColor ? Container(width: 12, height: 12, decoration: BoxDecoration(color: _parseHexColor(item), shape: BoxShape.circle)) : null,
                label: Text(item, style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onDeleted: () {
                  final newList = currentList.where((element) => element != item).toList();
                  ref.read(itemFormProvider.notifier).onAttributeChanged(key, newList);
                },
              );
            }).toList(),
          ),
        ],
      ],
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

  Widget _buildManualAttributeEntry(ItemFormState state) {
    // Filter out attributes that belong to templates to show only "extra" ones
    final extraAttributes = state.attributes.entries.where((e) => !state.availableTemplates.any((t) => t.name == e.key));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.availableTemplates.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
        ],
        
        if (!_showManualProperties)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showManualProperties = true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir propiedad personalizada'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else ...[
          Row(
            children: [
              const Text('Propiedad personalizada', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _showManualProperties = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _attrKeyController,
                  label: 'Nombre',
                  hint: 'Ej. Marca',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _attrValueController,
                  label: 'Valor',
                  hint: 'Ej. Nike',
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _addAttribute,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],

        if (extraAttributes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: extraAttributes.map((entry) {
              return Chip(
                label: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 12)),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onDeleted: () => ref.read(itemFormProvider.notifier).removeAttribute(entry.key),
                deleteIcon: const Icon(Icons.close, size: 14),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }



  
  // Re-define _buildTextField to allow both initialValue and controller
  Widget _buildTextField({
    String? initialValue,
    TextEditingController? controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefix,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    final itemId = ref.watch(itemFormProvider).itemId ?? 'new';
    return TextFormField(
      key: ValueKey('${label}_$itemId'),
      initialValue: initialValue,
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: _inputDecoration(label).copyWith(
        hintText: hint,
        prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.all(12), child: prefix) : null,
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildSubmitButton(ItemFormState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: state.isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 12),
                  Text('PROCESANDO...', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ],
              )
            : Text(
                '${widget.item != null ? 'GUARDAR' : 'CREAR'} ${state.itemType == ItemType.product ? 'PRODUCTO' : 'SERVICIO'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
              ),
      ),
    );
  }

  Widget _buildCustomizationsSection(ItemFormState state) {
    return _buildCard([
      if (state.customizationGroups.isEmpty) ...[
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No hay grupos de personalización configurados.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ),
      ] else ...[
        ...state.customizationGroups.map((group) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ExpansionTile(
              initiallyExpanded: true,
              shape: const Border(),
              title: Text(
                group.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                'Mínimo: ${group.minSelect} | Máximo: ${group.maxSelect}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Eliminar Grupo'),
                      content: Text('¿Estás seguro de que deseas eliminar el grupo "${group.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final newList = state.customizationGroups.where((g) => g.id != group.id).toList();
                            ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
                          },
                          child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInlineTextField(
                              key: ValueKey('${state.itemId ?? "new"}_${group.id}_name'),
                              initialValue: group.name,
                              label: 'Nombre del grupo de personalización',
                              onChanged: (val) {
                                final newList = state.customizationGroups.map((g) {
                                  if (g.id == group.id) {
                                    return CustomizationGroup(
                                      id: g.id,
                                      name: val.trim(),
                                      minSelect: g.minSelect,
                                      maxSelect: g.maxSelect,
                                      options: g.options,
                                    );
                                  }
                                  return g;
                                }).toList();
                                ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.stars_outlined, size: 18, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          const Text(
                            '¿Es obligatorio?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: group.minSelect > 0,
                            activeThumbColor: const Color(0xFF4F46E5),
                            onChanged: (val) {
                              final newList = state.customizationGroups.map((g) {
                                if (g.id == group.id) {
                                  return CustomizationGroup(
                                    id: g.id,
                                    name: g.name,
                                    minSelect: val ? (g.minSelect > 0 ? g.minSelect : 1) : 0,
                                    maxSelect: g.maxSelect,
                                    options: g.options,
                                  );
                                }
                                return g;
                              }).toList();
                              ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
                            },
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 2, bottom: 12),
                        child: Text(
                          'Si se marca, el cliente debe elegir al menos una opción obligatoria de este grupo.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInlineTextField(
                              key: ValueKey('${state.itemId ?? "new"}_${group.id}_minSelect'),
                              initialValue: group.minSelect.toString(),
                              label: 'Mín. Selecciones Totales',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final numVal = int.tryParse(val) ?? 0;
                                final newList = state.customizationGroups.map((g) {
                                  if (g.id == group.id) {
                                    return CustomizationGroup(
                                      id: g.id,
                                      name: g.name,
                                      minSelect: numVal,
                                      maxSelect: g.maxSelect,
                                      options: g.options,
                                    );
                                  }
                                  return g;
                                }).toList();
                                ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInlineTextField(
                              key: ValueKey('${state.itemId ?? "new"}_${group.id}_maxSelect'),
                              initialValue: group.maxSelect.toString(),
                              label: 'Máx. Selecciones Totales',
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final numVal = int.tryParse(val) ?? 0;
                                final newList = state.customizationGroups.map((g) {
                                  if (g.id == group.id) {
                                    return CustomizationGroup(
                                      id: g.id,
                                      name: g.name,
                                      minSelect: g.minSelect,
                                      maxSelect: numVal,
                                      options: g.options,
                                    );
                                  }
                                  return g;
                                }).toList();
                                ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF475569)),
                          const SizedBox(width: 8),
                          const Text(
                            'OPCIONES DEL GRUPO',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (group.options.isEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No hay opciones añadidas a este grupo aún.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ] else ...[
                        ...group.options.map((opt) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) => _OptionFormBottomSheet(
                                    group: group,
                                    option: opt,
                                    state: state,
                                    ref: ref,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            opt.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Mín: ${opt.minQuantity} | Máx: ${opt.maxQuantity}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: opt.price > 0
                                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        opt.price > 0 ? '\$${opt.price.toStringAsFixed(2)}' : 'Incluido',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: opt.price > 0 ? const Color(0xFF047857) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Eliminar Opción'),
                                            content: Text('¿Estás seguro de que deseas eliminar la opción "${opt.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('CANCELAR'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  final newList = state.customizationGroups.map((g) {
                                                    if (g.id == group.id) {
                                                      return CustomizationGroup(
                                                        id: g.id,
                                                        name: g.name,
                                                        minSelect: g.minSelect,
                                                        maxSelect: g.maxSelect,
                                                        options: g.options.where((o) => o.id != opt.id).toList(),
                                                      );
                                                    }
                                                    return g;
                                                  }).toList();
                                                  ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
                                                },
                                                child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => _OptionFormBottomSheet(
                                group: group,
                                state: state,
                                ref: ref,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar Opción'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFF4F46E5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            final newId = DateTime.now().millisecondsSinceEpoch.toString();
            final newList = [
              ...state.customizationGroups,
              CustomizationGroup(
                id: newId,
                name: 'Nueva Personalización',
                minSelect: 0,
                maxSelect: 0,
                options: const [],
              ),
            ];
            ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar Grupo de Opciones'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4F46E5),
            side: const BorderSide(color: Color(0xFF4F46E5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildInlineTextField({
    Key? key,
    required String initialValue,
    required String label,
    TextInputType? keyboardType,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      key: key,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}

class _OptionFormBottomSheet extends StatefulWidget {
  final CustomizationGroup group;
  final CustomizationOption? option;
  final ItemFormState state;
  final WidgetRef ref;

  const _OptionFormBottomSheet({
    required this.group,
    this.option,
    required this.state,
    required this.ref,
  });

  @override
  State<_OptionFormBottomSheet> createState() => _OptionFormBottomSheetState();
}

class _OptionFormBottomSheetState extends State<_OptionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _minQtyCtrl;
  late final TextEditingController _maxQtyCtrl;
  late final TextEditingController _defaultQtyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.option?.name ?? '');
    _priceCtrl = TextEditingController(
        text: widget.option != null && widget.option!.price > 0 ? widget.option!.price.toStringAsFixed(2) : '');
    _minQtyCtrl = TextEditingController(
        text: widget.option != null ? widget.option!.minQuantity.toString() : '0');
    _maxQtyCtrl = TextEditingController(
        text: widget.option != null ? widget.option!.maxQuantity.toString() : '1');
    _defaultQtyCtrl = TextEditingController(
        text: widget.option != null ? widget.option!.defaultQuantity.toString() : '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _minQtyCtrl.dispose();
    _maxQtyCtrl.dispose();
    _defaultQtyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final minQty = int.tryParse(_minQtyCtrl.text) ?? 0;
    final maxQty = int.tryParse(_maxQtyCtrl.text) ?? 1;
    final defaultQty = int.tryParse(_defaultQtyCtrl.text) ?? 0;

    final CustomizationOption finalOption;
    if (widget.option != null) {
      finalOption = CustomizationOption(
        id: widget.option!.id,
        name: _nameCtrl.text.trim(),
        price: price,
        minQuantity: minQty,
        maxQuantity: maxQty,
        defaultQuantity: defaultQty,
      );
    } else {
      finalOption = CustomizationOption(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameCtrl.text.trim(),
        price: price,
        minQuantity: minQty,
        maxQuantity: maxQty,
        defaultQuantity: defaultQty,
      );
    }

    final newList = widget.state.customizationGroups.map((g) {
      if (g.id == widget.group.id) {
        final List<CustomizationOption> newOptions = [...g.options];
        if (widget.option != null) {
          final idx = newOptions.indexWhere((o) => o.id == widget.option!.id);
          if (idx >= 0) {
            newOptions[idx] = finalOption;
          }
        } else {
          newOptions.add(finalOption);
        }
        return CustomizationGroup(
          id: g.id,
          name: g.name,
          minSelect: g.minSelect,
          maxSelect: g.maxSelect,
          options: newOptions,
        );
      }
      return g;
    }).toList();

    widget.ref.read(itemFormProvider.notifier).onCustomizationGroupsChanged(newList);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.option != null ? 'Editar Opción' : 'Nueva Opción',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre de la opción',
                  hintText: 'Ej. Queso Cheddar Extra',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: 'Precio adicional (\$)',
                  hintText: '0.00 (Dejar en blanco si es gratis)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.tune, size: 16, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text(
                    'LÍMITES DE CANTIDAD POR ARTÍCULO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minQtyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Cantidad Mínima',
                        hintText: '0',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxQtyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Cantidad Máxima',
                        hintText: '1',
                        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _defaultQtyCtrl,
                decoration: InputDecoration(
                  labelText: 'Cantidad por Defecto (Incluida en precio base)',
                  hintText: '0 (Por ejemplo: 1 para indicar que ya viene preseleccionada)',
                  labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.option != null ? 'GUARDAR CAMBIOS' : 'AGREGAR OPCIÓN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
