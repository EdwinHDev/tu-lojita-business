import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/item.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/item_form_provider.dart';
import '../../../dashboard/presentation/providers/store_details_notifier.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final String storeId;

  const ItemFormScreen({super.key, required this.storeId});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Auxiliary controllers for attributes (as they are dynamic/modal)
  final _attrKeyController = TextEditingController();
  final _attrValueController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item creado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      final error = next.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Nuevo ${state.itemType == ItemType.product ? 'Producto' : 'Servicio'}',
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
                  initialValue: state.itemType,
                  decoration: _inputDecoration('Tipo de artículo'),
                  items: [
                    DropdownMenuItem(value: ItemType.product, child: _dropdownItem(HugeIcons.strokeRoundedShoppingBasket01, 'Producto Físico')),
                    DropdownMenuItem(value: ItemType.service, child: _dropdownItem(HugeIcons.strokeRoundedCustomerService, 'Servicio / Reserva')),
                  ],
                  onChanged: (v) => notifier.onItemTypeChanged(v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: state.categoryId,
                  decoration: _inputDecoration('Categoría de la tienda'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                    ...storeState.categories.map((e) => DropdownMenuItem(
                      value: e.id, 
                      child: Text(e.name),
                    )),
                  ],
                  onChanged: (v) => notifier.onCategoryIdChanged(v),
                ),
              ]),

              const SizedBox(height: 24),
              _buildSectionTitle('Precios y Ofertas'),
              const SizedBox(height: 12),
              _buildCard([
                DropdownButtonFormField<PriceType>(
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
              _buildSectionTitle('Propiedades Adicionales'),
              const SizedBox(height: 12),
              _buildAttributesEditor(state),

              const SizedBox(height: 40),
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
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == state.selectedImages.length) {
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
                    image: DecorationImage(image: FileImage(state.selectedImages[index]), fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 18,
                child: GestureDetector(
                  onTap: () => ref.read(itemFormProvider.notifier).removeImage(index),
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

  Widget _buildAttributesEditor(ItemFormState state) {
    return _buildCard([
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _attrKeyController,
              label: 'Propiedad',
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
      if (state.attributes.isNotEmpty) ...[
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.attributes.entries.map((entry) {
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
    ]);
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
    return TextFormField(
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
                'CREAR ${state.itemType == ItemType.product ? 'PRODUCTO' : 'SERVICIO'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
              ),
      ),
    );
  }
}
