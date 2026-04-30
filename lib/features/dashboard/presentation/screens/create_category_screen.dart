import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../items/domain/entities/property_template.dart';
import '../providers/store_category_provider.dart';

class CreateCategoryScreen extends ConsumerStatefulWidget {
  final String storeId;
  const CreateCategoryScreen({super.key, required this.storeId});

  @override
  ConsumerState<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final List<Map<String, dynamic>> _properties = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addProperty() {
    setState(() {
      _properties.add({
        'name': '',
        'type': PropertyType.text.name.toUpperCase(),
        'isRequired': false,
      });
    });
  }

  void _removeProperty(int index) {
    setState(() {
      _properties.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate properties
    for (var prop in _properties) {
      if (prop['name'].toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas las propiedades deben tener un nombre')),
        );
        return;
      }
    }

    final success = await ref.read(storeCategoryProvider.notifier).createCategory(
          storeId: widget.storeId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          propertyTemplates: _properties.map((p) => {
            'name': p['name'].toString().trim(),
            'type': p['type'],
            'isRequired': p['isRequired'],
          }).toList(),
        );

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(storeCategoryProvider).isCreating;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nueva Categoría',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información Básica'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre de la categoría',
                hint: 'Ej: Bebidas, Postres, etc.',
                icon: HugeIcons.strokeRoundedTag01,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Ingresa un nombre';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _descriptionController,
                label: 'Descripción (opcional)',
                hint: 'Breve descripción de los productos',
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              _buildSectionTitle('Plantilla de Propiedades'),
              const SizedBox(height: 8),
              const Text(
                'Define qué campos verás al crear artículos en esta categoría.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ..._properties.asMap().entries.map((entry) => _buildPropertyEditor(entry.key, entry.value)),
              const SizedBox(height: 12),
              _buildAddPropertyButton(),
              const SizedBox(height: 48),
              _buildSubmitButton(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    dynamic icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
            prefixIcon: icon != null ? Padding(padding: const EdgeInsets.all(12.0), child: HugeIcon(icon: icon, color: const Color(0xFF6B7280), size: 20)) : null,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPropertyEditor(int index, Map<String, dynamic> property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: property['name'],
                  onChanged: (v) => property['name'] = v,
                  decoration: const InputDecoration(
                    hintText: 'Nombre (ej. Talla)',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: property['type'],
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                    onChanged: (v) => setState(() => property['type'] = v),
                    items: PropertyType.values.map((type) {
                      return DropdownMenuItem(value: type.name.toUpperCase(), child: Text(type.name.toUpperCase()));
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _removeProperty(index),
              ),
            ],
          ),
          const Divider(height: 1),
          Row(
            children: [
              const Text('¿Es obligatorio?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Spacer(),
              Switch.adaptive(
                value: property['isRequired'],
                activeThumbColor: const Color(0xFF4F46E5),
                onChanged: (v) => setState(() => property['isRequired'] = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPropertyButton() {
    return InkWell(
      onTap: _addProperty,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4F46E5), style: BorderStyle.none),
          color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFF4F46E5), size: 20),
            SizedBox(width: 8),
            Text('Añadir propiedad', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Crear Categoría', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
