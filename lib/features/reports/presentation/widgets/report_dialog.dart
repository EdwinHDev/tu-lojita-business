import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

class _ChatPreset {
  final String key;
  final String label;
  final String backendCategory;
  final String defaultDescription;

  const _ChatPreset({
    required this.key,
    required this.label,
    required this.backendCategory,
    required this.defaultDescription,
  });
}

class ReportDialog extends ConsumerStatefulWidget {
  final String title;
  final String reportType; // 'STORE', 'ITEM', 'CHAT_MESSAGE', 'USER'
  final String? targetStoreId;
  final String? targetItemId;
  final String? targetChatMessageId;
  final String? targetUserId;
  final String? messageContent;

  const ReportDialog({
    super.key,
    required this.title,
    required this.reportType,
    this.targetStoreId,
    this.targetItemId,
    this.targetChatMessageId,
    this.targetUserId,
    this.messageContent,
  });

  @override
  ConsumerState<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<ReportDialog> {
  final _reasonController = TextEditingController();
  late String _selectedCategory;
  bool _isSubmitting = false;

  static const List<_ChatPreset> _chatPresets = [
    _ChatPreset(
      key: 'OFFENSIVE_CONTENT',
      label: 'Insultos, agresión o trato irrespetuoso',
      backendCategory: 'OFFENSIVE_CONTENT',
      defaultDescription: 'Mensaje con insultos, faltas de respeto o agresión verbal.',
    ),
    _ChatPreset(
      key: 'HARASSMENT',
      label: 'Acoso, amenazas o intimidación',
      backendCategory: 'HARASSMENT',
      defaultDescription: 'Mensaje con acoso reiterado, amenazas o intimidación.',
    ),
    _ChatPreset(
      key: 'FRAUD_SCAM',
      label: 'Intento de estafa o comprobante fraudulento',
      backendCategory: 'FRAUD_SCAM',
      defaultDescription: 'Sospecha o intento de estafa mediante comprobantes de pago falsos o desvío no autorizado.',
    ),
    _ChatPreset(
      key: 'SPAM',
      label: 'Spam o publicidad externa no deseada',
      backendCategory: 'OTHER',
      defaultDescription: 'Mensaje no deseado, publicidad ajena o enlaces externos sospechosos.',
    ),
    _ChatPreset(
      key: 'EXTORTION',
      label: 'Exigencias indebidas o extorsión',
      backendCategory: 'OTHER',
      defaultDescription: 'Exigencias indebidas, condiciones fuera de la plataforma o chantajes.',
    ),
    _ChatPreset(
      key: 'OTHER',
      label: 'Otro motivo (Personalizado)',
      backendCategory: 'OTHER',
      defaultDescription: '',
    ),
  ];

  static const Map<String, String> _catalogCategories = {
    'FRAUD_SCAM': 'Fraude o sospecha de estafa',
    'PROHIBITED_GOODS': 'Artículos o servicios prohibidos',
    'OFFENSIVE_CONTENT': 'Contenido ofensivo o inapropiado',
    'HARASSMENT': 'Acoso o amenazas',
    'INTELLECTUAL_PROPERTY': 'Infracción de marca o autor',
    'UNDERAGE_VIOLATION': 'Contenido inapropiado para menores',
    'OTHER': 'Otro motivo',
  };

  bool get _isChatMessage => widget.reportType == 'CHAT_MESSAGE';

  @override
  void initState() {
    super.initState();
    _selectedCategory = _isChatMessage ? _chatPresets.first.key : 'FRAUD_SCAM';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final customText = _reasonController.text.trim();
    String finalCategory = _selectedCategory;
    String finalReason = '';

    if (_isChatMessage) {
      final preset = _chatPresets.firstWhere(
        (p) => p.key == _selectedCategory,
        orElse: () => _chatPresets.last,
      );

      finalCategory = preset.backendCategory;

      if (preset.key == 'OTHER') {
        if (customText.isEmpty) {
          NotificationService.showError(
            context,
            'Por favor describe brevemente el motivo del reporte.',
          );
          return;
        }
        finalReason = customText;
      } else {
        if (customText.isNotEmpty) {
          finalReason = '[${preset.label}] $customText';
        } else {
          finalReason = preset.defaultDescription;
        }
      }
    } else {
      if (customText.isEmpty) {
        NotificationService.showError(
          context,
          'Por favor describe brevemente el motivo del reporte.',
        );
        return;
      }
      finalCategory = _selectedCategory;
      finalReason = customText;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/reports',
        data: {
          'type': widget.reportType,
          'category': finalCategory,
          'reason': finalReason,
          if (widget.targetStoreId != null)
            'targetStoreId': widget.targetStoreId,
          if (widget.targetItemId != null)
            'targetItemId': widget.targetItemId,
          if (widget.targetChatMessageId != null)
            'targetChatMessageId': widget.targetChatMessageId,
          if (widget.targetUserId != null)
            'targetUserId': widget.targetUserId,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      NotificationService.showSuccess(
        context,
        'Reporte enviado exitosamente. Moderación lo revisará a la brevedad.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      NotificationService.showError(
        context,
        'No se pudo enviar el reporte. Intenta más tarde.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomReasonRequired = !_isChatMessage || _selectedCategory == 'OTHER';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.messageContent != null && widget.messageContent!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF64748B), width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Text(
                          'Mensaje a reportar:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“${widget.messageContent!.length > 160 ? '${widget.messageContent!.substring(0, 160)}...' : widget.messageContent}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Selecciona el motivo:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _isChatMessage
                      ? _chatPresets.map((preset) {
                          return DropdownMenuItem<String>(
                            value: preset.key,
                            child: Text(
                              preset.label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList()
                      : _catalogCategories.entries.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          );
                        }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCustomReasonRequired
                  ? 'Descripción o detalles (obligatorio):'
                  : 'Detalles adicionales (opcional):',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: isCustomReasonRequired
                    ? 'Explica qué ocurrió de forma concisa...'
                    : 'Puedes agregar contexto adicional si lo deseas...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enviar Reporte',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
