import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';

class StoreHealthSheet extends ConsumerStatefulWidget {
  final String storeId;

  const StoreHealthSheet({super.key, required this.storeId});

  static Future<void> show(BuildContext context, String storeId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreHealthSheet(storeId: storeId),
    );
  }

  @override
  ConsumerState<StoreHealthSheet> createState() => _StoreHealthSheetState();
}

class _StoreHealthSheetState extends ConsumerState<StoreHealthSheet> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _strikes = [];

  @override
  void initState() {
    super.initState();
    _fetchStrikes();
  }

  Future<void> _fetchStrikes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/reports/stores/${widget.storeId}/strikes');
      if (res.data is List) {
        if (mounted) {
          setState(() {
            _strikes = List<Map<String, dynamic>>.from(res.data);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _strikes = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar el historial de sanciones.';
          _isLoading = false;
        });
      }
    }
  }

  int get _activeStrikesCount {
    final now = DateTime.now();
    return _strikes.where((s) {
      final isRevoked = s['isRevoked'] == true;
      if (isRevoked) return false;
      final expiresAtStr = s['expiresAt'];
      if (expiresAtStr == null) return true;
      final expiresAt = DateTime.tryParse(expiresAtStr.toString());
      if (expiresAt == null) return true;
      return expiresAt.isAfter(now);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _activeStrikesCount;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Salud del Comercio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Monitoreo de sanciones, reportes y normativas',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchStrikes,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          _buildStatusCard(activeCount),
                          const SizedBox(height: 20),
                          _buildStrikesProgress(activeCount),
                          const SizedBox(height: 24),
                          const Text(
                            'Historial de Infracciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_strikes.isEmpty)
                            _buildCleanState()
                          else
                            ..._strikes.map((s) => _buildStrikeTile(s)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(int activeCount) {
    Color bg;
    Color border;
    Color titleColor;
    dynamic icon;
    String title;
    String subtitle;
    String desc;

    if (activeCount == 0) {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFFA7F3D0);
      titleColor = const Color(0xFF065F46);
      icon = HugeIcons.strokeRoundedCheckmarkCircle02;
      title = 'Comercio en Excelente Estado';
      subtitle = '0 de 3 strikes de sanción';
      desc =
          'Tu tienda cumple todas las políticas comunitarias de Tu Lojita. Tienes plena visibilidad y recepción de órdenes activas.';
    } else if (activeCount == 1) {
      bg = const Color(0xFFFEFCE8);
      border = const Color(0xFFFDE047);
      titleColor = const Color(0xFF854D0E);
      icon = HugeIcons.strokeRoundedAlert02;
      title = 'Advertencia Activa (1/3 Strikes)';
      subtitle = '1 infracción registrada';
      desc =
          'Tu tienda tiene una sanción vigente con vigencia de 90 días. Revisa tus productos y operaciones para evitar acumular 3 strikes.';
    } else if (activeCount == 2) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECDD3);
      titleColor = const Color(0xFF9F1239);
      icon = HugeIcons.strokeRoundedAlertDiamond;
      title = 'Riesgo Crítico de Suspensión (2/3)';
      subtitle = '2 infracciones registradas';
      desc =
          '¡Atención! Tu comercio se encuentra a solo 1 strike de ser suspendido automáticamente por la plataforma.';
    } else {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      titleColor = const Color(0xFF991B1B);
      icon = HugeIcons.strokeRoundedAlertCircle;
      title = 'Comercio Suspendido (3/3)';
      subtitle = 'Límite de sanciones alcanzado';
      desc =
          'Tu catálogo público se encuentra temporalmente oculto para compradores. Comunícate con mediación para regularizar tu situación.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: titleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: titleColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrikesProgress(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nivel de Sanción Acumulado',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '$activeCount / 3 Strikes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: activeCount >= 3
                      ? const Color(0xFFDC2626)
                      : activeCount == 2
                          ? const Color(0xFFE11D48)
                          : activeCount == 1
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildProgressBar(1, activeCount)),
              const SizedBox(width: 6),
              Expanded(child: _buildProgressBar(2, activeCount)),
              const SizedBox(width: 6),
              Expanded(child: _buildProgressBar(3, activeCount)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Advertencia', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              Text('Riesgo', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              Text('Suspensión', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int step, int activeCount) {
    final isReached = activeCount >= step;
    Color barColor;
    if (step == 1) {
      barColor = isReached ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB);
    } else if (step == 2) {
      barColor = isReached ? const Color(0xFFF97316) : const Color(0xFFE5E7EB);
    } else {
      barColor = isReached ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB);
    }

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCleanState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          children: const [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Color(0xFF10B981),
              size: 40,
            ),
            SizedBox(height: 12),
            Text(
              '¡Sin sanciones ni infracciones!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tu comercio mantiene un historial limpio y ejemplar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrikeTile(Map<String, dynamic> strike) {
    final now = DateTime.now();
    final isRevoked = strike['isRevoked'] == true;
    final expiresAtStr = strike['expiresAt'];
    final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr.toString()) : null;
    final isExpired = expiresAt != null && expiresAt.isBefore(now);
    final isActive = !isRevoked && !isExpired;

    final createdAtStr = strike['createdAt'];
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr.toString()) : null;
    final dateFormatted = createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt) : '';

    String statusLabel;
    Color statusBg;
    Color statusColor;

    if (isRevoked) {
      statusLabel = 'Revocado';
      statusBg = const Color(0xFFF3F4F6);
      statusColor = const Color(0xFF6B7280);
    } else if (isExpired) {
      statusLabel = 'Vencido';
      statusBg = const Color(0xFFF3F4F6);
      statusColor = const Color(0xFF9CA3AF);
    } else {
      statusLabel = 'Activo';
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
          width: isActive ? 1.5 : 1,
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAlertSquare,
                      color: isActive
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF9CA3AF),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Infracción $dateFormatted',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            strike['reason'] ?? 'Infracción a normas de la plataforma',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF374151),
            ),
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedTime02,
                  size: 13,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 5),
                Text(
                  isActive
                      ? 'Vence el: ${DateFormat('dd/MM/yyyy').format(expiresAt)}'
                      : 'Venció el: ${DateFormat('dd/MM/yyyy').format(expiresAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
