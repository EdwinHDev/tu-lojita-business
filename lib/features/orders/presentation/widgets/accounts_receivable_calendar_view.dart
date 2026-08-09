import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../providers/orders_provider.dart';
import '../../domain/entities/order.dart';
import '../screens/order_details_screen.dart';

class AccountsReceivableCalendarView extends ConsumerWidget {
  final String storeId;

  const AccountsReceivableCalendarView({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivablesAsync = ref.watch(storeReceivablesProvider(storeId));

    return receivablesAsync.when(
      data: (installments) {
        if (installments.isEmpty) {
          return _buildEmptyState();
        }

        // Calcular Métricas
        double totalOutstanding = 0.0;
        double totalOverdue = 0.0;
        double totalThisWeek = 0.0;
        final now = DateTime.now();
        final sevenDaysFromNow = now.add(const Duration(days: 7));

        for (var inst in installments) {
          final instAmount = inst.amount + inst.lateFeeApplied - inst.paidAmount;
          totalOutstanding += instAmount;

          final isOverdue = inst.dueDate.isBefore(now);
          if (isOverdue) {
            totalOverdue += instAmount;
          } else if (inst.dueDate.isBefore(sevenDaysFromNow)) {
            totalThisWeek += instAmount;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(storeReceivablesProvider(storeId));
          },
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Resumen de Tesorería Proyectada ───
                _buildSummaryDashboard(
                  totalOutstanding: totalOutstanding,
                  totalOverdue: totalOverdue,
                  totalThisWeek: totalThisWeek,
                ),
                
                const SizedBox(height: 28),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: Color(0xFF4F46E5),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Calendario de Cuentas por Cobrar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // ─── Listado Cronológico ───
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: installments.length,
                  itemBuilder: (context, index) {
                    final inst = installments[index];
                    return _buildReceivableCard(context, inst);
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                'Error al cargar tesorería: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryDashboard({
    required double totalOutstanding,
    required double totalOverdue,
    required double totalThisWeek,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 16),
              SizedBox(width: 6),
              Text(
                'TESORERÍA PROYECTADA',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total por Cobrar',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            '\$${totalOutstanding.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFF334155)),
          ),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Por Vencer (7 días)',
                  '\$${totalThisWeek.toStringAsFixed(2)}',
                  const Color(0xFF60A5FA),
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFF334155)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildMiniStat(
                    'Monto en Mora',
                    '\$${totalOverdue.toStringAsFixed(2)}',
                    const Color(0xFFF87171),
                    isHighlight: totalOverdue > 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? color : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildReceivableCard(BuildContext context, Installment installment) {
    final now = DateTime.now();
    final isOverdue = installment.dueDate.isBefore(now);
    final instAmount = installment.amount + installment.lateFeeApplied - installment.paidAmount;
    final dueDateFormatted = installment.dueDate.toSlashDateString();
    
    // Identificar datos del cliente
    final order = installment.order;
    final user = order?.user;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    String userName = '$firstName $lastName'.trim();
    if (userName.isEmpty) {
      userName = user?['name'] as String? ?? 'Cliente Desconocido';
    }

    final String statusLabel = isOverdue ? 'MORA' : 'A TIEMPO';
    final Color badgeColor = isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: badgeColor,
                width: 5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Orden: #${order?.id.substring(0, 8).toUpperCase() ?? "S/ID"}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              color: Color(0xFF94A3B8),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Vence: $dueDateFormatted',
                              style: TextStyle(
                                color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${instAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (installment.lateFeeApplied > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Mora: +\$${installment.lateFeeApplied.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
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
                  Text(
                    'Cuota de \$${installment.amount.toStringAsFixed(2)} (${(installment.paidAmount / installment.amount * 100).toStringAsFixed(0)}% cubierto)',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                  if (order != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(orderId: order.id),
                          ),
                        );
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedEye,
                        color: Color(0xFF4F46E5),
                        size: 14,
                      ),
                      label: const Text(
                        'Ver Detalle',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar03,
                color: Color(0xFF64748B),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay cuentas pendientes por cobrar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Todas las cuotas de tus clientes están pagadas o no hay órdenes parcializadas activas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
