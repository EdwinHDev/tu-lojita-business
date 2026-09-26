import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../../domain/entities/order_dispute.dart';
import '../../../domain/enums/dispute_enums.dart';
import '../../providers/dispute_providers.dart';

/// Modal bottom sheet unificado que permite consultar el reclamo del cliente y responder
/// directamente in-situ sin modales anidados y con protección contra desbordamientos por teclado.
class OrderDisputeBottomSheet extends ConsumerStatefulWidget {
  final String orderId;
  final OrderDispute? initialDispute;

  const OrderDisputeBottomSheet({
    super.key,
    required this.orderId,
    this.initialDispute,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    OrderDispute? dispute,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDisputeBottomSheet(
        orderId: orderId,
        initialDispute: dispute,
      ),
    );
  }

  @override
  ConsumerState<OrderDisputeBottomSheet> createState() => _OrderDisputeBottomSheetState();
}

class _OrderDisputeBottomSheetState extends ConsumerState<OrderDisputeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<File> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isCounterMode = true; // true: Enviar Explicación, false: Aceptar Reclamo

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeDisputeActionNotifierProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String path) {
    var clean = path.trim();
    if (clean.contains('img.tulojita.com')) {
      clean = clean.replaceFirst('img.tulojita.com', 'images.tulojita.com');
    }
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final base = Envs.apiBaseUrlImages;
    return clean.startsWith('/') ? '$base$clean' : '$base/$clean';
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    final resolvedUrl = _resolveImageUrl(imageUrl);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  resolvedUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.black87,
                    child: const Text(
                      'Error al cargar la imagen',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _submitResponse(OrderDispute dispute) async {
    if (_isCounterMode && !_formKey.currentState!.validate()) return;

    final responseText = _isCounterMode
        ? _responseController.text.trim()
        : 'La tienda ha aceptado la solicitud del cliente de mutuo acuerdo.';

    final success = await ref
        .read(storeDisputeActionNotifierProvider.notifier)
        .respondDispute(
          disputeId: dispute.id,
          orderId: widget.orderId,
          response: responseText,
          evidenceFiles: _isCounterMode ? _selectedFiles : const [],
          acceptDispute: !_isCounterMode,
        );

    if (mounted) {
      if (success) {
        ref.invalidate(storeDisputesByOrderProvider(widget.orderId));
        Navigator.pop(context);
        NotificationService.showSuccess(
          context,
          _isCounterMode
              ? 'Respuesta enviada a mediación'
              : 'Reclamo aceptado exitosamente',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDispute = ref.watch(activeStoreDisputeProvider(widget.orderId)) ?? widget.initialDispute;
    final actionState = ref.watch(storeDisputeActionNotifierProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final totalHeight = MediaQuery.of(context).size.height;
    final availableHeight = (totalHeight - keyboardHeight).clamp(200.0, totalHeight);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de arrastre
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado del modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlertSquare,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión del Reclamo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (activeDispute != null)
                          Text(
                            'Estado: ${activeDispute.status.label}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activeDispute.status.textColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 1),

            // Contenido scrolleable y seguro ante teclado
            Flexible(
              child: activeDispute == null
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      controller: _scrollController,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. REPORTE DEL CLIENTE (Contexto visible)
                          _buildCustomerClaimCard(activeDispute),

                          const SizedBox(height: 16),

                          // 2. SECCIÓN DE RESPUESTA DEL COMERCIO
                          if (activeDispute.hasMerchantResponse) ...[
                            _buildExistingResponseCard(activeDispute),
                          ] else if (activeDispute.status.requiresMerchantAction) ...[
                            _buildResponseFormSection(activeDispute, actionState),
                          ],

                          // 3. ACCIONES BILATERALES (después de responder)
                          if (activeDispute.hasMerchantResponse &&
                              (activeDispute.canEscalate || activeDispute.merchantCanMarkResolved)) ...[
                            const SizedBox(height: 16),
                            _buildBilateralActionsSection(activeDispute, actionState),
                          ],

                          // 4. RESOLUCIÓN DE ADMINISTRACIÓN (Si aplica)
                          if (activeDispute.isResolved && activeDispute.resolution != null) ...[
                            const SizedBox(height: 16),
                            _buildAdminResolutionCard(activeDispute),
                          ],

                          // 5. Banner de cierre por consenso
                          if (activeDispute.status == DisputeStatus.resolved &&
                              activeDispute.merchantMarkedResolved &&
                              activeDispute.clientMarkedResolved) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.handshake_outlined, color: Color(0xFF059669), size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Este reclamo fue cerrado por acuerdo mutuo entre ambas partes.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildBilateralActionsSection(OrderDispute dispute, StoreDisputeActionState actionState) {
    final isActing = actionState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones de resolución',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),

        // Indicador del voto del cliente
        if (dispute.clientMarkedResolved)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El cliente ya marcó este reclamo como resuelto.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // Botón marcar resuelto (solo si la tienda aún no votó)
        if (dispute.merchantCanMarkResolved)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isActing
                  ? null
                  : () async {
                      final confirm = await _showBilateralConfirmDialog(
                        title: 'Marcar como resuelto',
                        message: dispute.clientMarkedResolved
                            ? 'El cliente ya confirmó la resolución. Al confirmar, el reclamo se cerrará por acuerdo mutuo.'
                            : 'Indica que el problema fue resuelto. Si el cliente también confirma, el reclamo se cerrará automáticamente.',
                        confirmLabel: 'Confirmar',
                        confirmColor: const Color(0xFF10B981),
                      );
                      if (!confirm || !mounted) return;

                      final success = await ref
                          .read(storeDisputeActionNotifierProvider.notifier)
                          .markResolved(disputeId: dispute.id, orderId: widget.orderId);

                      if (mounted) {
                        if (success) {
                          Navigator.pop(context);
                          NotificationService.showSuccess(
                            context,
                            dispute.clientMarkedResolved
                                ? 'Reclamo cerrado por acuerdo mutuo'
                                : 'Marcado como resuelto. Esperando confirmación del cliente.',
                          );
                        }
                      }
                    },
              icon: isActing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'Marcar como resuelto',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),

        if (dispute.merchantCanMarkResolved && dispute.canEscalate) const SizedBox(height: 8),
 
        // Botón escalar (disponible en OPEN y MERCHANT_RESPONDED)
        if (dispute.canEscalate)
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
            onPressed: isActing
                ? null
                : () async {
                    final confirm = await _showBilateralConfirmDialog(
                      title: 'Escalar a soporte',
                      message:
                          'El equipo de soporte de Tu Lojita revisará el reclamo y tomará una decisión. Esto puede demorar algunos días hábiles.',
                      confirmLabel: 'Escalar',
                      confirmColor: const Color(0xFF8B5CF6),
                    );
                    if (!confirm || !mounted) return;

                    final success = await ref
                        .read(storeDisputeActionNotifierProvider.notifier)
                        .escalate(disputeId: dispute.id, orderId: widget.orderId);

                    if (mounted) {
                      if (success) {
                        Navigator.pop(context);
                        NotificationService.showSuccess(
                          context,
                          'Reclamo escalado a soporte.',
                        );
                      }
                    }
                  },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCustomerService01,
              size: 16,
              color: Color(0xFF8B5CF6),
            ),
            label: const Text(
              'Escalar a soporte',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _showBilateralConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            content: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
            SizedBox(height: 12),
            Text(
              'No hay reclamos activos para este pedido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerClaimCard(OrderDispute dispute) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dispute.type.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dispute.createdAt.toDateTimeString(),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Reclamo del cliente:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Text(
              dispute.reason,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
          if (dispute.evidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Fotos de prueba del cliente:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dispute.evidenceUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = dispute.evidenceUrls[index];
                  return GestureDetector(
                    onTap: () => _showImagePreview(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _resolveImageUrl(url),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseFormSection(OrderDispute dispute, StoreDisputeActionState actionState) {
    final isSubmitting = actionState.isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
        children: [
          const Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedComment01,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'Tu Respuesta como Comercio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Selector de Modo (Explicación vs Aceptar)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
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
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _isCounterMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _isCounterMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
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
                            color: _isCounterMode ? const Color(0xFF1E293B) : const Color(0xFF64748B),
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
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !_isCounterMode ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: !_isCounterMode
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
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
                            color: !_isCounterMode ? const Color(0xFF059669) : const Color(0xFF64748B),
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
            const Text(
              'Tu respuesta o descargo:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _responseController,
              focusNode: _focusNode,
              scrollPadding: const EdgeInsets.only(bottom: 80),
              enabled: !isSubmitting,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Explica tu versión de los hechos o aclara la situación...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
                fillColor: const Color(0xFFF8FAFC),
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
            const SizedBox(height: 12),

            // Adjuntar pruebas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pruebas de entrega (opcional)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF64748B),
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
                      tooltip: 'Tomar foto',
                      onPressed: isSubmitting ? null : () => _pickImage(ImageSource.camera),
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedImage01,
                        size: 20,
                        color: Color(0xFF4F46E5),
                      ),
                      tooltip: 'Galería',
                      onPressed: isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),

            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedFiles.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedFiles[index],
                            width: 60,
                            height: 60,
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
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
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
            // Conciliación Directa
            Container(
              padding: const EdgeInsets.all(14),
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
                      Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Conciliación Directa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Al aceptar el reclamo, confirmas acuerdo con la petición del cliente. El caso se cerrará de forma satisfactoria sin penalizaciones.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.4),
                  ),
                ],
              ),
            ),
          ],

          if (actionState.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionState.error!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Botón de Enviar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : () => _submitResponse(dispute),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCounterMode ? const Color(0xFF2563EB) : const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isCounterMode ? 'Enviar Respuesta al Reclamo' : 'Confirmar y Aceptar Reclamo',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingResponseCard(OrderDispute dispute) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tu respuesta enviada:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              if (dispute.merchantRespondedAt != null)
                Text(
                  dispute.merchantRespondedAt!.toDateTimeString(),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF60A5FA)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dispute.merchantResponse ?? '',
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF), height: 1.4),
          ),
          if (dispute.merchantEvidenceUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 55,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dispute.merchantEvidenceUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = dispute.merchantEvidenceUrls[index];
                  return GestureDetector(
                    onTap: () => _showImagePreview(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _resolveImageUrl(url),
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminResolutionCard(OrderDispute dispute) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                'Resolución Final: ${dispute.resolution!.label}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          if (dispute.resolutionNotes != null && dispute.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dispute.resolutionNotes!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF047857), height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
