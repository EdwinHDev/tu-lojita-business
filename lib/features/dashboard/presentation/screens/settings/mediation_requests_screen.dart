import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';

class MediationRequestsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const MediationRequestsScreen({super.key, required this.storeId});

  @override
  ConsumerState<MediationRequestsScreen> createState() =>
      _MediationRequestsScreenState();
}

class _MediationRequestsScreenState
    extends ConsumerState<MediationRequestsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _requests = [];
  String _selectedFilter = 'ALL'; // ALL, PENDING, ACCEPTED, REJECTED

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _formatCustomerName(Map<String, dynamic> customer) {
    final first = customer['firstName']?.toString().trim() ?? '';
    final last = customer['lastName']?.toString().trim() ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;

    final fallback = customer['fullName']?.toString().trim() ?? '';
    if (fallback.isNotEmpty) return fallback;

    final email = customer['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'Cliente';
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response =
          await dio.get('/stores/${widget.storeId}/mediation-requests');
      if (response.data is List) {
        final list = response.data as List;
        final parsed = list.map((item) => _safeMap(item)).toList();
        if (mounted) {
          setState(() {
            _requests = parsed;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _requests = [];
            _isLoading = false;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = 'No pudimos conectar con el servidor. Verifica tu conexión e intenta de nuevo.';
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            msg = 'Error de conexión o red inestable. Por favor, reintenta.';
          } else if (e.response?.statusCode != null) {
            msg = 'Error del servidor (${e.response?.statusCode}). Por favor, reintenta.';
          }
        }
        setState(() {
          _isLoading = false;
          _errorMessage = msg;
        });
      }
    }
  }

  void _openResponseDialog(Map<String, dynamic> request) {
    final safeRequest = _safeMap(request);
    final requestId = safeRequest['id']?.toString() ?? '';
    final customer = _safeMap(safeRequest['customer']);
    final customerName = _formatCustomerName(customer);

    String selectedStatus = 'ACCEPTED';
    final responseController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Responder a $customerName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Selecciona la decisión de mediación:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // ignore: deprecated_member_use
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'ACCEPTED',
                // ignore: deprecated_member_use
                groupValue: selectedStatus,
                activeColor: const Color(0xFF10B981),
                title: const Text(
                  'Aceptar y desbloquear cliente',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'El cliente será desbloqueado inmediatamente y podrá volver a comprar.',
                  style: TextStyle(fontSize: 12),
                ),
                // ignore: deprecated_member_use
                onChanged: (val) => setModalState(() => selectedStatus = val!),
              ),
              // ignore: deprecated_member_use
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: 'REJECTED',
                // ignore: deprecated_member_use
                groupValue: selectedStatus,
                activeColor: const Color(0xFFEF4444),
                title: const Text(
                  'Rechazar solicitud de mediación',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'El cliente permanecerá restringido para compras.',
                  style: TextStyle(fontSize: 12),
                ),
                // ignore: deprecated_member_use
                onChanged: (val) => setModalState(() => selectedStatus = val!),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mensaje de respuesta para el cliente:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: selectedStatus == 'ACCEPTED'
                      ? 'Ej. Hemos revisado tu caso y aceptamos tu compromiso de pago...'
                      : 'Ej. No es posible levantar la restricción debido a cuotas aún no solventadas...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedStatus == 'ACCEPTED'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final text = responseController.text.trim();
                          if (text.isEmpty) {
                            NotificationService.showWarning(
                              context,
                              'Por favor escribe una explicación para el cliente',
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final dio = ref.read(dioProvider);
                            await dio.patch(
                              '/stores/${widget.storeId}/mediation-requests/$requestId',
                              data: {
                                'status': selectedStatus,
                                'storeResponse': text,
                              },
                            );

                            if (!context.mounted) return;
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            NotificationService.showSuccess(
                              context,
                              selectedStatus == 'ACCEPTED'
                                  ? 'Solicitud aceptada y cliente desbloqueado'
                                  : 'Solicitud rechazada',
                            );
                            _fetchRequests();
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (!context.mounted) return;
                            NotificationService.showError(
                              context,
                              'Error al responder solicitud: $e',
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          selectedStatus == 'ACCEPTED'
                              ? 'Aceptar Solicitud'
                              : 'Rechazar Solicitud',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final filtered = _requests.where((r) {
      if (_selectedFilter == 'ALL') return true;
      return (r['status'] ?? '').toString().toUpperCase() == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solicitudes de Mediación',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Todas'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Pendientes'),
                const SizedBox(width: 8),
                _buildFilterChip('ACCEPTED', 'Aceptadas'),
                const SizedBox(width: 8),
                _buildFilterChip('REJECTED', 'Rechazadas'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F46E5),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Problema de conexión',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _fetchRequests,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text(
                                  'Reintentar conexión',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                    color: const Color(0xFF4F46E5),
                    onRefresh: _fetchRequests,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.mark_email_read_outlined,
                                          color: Color(0xFF3B82F6),
                                          size: 48,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Buzón al día',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'No tienes solicitudes de mediación en este estado.',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _safeMap(filtered[index]);
                              final customer = _safeMap(item['customer']);
                              final customerName = _formatCustomerName(customer);
                              final customerEmail =
                                  (customer['email'] ?? '').toString();
                              final rawSubject = (item['subject'] ??
                                      item['topic'] ??
                                      'Solicitud de Reactivación')
                                  .toString();
                              final subject = _formatMediationTopic(rawSubject);
                              final reason =
                                  (item['reason'] ?? item['message'] ?? '').toString();
                              final proposedResolution =
                                  (item['proposedResolution'] ?? '').toString();
                              final status = (item['status'] ?? 'PENDING')
                                  .toString()
                                  .toUpperCase();
                              final storeResponse =
                                  (item['storeResponse'] ?? '').toString();
                              final createdAt =
                                  (item['createdAt'] ?? '').toString();

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subject,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                        _buildStatusBadge(status),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            customerName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                        ),
                                        if (customerEmail.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '($customerEmail)',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade100,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Planteamiento del cliente:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF4B5563),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            reason,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          if (proposedResolution.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Solución propuesta por cliente:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: Color(0xFF047857),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              proposedResolution,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF065F46),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (storeResponse.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: status == 'ACCEPTED'
                                              ? const Color(0xFFECFDF5)
                                              : const Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Respuesta de tu tienda:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: status == 'ACCEPTED'
                                                    ? const Color(0xFF065F46)
                                                    : const Color(0xFF991B1B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              storeResponse,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: status == 'ACCEPTED'
                                                    ? const Color(0xFF047857)
                                                    : const Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (createdAt.isNotEmpty)
                                          Text(
                                            createdAt.split('T').first,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        if (status == 'PENDING')
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF4F46E5),
                                              foregroundColor: Colors.white,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                  BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.reply,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Responder',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _openResponseDialog(item),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4B5563),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'ACCEPTED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        text = 'Aceptada';
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        text = 'Rechazada';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        text = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatMediationTopic(String? rawTopic) {
    if (rawTopic == null || rawTopic.isEmpty) return 'Solicitud de reactivación';
    switch (rawTopic.trim().toUpperCase()) {
      case 'ACCOUNT_REACTIVATION':
        return 'Reactivación de compras';
      case 'SETTLE_DEBT':
        return 'Acuerdo de saldo pendiente';
      case 'CLARIFY_MISUNDERSTANDING':
        return 'Aclaratoria de malentendido';
      case 'OTHER':
        return 'Consulta general';
      default:
        if (rawTopic.contains('ACCOUNT_REACTIVATION')) {
          return rawTopic.replaceAll('ACCOUNT_REACTIVATION', 'Reactivación de compras');
        }
        return rawTopic;
    }
  }
}
