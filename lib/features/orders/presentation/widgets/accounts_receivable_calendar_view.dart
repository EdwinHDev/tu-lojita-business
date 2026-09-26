import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../providers/orders_provider.dart';
import '../../domain/entities/order.dart';
import '../screens/order_details_screen.dart';

class AccountsReceivableCalendarView extends ConsumerWidget {
  final String storeId;

  const AccountsReceivableCalendarView({super.key, required this.storeId});

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isOverdue(Installment inst, DateTime now) {
    if (inst.status == 'PAID') return false;
    if (inst.status == 'OVERDUE') return true;
    final hasWaitingPayment = inst.order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = inst.order?.installments.isNotEmpty == true && inst.order!.installments.first.id == inst.id;
    final isInReview = hasWaitingPayment || (inst.order?.status == 'PENDING' && isFirstInstallment);
    if (isInReview || isFirstInstallment) return false;
    return inst.dueDate != null && inst.dueDate!.isBefore(now);
  }

  bool _isScheduledOrActive(Installment inst) {
    if (inst.status == 'PAID') return true;
    if (inst.dueDate != null) return true;
    final hasWaitingPayment = inst.order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = inst.order?.installments.isNotEmpty == true && inst.order!.installments.first.id == inst.id;
    return hasWaitingPayment || (inst.order?.status == 'PENDING' && isFirstInstallment);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivablesAsync = ref.watch(storeReceivablesProvider(storeId));

    return receivablesAsync.when(
      data: (installments) {
        if (installments.isEmpty) {
          return _buildEmptyState();
        }

        final now = DateTime.now();
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
        final sevenDaysFromNow = endOfToday.add(const Duration(days: 7));
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

        // Buckets
        final List<Installment> overdueList = [];
        final List<Installment> dueTodayList = [];
        final List<Installment> dueThisWeekList = [];
        final List<Installment> dueThisMonthList = [];
        final List<Installment> futureList = [];

        double totalOutstanding = 0.0;
        double totalOverdue = 0.0;
        double totalThisWeek = 0.0;

        for (final inst in installments) {
          if (inst.status == 'PAID') continue;
          if (!_isScheduledOrActive(inst)) continue;

          final instAmount = inst.amount + inst.lateFeeApplied - inst.paidAmount;
          totalOutstanding += instAmount;

          final bool isOverdue = _isOverdue(inst, now);

          if (isOverdue) {
            overdueList.add(inst);
            totalOverdue += instAmount;
          } else if (inst.dueDate != null && _isSameDay(inst.dueDate!, now)) {
            dueTodayList.add(inst);
            totalThisWeek += instAmount;
          } else if (inst.dueDate != null && inst.dueDate!.isAfter(endOfToday) && inst.dueDate!.isBefore(sevenDaysFromNow)) {
            dueThisWeekList.add(inst);
            totalThisWeek += instAmount;
          } else if (inst.dueDate != null && inst.dueDate!.isAfter(sevenDaysFromNow) && inst.dueDate!.isBefore(endOfMonth)) {
            dueThisMonthList.add(inst);
          } else {
            futureList.add(inst);
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(storeReceivablesProvider(storeId));
            ref.invalidate(storeInstallmentsProvider(storeId));
          },
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Executive Dashboard ──
                _buildSummaryDashboard(
                  totalOutstanding: totalOutstanding,
                  totalOverdue: totalOverdue,
                  totalThisWeek: totalThisWeek,
                ),

                const SizedBox(height: 24),

                // Section header
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
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Flujo Proyectado de Cobranza',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cuentas por cobrar agrupadas por horizonte temporal de vencimiento.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 16),

                // 1. Overdue Section
                if (overdueList.isNotEmpty)
                  _buildTimelineSection(
                    context: context,
                    title: 'Vencidas / En Mora',
                    subtitle: 'Cobranza inmediata requerida',
                    installments: overdueList,
                    badgeColor: const Color(0xFFEF4444),
                    badgeBgColor: const Color(0xFFFEF2F2),
                    icon: Icons.warning_amber_rounded,
                  ),

                // 2. Due Today
                if (dueTodayList.isNotEmpty)
                  _buildTimelineSection(
                    context: context,
                    title: 'Vencen Hoy',
                    subtitle: 'Cobros programados para el día',
                    installments: dueTodayList,
                    badgeColor: const Color(0xFFD97706),
                    badgeBgColor: const Color(0xFFFFFBEB),
                    icon: Icons.today_rounded,
                  ),

                // 3. Due This Week
                if (dueThisWeekList.isNotEmpty)
                  _buildTimelineSection(
                    context: context,
                    title: 'Esta Semana (Próximos 7 días)',
                    subtitle: 'Ingresos proyectados a corto plazo',
                    installments: dueThisWeekList,
                    badgeColor: const Color(0xFF4F46E5),
                    badgeBgColor: const Color(0xFFEEF2FF),
                    icon: Icons.date_range_rounded,
                  ),

                // 4. Due This Month
                if (dueThisMonthList.isNotEmpty)
                  _buildTimelineSection(
                    context: context,
                    title: 'Resto de este Mes',
                    subtitle: 'Cuotas con vencimiento este mes',
                    installments: dueThisMonthList,
                    badgeColor: const Color(0xFF059669),
                    badgeBgColor: const Color(0xFFECFDF5),
                    icon: Icons.calendar_month_rounded,
                  ),

                // 5. Future Months
                if (futureList.isNotEmpty)
                  _buildTimelineSection(
                    context: context,
                    title: 'Próximos Meses / Futuras',
                    subtitle: 'Cartera a mediano y largo plazo',
                    installments: futureList,
                    badgeColor: const Color(0xFF64748B),
                    badgeBgColor: const Color(0xFFF1F5F9),
                    icon: Icons.schedule_rounded,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  const Text(
                    'TOTAL SALDO POR COBRAR',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${totalOutstanding.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCoins01,
                  color: Color(0xFF818CF8),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: const Color(0xFF334155),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Próximos 7 días',
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

  Widget _buildTimelineSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Installment> installments,
    required Color badgeColor,
    required Color badgeBgColor,
    required IconData icon,
  }) {
    final double subtotal = installments.fold(
      0.0,
      (sum, inst) => sum + (inst.amount + inst.lateFeeApplied - inst.paidAmount),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: badgeColor, size: 16),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: badgeColor.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '\$${subtotal.toStringAsFixed(2)} (${installments.length})',
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Cards in bucket
          ...installments.map((inst) => _buildReceivableCard(context, inst)),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(BuildContext context, Installment installment) {
    final now = DateTime.now();
    final order = installment.order;
    final hasWaitingPayment = order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = order?.installments.isNotEmpty == true && order!.installments.first.id == installment.id;
    final isInReview = hasWaitingPayment || (order?.status == 'PENDING' && isFirstInstallment);
    final isOverdue = _isOverdue(installment, now);
    final instAmount = installment.amount + installment.lateFeeApplied - installment.paidAmount;
    final dueDateFormatted = isInReview
        ? (isFirstInstallment ? 'Pago inicial en verificación' : 'Comprobante en verificación')
        : (installment.dueDate != null ? installment.dueDate!.toSlashDateString() : 'Por programar');

    final user = order?.user;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final phone = user?['phone'] as String? ?? '';
    String userName = '$firstName $lastName'.trim();
    if (userName.isEmpty) {
      userName = user?['name'] as String? ?? 'Cliente Desconocido';
    }

    final String statusLabel = isInReview
        ? 'EN REVISIÓN'
        : (installment.dueDate == null
            ? 'POR PROGRAMAR'
            : (isOverdue ? 'MORA' : 'AL DÍA'));
    final Color badgeColor = isInReview
        ? const Color(0xFFD97706)
        : (installment.dueDate == null
            ? const Color(0xFF64748B)
            : (isOverdue ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)));

    // Installment number text
    String installmentText = 'Cuota';
    if (order?.installments.isNotEmpty == true) {
      final idx = order!.installments.indexWhere((i) => i.id == installment.id);
      if (idx != -1) {
        installmentText = (idx == 0 && order.isPartialPayment)
            ? 'Pago Inicial (1/${order.installments.length})'
            : 'Cuota ${idx + 1} de ${order.installments.length}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          padding: const EdgeInsets.all(14),
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
                            Flexible(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Orden: #${order?.id.substring(0, 8).toUpperCase() ?? "S/ID"}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• $installmentText',
                              style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (phone.isNotEmpty)
                        InkWell(
                          onTap: () {
                            String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                            if (cleanPhone.startsWith('0')) {
                              cleanPhone = '58${cleanPhone.substring(1)}';
                            } else if (!cleanPhone.startsWith('58') && cleanPhone.length == 10) {
                              cleanPhone = '58$cleanPhone';
                            }
                            final displayOrderId = order != null && order.id.length >= 8
                                ? order.id.substring(0, 8).toUpperCase()
                                : order?.id.toUpperCase() ?? '';
                            final msg = isOverdue
                                ? 'Hola $userName, le saludamos de nuestra tienda. Le recordamos cordialmente sobre la $installmentText del pedido #$displayOrderId vencida por \$${instAmount.toStringAsFixed(2)}. ¿Nos confirma si realizó el pago? ¡Gracias!'
                                : 'Hola $userName, le saludamos de nuestra tienda sobre la $installmentText del pedido #$displayOrderId con vencimiento el $dueDateFormatted por \$${instAmount.toStringAsFixed(2)}. ¡Gracias!';
                            final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 12),
                                SizedBox(width: 4),
                                Text('WhatsApp', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (order != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(order: order, storeId: storeId),
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
                color: Color(0xFF94A3B8),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay cobros pendientes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Todas las cuotas de tus clientes están al día o totalmente saldadas.',
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
