import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';
import 'order_details_screen.dart';
import '../widgets/accounts_receivable_calendar_view.dart';

class StoreInstallmentsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreInstallmentsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreInstallmentsScreen> createState() => _StoreInstallmentsScreenState();
}

class _StoreInstallmentsScreenState extends ConsumerState<StoreInstallmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final installmentsAsync = ref.watch(storeInstallmentsProvider(widget.storeId));

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Cuotas y Deudas',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF4F46E5),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF4F46E5),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            padding: EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              Tab(text: 'Todas'),
              Tab(text: 'Pendientes'),
              Tab(text: 'Vencidas'),
              Tab(text: 'Pagadas'),
              Tab(text: 'Calendario de Cobros'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: installmentsAsync.when(
                data: (installments) {
                  if (installments.isEmpty) {
                    return _buildEmptyState(hasQueryOrFilter: false);
                  }
                  return TabBarView(
                    children: [
                      _buildFilteredList(installments, null),
                      _buildFilteredList(installments, 'PENDING'),
                      _buildFilteredList(installments, 'OVERDUE'),
                      _buildFilteredList(installments, 'PAID'),
                      AccountsReceivableCalendarView(storeId: widget.storeId),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ),
                error: (err, stack) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Buscar por cliente o ID de orden...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilteredList(List<Installment> installments, String? filter) {
    final filtered = installments.where((inst) {
      final isOverdue = inst.dueDate.isBefore(DateTime.now()) && inst.status == 'PENDING';
      
      // Filter by status
      bool matchesStatus = true;
      if (filter == 'PENDING') {
        matchesStatus = inst.status == 'PENDING' && !isOverdue;
      } else if (filter == 'OVERDUE') {
        matchesStatus = inst.status == 'PENDING' && isOverdue;
      } else if (filter == 'PAID') {
        matchesStatus = inst.status == 'PAID';
      }

      // Filter by search query
      final order = inst.order;
      final user = order?.user;
      final firstName = user?['firstName'] as String? ?? '';
      final lastName = user?['lastName'] as String? ?? '';
      String userName = '$firstName $lastName'.trim();
      if (userName.isEmpty) {
        userName = user?['name'] as String? ?? 'Cliente Desconocido';
      }
      final orderId = order?.id ?? '';

      final matchesQuery = _searchQuery.isEmpty ||
          userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          orderId.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesQuery;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(hasQueryOrFilter: _searchQuery.isNotEmpty || filter != null);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final installment = filtered[index];
        return _buildInstallmentCard(context, installment);
      },
    );
  }

  Widget _buildInstallmentCard(BuildContext context, Installment installment) {
    final order = installment.order;
    final user = order?.user;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    String userName = '$firstName $lastName'.trim();
    if (userName.isEmpty) {
      userName = user?['name'] as String? ?? 'Cliente Desconocido';
    }

    final isOverdue = installment.dueDate.isBefore(DateTime.now()) && installment.status == 'PENDING';
    final (statusBgColor, statusTextColor, statusText) = _statusBadgeStyle(installment.status, isOverdue);

    final displayOrderId = order != null && order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order?.id.toUpperCase() ?? '';

    final double remainingAmount = installment.amount + installment.lateFeeApplied - installment.paidAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pedido #$displayOrderId',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha de Vencimiento',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: isOverdue ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        installment.dueDate.toSlashDateString(),
                        style: TextStyle(
                          color: isOverdue ? const Color(0xFFB91C1C) : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    installment.status == 'PAID' ? 'Monto Pagado' : 'Pendiente Real',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${remainingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Abono progress bar
          if (installment.paidAmount > 0 && installment.status != 'PAID') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: installment.paidAmount / (installment.amount + installment.lateFeeApplied),
                backgroundColor: const Color(0xFFF1F5F9),
                color: const Color(0xFF10B981),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Abonado: \$${installment.paidAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
                Text(
                  'Cuota total: \$${(installment.amount + installment.lateFeeApplied).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],

          // Extension status badge
          if (installment.extensionStatus != 'NONE') ...[
            const SizedBox(height: 12),
            _buildMerchantExtensionBadge(installment),
          ],

          // Extension pending actions
          if (installment.extensionStatus == 'PENDING') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Solicitud: ${installment.extensionRequestedDays ?? 7} días adicionales',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                  if (installment.extensionReason != null && installment.extensionReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Motivo: "${installment.extensionReason}"',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _showRejectExtensionDialog(context, installment),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Rechazar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _approveExtension(context, installment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        child: const Text('Aprobar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (order != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(
                        order: order,
                        storeId: widget.storeId,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Ver Detalles del Pedido',
                  style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, String) _statusBadgeStyle(String status, bool isOverdue) {
    if (isOverdue) {
      return (
        const Color(0xFFFEF2F2),
        const Color(0xFFB91C1C),
        'VENCIDO',
      );
    }
    switch (status) {
      case 'PAID':
        return (
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
          'PAGADO',
        );
      case 'PENDING':
        return (
          const Color(0xFFFFF7ED),
          const Color(0xFFC2410C),
          'PENDIENTE',
        );
      default:
        return (
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
          status,
        );
    }
  }

  Widget _buildEmptyState({required bool hasQueryOrFilter}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedInvoice01,
                color: Color(0xFF94A3B8),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQueryOrFilter ? 'No se encontraron resultados' : 'No hay cuotas registradas',
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              hasQueryOrFilter
                  ? 'Prueba buscando con otros términos o filtros.'
                  : 'Las cuotas y deudas aparecerán listadas aquí.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantExtensionBadge(Installment installment) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;
    
    switch (installment.extensionStatus) {
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'Solicitud de prórroga pendiente';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'APPROVED':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        label = 'Prórroga aprobada (+${installment.extensionRequestedDays ?? 7} días)';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Prórroga rechazada';
        icon = Icons.cancel_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (installment.extensionStatus == 'REJECTED' && installment.extensionMerchantComment != null) ...[
            const SizedBox(height: 4),
            Text(
              'Motivo rechazo: "${installment.extensionMerchantComment}"',
              style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectExtensionDialog(BuildContext context, Installment installment) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Rechazar Prórroga', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Por favor, indica la razón del rechazo para informar al cliente:', style: TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ej. No se permiten prórrogas consecutivas...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                if (comment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, indica un motivo de rechazo.')),
                  );
                  return;
                }
                Navigator.pop(context);
                
                try {
                  await ref.read(verifyExtensionProvider({
                    'installmentId': installment.id,
                    'status': 'REJECTED',
                    'merchantComment': comment,
                    'storeId': widget.storeId,
                  }).future);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prórroga rechazada correctamente.'), backgroundColor: Color(0xFFDC2626)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveExtension(BuildContext context, Installment installment) async {
    try {
      await ref.read(verifyExtensionProvider({
        'installmentId': installment.id,
        'status': 'APPROVED',
        'merchantComment': 'Prórroga aprobada por la tienda.',
        'storeId': widget.storeId,
      }).future);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prórroga aprobada con éxito!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
