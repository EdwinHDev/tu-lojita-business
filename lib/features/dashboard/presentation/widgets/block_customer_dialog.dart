import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/error_parser.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';

/// Modal bottom sheet allowing a store owner/admin to restrict a customer's ability
/// to place orders or make purchases in their store, either by selecting an existing
/// customer or by entering their registered email.
class BlockCustomerDialog extends ConsumerStatefulWidget {
  final String storeId;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final String? customerAvatar;
  final String? initialReason;

  const BlockCustomerDialog({
    super.key,
    required this.storeId,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.customerAvatar,
    this.initialReason,
  });

  /// Helper static method to open the modal bottom sheet smoothly from any screen
  static Future<bool?> show({
    required BuildContext context,
    required String storeId,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerAvatar,
    String? initialReason,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (ctx) => BlockCustomerDialog(
        storeId: storeId,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerAvatar: customerAvatar,
        initialReason: initialReason,
      ),
    );

    if (result == true && context.mounted) {
      final name = (customerName != null && customerName.trim().isNotEmpty)
          ? customerName.trim()
          : 'Cliente';
      NotificationService.showSuccess(
        context,
        '$name restringido exitosamente',
      );
    }
    return result;
  }

  @override
  ConsumerState<BlockCustomerDialog> createState() =>
      _BlockCustomerDialogState();
}

class _BlockCustomerDialogState extends ConsumerState<BlockCustomerDialog> {
  late final TextEditingController _emailController;
  late final TextEditingController _reasonController;
  bool _isSubmitting = false;
  String? _motiveError;
  String? _serverError;

  final List<String> _quickReasons = const [
    'Cuotas vencidas y mora reiterada',
    'Incumplimiento en pagos acordados',
    'Conducta inapropiada o fraudulenta',
    'Disputas o reclamos infundados',
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.customerEmail ?? '');
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
    _reasonController.addListener(_onReasonChanged);
    _emailController.addListener(_onEmailChanged);
  }

  void _onReasonChanged() {
    if (_motiveError != null && _reasonController.text.trim().isNotEmpty) {
      setState(() => _motiveError = null);
    }
  }

  void _onEmailChanged() {
    if (_serverError != null) {
      setState(() => _serverError = null);
    }
  }

  void _selectQuickReason(String reason) {
    setState(() {
      _reasonController.text = reason;
      _motiveError = null;
      _serverError = null;
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _reasonController.removeListener(_onReasonChanged);
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isManualEmailMode =>
      widget.customerId == null || widget.customerId!.trim().isEmpty;

  Future<void> _submitBlock() async {
    final email = _emailController.text.trim().toLowerCase();
    final reason = _reasonController.text.trim();

    if (_isManualEmailMode) {
      if (email.isEmpty) {
        setState(() {
          _serverError = 'Ingresa el correo electrónico del cliente';
        });
        NotificationService.showWarning(
          context,
          'Ingresa el correo electrónico del cliente',
        );
        return;
      }
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        setState(() {
          _serverError = 'Ingresa un formato de correo electrónico válido';
        });
        NotificationService.showWarning(
          context,
          'Ingresa un formato de correo electrónico válido',
        );
        return;
      }
    }

    if (reason.isEmpty) {
      setState(() {
        _motiveError =
            'Debes seleccionar una opción o escribir el motivo de la restricción';
      });
      NotificationService.showWarning(
        context,
        'Debes seleccionar una opción o escribir el motivo de la restricción',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _motiveError = null;
      _serverError = null;
    });

    final payload = <String, dynamic>{
      'reason': reason,
    };
    if (widget.customerId != null && widget.customerId!.trim().isNotEmpty) {
      payload['customerId'] = widget.customerId!.trim();
    }
    if (email.isNotEmpty) {
      payload['email'] = email;
    }

    final dio = ref.read(dioProvider);

    try {
      try {
        await dio.post(
          '/stores/${widget.storeId}/blocks',
          data: payload,
        );
      } on DioException catch (dioErr) {
        // Fallback for compatibility if customerId is present
        if (dioErr.response?.statusCode == 404 &&
            widget.customerId != null &&
            widget.customerId!.trim().isNotEmpty) {
          await dio.post(
            '/stores/${widget.storeId}/blocks/${widget.customerId!.trim()}',
            data: {'reason': reason},
          );
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final parsedErr = ErrorParser.parse(e);
      setState(() {
        _isSubmitting = false;
        _serverError = parsedErr;
      });
      NotificationService.showError(
        context,
        'Error al restringir cliente: $parsedErr',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = (widget.customerName != null &&
            widget.customerName!.trim().isNotEmpty)
        ? widget.customerName!.trim()[0].toUpperCase()
        : 'C';

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle with swipe-down dismissal
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! > 180) {
                          Navigator.of(context).pop(false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header con icono y botón cerrar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedUserBlock01,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Restringir Cliente',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isManualEmailMode
                                  ? 'Restringe las compras usando su correo registrado'
                                  : 'Impide que este cliente realice compras en tu tienda',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tarjeta informativa de reglas de restricción
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Efectos de la restricción',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildEffectRow(
                          icon: Icons.check_circle_outline,
                          iconColor: const Color(0xFF10B981),
                          text: 'Podrá seguir viendo tu catálogo y vitrina pública.',
                        ),
                        const SizedBox(height: 4),
                        _buildEffectRow(
                          icon: Icons.cancel_outlined,
                          iconColor: const Color(0xFFEF4444),
                          text: 'No podrá realizar pedidos, compras ni abonar cuotas.',
                        ),
                        const SizedBox(height: 4),
                        _buildEffectRow(
                          icon: Icons.chat_bubble_outline,
                          iconColor: const Color(0xFF6366F1),
                          text: 'Podrá solicitar mediación a través de tu buzón si lo requiere.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Si está en modo contextual con cliente ya identificado
                  if (!_isManualEmailMode) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFFEE2E2),
                            child: Text(
                              initialLetter,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customerName ?? 'Cliente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.customerEmail != null &&
                                    widget.customerEmail!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.alternate_email,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.customerEmail!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Campo de Correo Electrónico para modo manual
                    const Text(
                      'Correo electrónico del cliente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'cliente@ejemplo.com',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedMail01,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDC2626),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Motivos sugeridos
                  const Text(
                    'Motivos frecuentes:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickReasons.map((reason) {
                      final isSelected =
                          _reasonController.text.trim() == reason;
                      return InkWell(
                        onTap: () => _selectQuickReason(reason),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Campo de motivo detallado
                  const Text(
                    'Detalle o justificación:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText:
                          'Escribe los comentarios o la razón interna de esta restricción...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alerta inline si falta el motivo
                  if (_motiveError != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _motiveError!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Alerta inline en caso de error del servidor
                  if (_serverError != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFD97706),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _serverError!,
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botón CTA Principal
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedUserBlock01,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  !_isManualEmailMode
                                      ? 'Confirmar Restricción'
                                      : 'Restringir Cliente',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEffectRow({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
