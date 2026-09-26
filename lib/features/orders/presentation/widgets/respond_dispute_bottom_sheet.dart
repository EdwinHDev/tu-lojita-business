import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/entities/order_dispute.dart';
import '../providers/dispute_providers.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

class RespondDisputeBottomSheet extends ConsumerStatefulWidget {
  final OrderDispute dispute;

  const RespondDisputeBottomSheet({super.key, required this.dispute});

  static Future<bool?> show(BuildContext context, {required OrderDispute dispute}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RespondDisputeBottomSheet(dispute: dispute),
    );
  }

  @override
  ConsumerState<RespondDisputeBottomSheet> createState() =>
      _RespondDisputeBottomSheetState();
}

class _RespondDisputeBottomSheetState
    extends ConsumerState<RespondDisputeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  final List<File> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isCounterMode = true; // true: counter/argue, false: accept claim

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeDisputeActionNotifierProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedFiles.add(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Error al seleccionar imagen: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitResponse() async {
    if (_isCounterMode && !_formKey.currentState!.validate()) return;

    final responseText = _isCounterMode
        ? _responseController.text.trim()
        : 'La tienda ha aceptado la solicitud del cliente de mutuo acuerdo.';

    final success = await ref
        .read(storeDisputeActionNotifierProvider.notifier)
        .respondDispute(
          disputeId: widget.dispute.id,
          orderId: widget.dispute.orderId,
          response: responseText,
          evidenceFiles: _isCounterMode ? _selectedFiles : const [],
          acceptDispute: !_isCounterMode,
        );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        NotificationService.showSuccess(
          context,
          _isCounterMode
              ? 'Respuesta enviada a mediación'
              : 'Reclamo aceptado exitosamente',
        );
      }
      // On failure, modal stays open and error displays in the inline banner
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(storeDisputeActionNotifierProvider);
    final isSubmitting = actionState.isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedComment01,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responder al Reclamo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Gestiona el caso con tu cliente y el equipo de mediación',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode Selector (Tabs)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isSubmitting
                            ? null
                            : () {
                                ref.read(storeDisputeActionNotifierProvider.notifier).clearError();
                                setState(() => _isCounterMode = true);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isCounterMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isCounterMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Enviar Explicación',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isCounterMode
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: isSubmitting
                            ? null
                            : () {
                                ref.read(storeDisputeActionNotifierProvider.notifier).clearError();
                                setState(() => _isCounterMode = false);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isCounterMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isCounterMode
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              'Aceptar Reclamo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isCounterMode
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isCounterMode) ...[
                // Counter-argument input
                const Text(
                  'Tu respuesta o descargo:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _responseController,
                  enabled: !isSubmitting,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Explica tu versión de los hechos o aclara la situación...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    ),
                    fillColor: Colors.grey.shade50,
                    filled: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor escribe tu respuesta';
                    }
                    if (val.trim().length < 10) {
                      return 'Escribe al menos 10 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Evidence photos (delivery receipt, package photo)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pruebas de entrega o empaque (opcional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCamera01,
                            size: 20,
                            color: Color(0xFF4F46E5),
                          ),
                          onPressed: isSubmitting ? null : () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            size: 20,
                            color: Color(0xFF4F46E5),
                          ),
                          onPressed: isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ],
                ),

                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedFiles.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedFiles[index],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (!isSubmitting)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ] else ...[
                // Direct acceptance explanation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Conciliación Directa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Al aceptar el reclamo, confirmas que estás de acuerdo con la petición del cliente (reembolso o reposición acordada). Esto resolverá el caso de forma inmediata sin escalar a penalizaciones.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF047857), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Inline Error Alert Banner
              if (actionState.error != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          actionState.error!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Submit Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCounterMode
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isCounterMode
                              ? 'Enviar Respuesta al Reclamo'
                              : 'Confirmar y Aceptar Reclamo',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
