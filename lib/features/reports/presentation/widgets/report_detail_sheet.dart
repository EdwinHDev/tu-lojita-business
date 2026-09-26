import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';

class ReportDetailSheet extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailSheet({
    super.key,
    required this.reportId,
  });

  static Future<void> show(BuildContext context, String reportId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportDetailSheet(reportId: reportId),
    );
  }

  @override
  ConsumerState<ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends ConsumerState<ReportDetailSheet> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/reports/${widget.reportId}');
      if (mounted) {
        setState(() {
          _report = res.data is Map<String, dynamic>
              ? res.data as Map<String, dynamic>
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e is DioException && e.response?.data?['message'] != null
              ? e.response!.data['message'].toString()
              : 'No se pudo obtener el detalle de este reporte.';
        });
      }
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '-';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a', 'es_ES').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _getCategoryLabel(String? cat) {
    switch (cat) {
      case 'FRAUD_SCAM':
        return 'Fraude o sospecha de estafa';
      case 'PROHIBITED_GOODS':
        return 'Artículos prohibidos';
      case 'OFFENSIVE_CONTENT':
        return 'Contenido inapropiado';
      case 'HARASSMENT':
        return 'Acoso o amenazas';
      case 'INTELLECTUAL_PROPERTY':
        return 'Propiedad intelectual';
      case 'UNDERAGE_VIOLATION':
        return 'Infracción sobre menores';
      default:
        return 'Infracción comunitaria';
    }
  }

  static ({String? penaltyBadge, String cleanNotes}) _parseAdminNotes(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (penaltyBadge: null, cleanNotes: '');
    }
    final regex = RegExp(
      r'^\[(?:Sanción|Sancion)\s+(?:de|del)\s+Chat:\s*([A-Za-z0-9_]+)\]\s*',
      caseSensitive: false,
    );
    final match = regex.firstMatch(raw.trim());
    if (match != null) {
      final tier = match.group(1)?.toUpperCase() ?? '';
      final cleanText = raw.trim().substring(match.end).trim();
      String badgeText;
      switch (tier) {
        case 'WARNING':
          badgeText = 'Advertencia formal de moderación';
          break;
        case 'SUSPEND_72H':
        case 'SUSPEND_72':
          badgeText = 'Suspensión temporal de chat por 72 horas (3 días)';
          break;
        case 'SUSPEND_15D':
        case 'SUSPEND_15':
          badgeText = 'Suspensión temporal de chat por 15 días';
          break;
        case 'SUSPEND_30D':
        case 'SUSPEND_30':
          badgeText = 'Suspensión temporal de chat por 30 días';
          break;
        case 'BAN_PERMANENT':
        case 'BAN':
        case 'PERMANENT':
          badgeText = 'Suspensión definitiva del chat';
          break;
        default:
          badgeText = 'Sanción disciplinaria de chat';
      }
      return (penaltyBadge: badgeText, cleanNotes: cleanText);
    }
    return (penaltyBadge: null, cleanNotes: raw.trim());
  }

  String _getActionLabel(String? action, String? adminNotes) {
    final parsed = _parseAdminNotes(adminNotes);
    if (parsed.penaltyBadge != null) {
      return parsed.penaltyBadge!;
    }
    if (action == 'CHAT_PENALTY_APPLIED') {
      return 'Sanción disciplinaria de chat';
    }
    switch (action) {
      case 'STRIKE_ISSUED':
        return 'Strike Aplicado';
      case 'STORE_SUSPENDED':
        return 'Tienda Suspendida';
      case 'ITEM_HIDDEN':
        return 'Publicación Ocultada';
      case 'DISMISSED':
        return 'Reporte Desestimado';
      case 'NONE':
        return 'Revisado sin sanción';
      default:
        return action ?? 'Evaluado';
    }
  }

  String? _resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final clean = path.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    final base = Envs.apiBaseUrlImages;
    return clean.startsWith('/') ? '$base$clean' : '$base/$clean';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertSquare,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalle de Moderación',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Reporte #${widget.reportId.length >= 8 ? widget.reportId.substring(0, 8) : widget.reportId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

          // Body
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF4F46E5)),
                          SizedBox(height: 16),
                          Text(
                            'Cargando detalles de moderación...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _error != null || _report == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedAlertCircle,
                                color: Color(0xFFEF4444),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error ?? 'Reporte no disponible',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _fetchReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final rep = _report!;
    final status = rep['status'] as String? ?? 'PENDING';
    final actionTaken = rep['actionTaken'] as String? ?? 'NONE';
    final adminNotes = rep['adminNotes'] as String?;
    final reason = rep['reason'] as String? ?? '';
    final category = rep['category'] as String?;
    final createdAt = rep['createdAt'];
    final resolvedAt = rep['resolvedAt'];
    final evidenceUrl = _resolveImageUrl(rep['evidenceUrl'] as String?);

    final targetStore = rep['targetStore'] as Map<String, dynamic>?;
    final targetItem = rep['targetItem'] as Map<String, dynamic>?;
    final targetChatMessage = rep['targetChatMessage'] as Map<String, dynamic>?;
    final rawEvidenceMessages = rep['evidenceMessages'];
    final List<String> evidenceMessages = (rawEvidenceMessages is List)
        ? rawEvidenceMessages
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : const [];

    final isResolved = status == 'RESOLVED';
    final isDismissed = status == 'DISMISSED';

    final Color statusColor = isResolved
        ? const Color(0xFF10B981)
        : isDismissed
            ? const Color(0xFF64748B)
            : const Color(0xFFF59E0B);

    final Color statusBg = isResolved
        ? const Color(0xFFECFDF5)
        : isDismissed
            ? const Color(0xFFF1F5F9)
            : const Color(0xFFFFFBEB);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Status & Action Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isResolved
                          ? 'RESUELTO'
                          : isDismissed
                              ? 'DESESTIMADO'
                              : 'EN REVISIÓN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _getActionLabel(actionTaken, adminNotes),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _getCategoryLabel(category),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDismissed ? const Color(0xFF334155) : statusColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reported Entity Card (if applicable)
        if (evidenceMessages.isNotEmpty) ...[
          _buildCard(
            title: 'Mensajes Citados como Evidencia (${evidenceMessages.where((e) => !e.contains('Se omitieron mensajes')).length})',
            icon: HugeIcons.strokeRoundedMessage01,
            color: const Color(0xFF4F46E5),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...evidenceMessages.map((msg) {
                  final isGap = msg.contains('Se omitieron mensajes');
                  if (isGap) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedMoreHorizontalCircle01,
                            color: Color(0xFF64748B),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Se omitieron mensajes intermedios',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      msg,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        height: 1.35,
                      ),
                    ),
                  );
                }),
                if (targetChatMessage?['sender'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Remitente denunciado: ${(targetChatMessage!['sender'] as Map)['firstName'] ?? 'Usuario'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (targetChatMessage != null) ...[
          _buildCard(
            title: 'Mensaje Denunciado en Chat',
            icon: HugeIcons.strokeRoundedMessage01,
            color: const Color(0xFF4F46E5),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '"${targetChatMessage['content'] ?? ''}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                if (targetChatMessage['sender'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Remitente: ${(targetChatMessage['sender'] as Map)['firstName'] ?? 'Usuario'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (targetItem != null) ...[
          _buildCard(
            title: 'Publicación Denunciada',
            icon: HugeIcons.strokeRoundedShoppingBag01,
            color: const Color(0xFF0284C7),
            content: Row(
              children: [
                if (targetItem['mainImage'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _resolveImageUrl(targetItem['mainImage'].toString()) ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.broken_image, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetItem['title'] ?? 'Artículo',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${NumberFormat('#,##0.00').format(targetItem['price'] ?? 0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (targetStore != null) ...[
          _buildCard(
            title: 'Tienda Denunciada',
            icon: HugeIcons.strokeRoundedStore01,
            color: const Color(0xFF7C3AED),
            content: Text(
              targetStore['name'] ?? 'Tienda',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Reason Card
        _buildCard(
          title: 'Motivo y Hechos Reportados',
          icon: HugeIcons.strokeRoundedFile01,
          color: const Color(0xFF334155),
          content: Text(
            reason.isNotEmpty ? reason : 'Sin descripción adicional.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Admin Decision / Notes Card
        if (adminNotes != null && adminNotes.trim().isNotEmpty) ...[
          () {
            final parsedNotes = _parseAdminNotes(adminNotes);
            return _buildCard(
              title: 'Resolución de Moderación',
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: const Color(0xFF10B981),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parsedNotes.penaltyBadge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedAlertSquare,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              parsedNotes.penaltyBadge!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (parsedNotes.cleanNotes.isNotEmpty)
                      const SizedBox(height: 10),
                  ],
                  if (parsedNotes.cleanNotes.isNotEmpty) ...[
                    if (parsedNotes.penaltyBadge != null) ...[
                      const Text(
                        'Motivo / Detalle:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      parsedNotes.cleanNotes,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }(),
          const SizedBox(height: 14),
        ],

        // Evidence Image (if any)
        if (evidenceUrl != null) ...[
          _buildCard(
            title: 'Evidencia Adjunta',
            icon: HugeIcons.strokeRoundedImage01,
            color: const Color(0xFF64748B),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                evidenceUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No se pudo cargar la imagen de evidencia.'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Timestamps
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fecha de creación:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              if (resolvedAt != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fecha de resolución:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      _formatDate(resolvedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Close button
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Entendido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required dynamic icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}
