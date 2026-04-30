import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/store_category_provider.dart';

class CreateStoreCategoryModal extends ConsumerStatefulWidget {
  final String storeId;
  final VoidCallback? onSuccess;

  const CreateStoreCategoryModal({
    super.key,
    required this.storeId,
    this.onSuccess,
  });

  @override
  ConsumerState<CreateStoreCategoryModal> createState() => _CreateStoreCategoryModalState();
}

class _CreateStoreCategoryModalState extends ConsumerState<CreateStoreCategoryModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(storeCategoryProvider.notifier).createCategory(
          storeId: widget.storeId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );

    if (success && mounted) {
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    }
  }

  InputDecoration _getInputDecoration({
    required String label,
    required String hint,
    required dynamic icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: HugeIcon(icon: icon, color: const Color(0xFF4F46E5), size: 22),
      ),
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeCategoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nueva Categoría',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea una categoría personalizada para organizar mejor tus productos.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: _getInputDecoration(
                    label: 'Nombre de la categoría',
                    hint: 'Ej. Bebidas, Postres, Entradas...',
                    icon: HugeIcons.strokeRoundedTag01,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    if (value.trim().length < 3 || value.trim().length > 50) {
                      return 'El nombre debe tener entre 3 y 50 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(height: 1.4),
                  decoration: _getInputDecoration(
                    label: 'Descripción',
                    hint: 'Breve descripción de lo que incluye esta categoría...',
                    icon: HugeIcons.strokeRoundedNote01,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa una descripción';
                    }
                    if (value.trim().length < 10 || value.trim().length > 255) {
                      return 'La descripción debe tener entre 10 y 255 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (state.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: state.isCreating ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: state.isCreating
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Crear Categoría',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
