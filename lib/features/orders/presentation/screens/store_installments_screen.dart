import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import '../../domain/entities/order.dart';
import '../providers/orders_provider.dart';
import 'order_details_screen.dart';
import '../widgets/accounts_receivable_calendar_view.dart';
import '../widgets/receipt_image_viewer.dart';

class StoreInstallmentsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreInstallmentsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreInstallmentsScreen> createState() => _StoreInstallmentsScreenState();
}

class _StoreInstallmentsScreenState extends ConsumerState<StoreInstallmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription? _installmentsSub;
  StreamSubscription? _notificationsSub;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = ref.read(socketServiceProvider);
      socket.joinStore(widget.storeId);
    });

    final socket = ref.read(socketServiceProvider);
    _installmentsSub = socket.storeInstallmentsStream.listen((data) {
      if (mounted) {
        ref.invalidate(storeInstallmentsProvider(widget.storeId));
        ref.invalidate(storeReceivablesProvider(widget.storeId));
      }
    });

    _notificationsSub = socket.notificationsStream.listen((data) {
      if (mounted) {
        ref.invalidate(storeInstallmentsProvider(widget.storeId));
        ref.invalidate(storeReceivablesProvider(widget.storeId));
      }
    });
  }

  @override
  void dispose() {
    _installmentsSub?.cancel();
    _notificationsSub?.cancel();
    ref.read(socketServiceProvider).leaveStore(widget.storeId);
    _searchController.dispose();
    super.dispose();
  }

  bool _isScheduledOrActiveInstallment(Installment inst) {
    if (inst.status == 'PAID') return true;
    if (inst.dueDate != null) return true;
    final hasWaitingPayment = inst.order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = inst.order?.installments.isNotEmpty == true && inst.order!.installments.first.id == inst.id;
    final isInReview = hasWaitingPayment || (inst.order?.status == 'PENDING' && isFirstInstallment);
    return isInReview || isFirstInstallment;
  }

  bool _isOverdueInstallment(Installment inst) {
    if (inst.status == 'PAID') return false;
    if (inst.status == 'OVERDUE') return true;
    final hasWaitingPayment = inst.order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = inst.order?.installments.isNotEmpty == true && inst.order!.installments.first.id == inst.id;
    final isInReview = hasWaitingPayment || (inst.order?.status == 'PENDING' && isFirstInstallment);
    if (isInReview || isFirstInstallment) return false;
    return inst.dueDate != null && inst.dueDate!.isBefore(DateTime.now());
  }

  bool _isInReviewInstallment(Installment inst) {
    final hasWaitingPayment = inst.order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = inst.order?.installments.isNotEmpty == true && inst.order!.installments.first.id == inst.id;
    return hasWaitingPayment || (inst.order?.status == 'PENDING' && isFirstInstallment);
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final installmentsAsync = ref.watch(storeInstallmentsProvider(widget.storeId));

    return installmentsAsync.when(
      data: (rawInstallments) {
        final installments = rawInstallments.where(_isScheduledOrActiveInstallment).toList();
        final allCount = installments.length;
        final pendingCount = installments.where((i) => i.status == 'PENDING' && !_isOverdueInstallment(i)).length;
        final overdueCount = installments.where((i) => _isOverdueInstallment(i)).length;
        final paidCount = installments.where((i) => i.status == 'PAID').length;

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
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF4F46E5),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  Tab(text: 'Todas ($allCount)'),
                  Tab(text: 'Pendientes ($pendingCount)'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Vencidas ($overdueCount)'),
                        if (overdueCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(text: 'Pagadas ($paidCount)'),
                  const Tab(text: 'Flujo Proyectado'),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildExecutiveKpiBar(installments),
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFilteredList(installments, null),
                      _buildFilteredList(installments, 'PENDING'),
                      _buildFilteredList(installments, 'OVERDUE'),
                      _buildFilteredList(installments, 'PAID'),
                      AccountsReceivableCalendarView(storeId: widget.storeId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Cuotas y Deudas', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Cuotas y Deudas', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error al cargar datos: $err', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(storeInstallmentsProvider(widget.storeId)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveKpiBar(List<Installment> installments) {
    double totalReceivables = 0.0;
    double totalOverdue = 0.0;
    int overdueCount = 0;
    int reviewPaymentsCount = 0;
    final Set<String> debtorUserIds = {};

    for (final inst in installments) {
      final double rem = inst.amount + inst.lateFeeApplied - inst.paidAmount;
      if (inst.status != 'PAID') {
        totalReceivables += rem;
        final userId = inst.order?.user?['id'] as String? ?? inst.order?.id ?? '';
        if (userId.isNotEmpty) {
          debtorUserIds.add(userId);
        }
      }

      if (_isOverdueInstallment(inst)) {
        totalOverdue += rem;
        overdueCount++;
      }

      if (inst.order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false) {
        reviewPaymentsCount++;
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildKpiCard(
              title: 'Por Cobrar',
              value: '\$${totalReceivables.toStringAsFixed(2)}',
              subtitle: 'Cartera activa',
              icon: HugeIcons.strokeRoundedCoins01,
              iconColor: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'En Mora',
              value: '\$${totalOverdue.toStringAsFixed(2)}',
              subtitle: '$overdueCount cuota(s)',
              icon: HugeIcons.strokeRoundedAlert02,
              iconColor: const Color(0xFFEF4444),
              bgColor: const Color(0xFFFEF2F2),
              isAlert: overdueCount > 0,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'En Revisión',
              value: '$reviewPaymentsCount',
              subtitle: 'Pagos por validar',
              icon: HugeIcons.strokeRoundedClock01,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              isAlert: reviewPaymentsCount > 0,
            ),
            const SizedBox(width: 10),
            _buildKpiCard(
              title: 'Deudores',
              value: '${debtorUserIds.length}',
              subtitle: 'Clientes con saldo',
              icon: HugeIcons.strokeRoundedUserGroup,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required List<List<dynamic>> icon,
    required Color iconColor,
    required Color bgColor,
    bool isAlert = false,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert ? iconColor.withValues(alpha: 0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
              HugeIcon(icon: icon, color: iconColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Buscar por cliente, teléfono o # orden...',
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
      final isOverdue = _isOverdueInstallment(inst);

      // Filter by status
      bool matchesStatus = true;
      if (filter == 'PENDING') {
        matchesStatus = inst.status == 'PENDING' && !isOverdue;
      } else if (filter == 'OVERDUE') {
        matchesStatus = isOverdue;
      } else if (filter == 'PAID') {
        matchesStatus = inst.status == 'PAID';
      }

      // Filter by search query
      final order = inst.order;
      final user = order?.user;
      final firstName = user?['firstName'] as String? ?? '';
      final lastName = user?['lastName'] as String? ?? '';
      final phone = user?['phone'] as String? ?? '';
      String userName = '$firstName $lastName'.trim();
      if (userName.isEmpty) {
        userName = user?['name'] as String? ?? 'Cliente Desconocido';
      }
      final orderId = order?.id ?? '';

      final query = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          userName.toLowerCase().contains(query) ||
          phone.toLowerCase().contains(query) ||
          orderId.toLowerCase().contains(query);

      return matchesStatus && matchesQuery;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(hasQueryOrFilter: _searchQuery.isNotEmpty || filter != null);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(storeInstallmentsProvider(widget.storeId));
        ref.invalidate(storeReceivablesProvider(widget.storeId));
      },
      color: const Color(0xFF4F46E5),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final installment = filtered[index];
          return _buildInstallmentCard(context, installment);
        },
      ),
    );
  }

  Widget _buildInstallmentCard(BuildContext context, Installment installment) {
    final order = installment.order;
    final user = order?.user;
    final firstName = user?['firstName'] as String? ?? '';
    final lastName = user?['lastName'] as String? ?? '';
    final phone = user?['phone'] as String? ?? '';
    String userName = '$firstName $lastName'.trim();
    if (userName.isEmpty) {
      userName = user?['name'] as String? ?? 'Cliente Desconocido';
    }

    final hasWaitingPayment = order?.payments.any((p) => p.status == 'WAITING_VERIFICATION') ?? false;
    final isFirstInstallment = order?.installments.isNotEmpty == true && order!.installments.first.id == installment.id;
    final isInReview = _isInReviewInstallment(installment);
    final isOverdue = _isOverdueInstallment(installment);
    final (statusBgColor, statusTextColor, statusText) = _statusBadgeStyle(installment.status, isOverdue, isInReview);

    final displayOrderId = order != null && order.id.length > 6
        ? order.id.substring(order.id.length - 6).toUpperCase()
        : order?.id.toUpperCase() ?? '';

    // Contextual installment number
    String installmentNumberText = 'Cuota';
    if (order?.installments.isNotEmpty == true) {
      final index = order!.installments.indexWhere((i) => i.id == installment.id);
      if (index != -1) {
        if (index == 0 && order.isPartialPayment) {
          installmentNumberText = 'Pago Inicial (1/${order.installments.length})';
        } else {
          installmentNumberText = 'Cuota ${index + 1} de ${order.installments.length}';
        }
      }
    }

    final double remainingAmount = installment.amount + installment.lateFeeApplied - installment.paidAmount;

    String dateText;
    Color dateColor;
    if (isInReview) {
      dateText = isFirstInstallment ? 'Pago inicial en verificación' : 'Comprobante en verificación';
      dateColor = const Color(0xFFD97706);
    } else if (installment.status == 'PAID') {
      dateText = installment.paymentDate != null
          ? 'Pagada el ${installment.paymentDate!.toSlashDateString()}'
          : 'Pagada';
      dateColor = const Color(0xFF047857);
    } else if (isOverdue) {
      dateText = installment.dueDate != null
          ? 'Venció el ${installment.dueDate!.toSlashDateString()}'
          : 'Vencida';
      dateColor = const Color(0xFFB91C1C);
    } else if (installment.dueDate == null) {
      dateText = 'Por programar';
      dateColor = const Color(0xFF64748B);
    } else {
      dateText = installment.dueDate!.toSlashDateString();
      dateColor = const Color(0xFF475569);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFCA5A5) : (isInReview ? const Color(0xFFFDE68A) : const Color(0xFFF1F5F9)),
          width: isOverdue || isInReview ? 1.5 : 1.0,
        ),
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
          // Header: Client, Phone & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• $phone',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Pedido #$displayOrderId',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            installmentNumberText,
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

          // Due Date & Pending Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha / Estado',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar03,
                        color: dateColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: TextStyle(
                          color: dateColor,
                          fontWeight: (isOverdue || isInReview) ? FontWeight.bold : FontWeight.w600,
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
                    installment.status == 'PAID' ? 'Monto Pagado' : 'Saldo Pendiente',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${remainingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Late fee indicator
          if (installment.lateFeeApplied > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Incluye recargo de mora: +\$${installment.lateFeeApplied.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          // Abono progress bar
          if (installment.paidAmount > 0 && installment.status != 'PAID') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (installment.paidAmount / (installment.amount + installment.lateFeeApplied)).clamp(0.0, 1.0),
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

          // ── Historial de pagos asentados en caja / comercio ──
          if (order?.payments.isNotEmpty == true) ...[
            Builder(
              builder: (context) {
                final approvedPayments = order!.payments.where((p) => p.status == 'APPROVED').toList();
                if (approvedPayments.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 13, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text(
                            'Historial de pagos asentados (${approvedPayments.length}):',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...approvedPayments.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${p.paymentMethod} (Ref: ${p.reference ?? 'S/R'})',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '+\$${p.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),
          ],

          // ── Action Buttons ──
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 1. WhatsApp Button (if has phone)
              if (phone.isNotEmpty && installment.dueDate != null)
                OutlinedButton.icon(
                  onPressed: () => _sendWhatsAppReminder(
                    context,
                    installment,
                    userName,
                    displayOrderId,
                    installmentNumberText,
                    dateText,
                    remainingAmount,
                    isOverdue,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF25D366)),
                  label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    backgroundColor: const Color(0xFFF0FDF4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

              // 2. Direct In-Store Manual Payment
              if (installment.status != 'PAID' && _isScheduledOrActiveInstallment(installment))
                ElevatedButton.icon(
                  onPressed: () => _showManualPaymentDialog(context, installment, remainingAmount, userName, displayOrderId),
                  icon: const Icon(Icons.point_of_sale_rounded, size: 14, color: Colors.white),
                  label: const Text('Cobrar en Tienda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

              // 3. Direct Voucher Verification
              if (hasWaitingPayment)
                OutlinedButton.icon(
                  onPressed: () {
                    final waitingPayment = order?.payments.firstWhere(
                      (p) => p.status == 'WAITING_VERIFICATION',
                    );
                    if (waitingPayment != null) {
                      _showPaymentVerificationDialog(context, order!, waitingPayment);
                    }
                  },
                  icon: const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFD97706)),
                  label: const Text('Validar Pago', style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    backgroundColor: const Color(0xFFFFFBEB),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),

              // 4. Order Details Screen
              if (order != null)
                OutlinedButton.icon(
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
                  icon: const Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF64748B)),
                  label: const Text('Ver Orden', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _statusBadgeStyle(String status, bool isOverdue, bool isInReview) {
    if (isInReview) {
      return (
        const Color(0xFFFFFBEB),
        const Color(0xFFD97706),
        'EN REVISIÓN',
      );
    }
    if (isOverdue) {
      return (
        const Color(0xFFFEF2F2),
        const Color(0xFFB91C1C),
        'VENCIDA',
      );
    }
    switch (status) {
      case 'PAID':
        return (
          const Color(0xFFECFDF5),
          const Color(0xFF047857),
          'PAGADA',
        );
      case 'PENDING':
        return (
          const Color(0xFFEFF6FF),
          const Color(0xFF2563EB),
          'AL DÍA',
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
              hasQueryOrFilter ? 'No se encontraron cuotas' : 'No hay cuotas registradas',
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              hasQueryOrFilter
                  ? 'Prueba buscando con otros términos o seleccionando otra pestaña.'
                  : 'Todas las compras en cuotas o con saldos pendientes aparecerán aquí.',
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

  Future<void> _sendWhatsAppReminder(
    BuildContext context,
    Installment installment,
    String userName,
    String displayOrderId,
    String installmentNumberText,
    String dateText,
    double remainingAmount,
    bool isOverdue,
  ) async {
    final phone = installment.order?.user?['phone'] as String?;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cliente no tiene un número registrado.')),
      );
      return;
    }

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '58${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('58') && cleanPhone.length == 10) {
      cleanPhone = '58$cleanPhone';
    }

    final message = isOverdue
        ? 'Hola $userName, le saludamos cordialmente de nuestra tienda. Le recordamos amablemente sobre la $installmentNumberText del pedido #$displayOrderId, la cual venció el $dateText por un saldo de \$${remainingAmount.toStringAsFixed(2)}. ¿Nos podría confirmar si ya pudo realizar su pago? Quedamos a su entera disposición. ¡Muchas gracias!'
        : 'Hola $userName, le saludamos cordialmente de nuestra tienda. Le recordamos con respecto a la $installmentNumberText del pedido #$displayOrderId con fecha de vencimiento el $dateText por un monto de \$${remainingAmount.toStringAsFixed(2)}. Si ya efectuó su pago, por favor compártanos el comprobante por este medio. ¡Muchas gracias!';

    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp en este dispositivo.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir WhatsApp: $e')),
        );
      }
    }
  }

  void _showManualPaymentDialog(
    BuildContext context,
    Installment installment,
    double remainingAmount,
    String userName,
    String displayOrderId,
  ) {
    final order = installment.order;
    if (order == null) return;

    final amountController = TextEditingController(text: remainingAmount.toStringAsFixed(2));
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedMethod = 'EFECTIVO';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registrar Cobro en Tienda',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliente: $userName • Pedido #$displayOrderId',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Amount field
                  const Text('Monto Recibido (\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money_rounded, size: 20, color: Color(0xFF10B981)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Method dropdown
                  const Text('Método de Cobro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedMethod,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo en Caja')),
                          DropdownMenuItem(value: 'PUNTO_DE_VENTA', child: Text('Punto de Venta (Tarjeta)')),
                          DropdownMenuItem(value: 'PAGO_MOVIL', child: Text('Pago Móvil / Transferencia en Tienda')),
                          DropdownMenuItem(value: 'DIVISA', child: Text('Dólares Efectivo')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedMethod = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reference field
                  const Text('Referencia / N° Recibo (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      hintText: 'Ej. POS-04812 o Recibo #12',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final double? parsedAmount = double.tryParse(amountController.text.trim());
                              if (parsedAmount == null || parsedAmount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ingresa un monto válido mayor a 0.')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                await ref.read(registerManualPaymentProvider({
                                  'orderId': order.id,
                                  'amount': parsedAmount,
                                  'paymentMethod': selectedMethod,
                                  'reference': referenceController.text.trim(),
                                  'notes': notesController.text.trim(),
                                  'storeId': widget.storeId,
                                }).future);

                                if (context.mounted) {
                                  Navigator.pop(modalContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('¡Pago de \$${parsedAmount.toStringAsFixed(2)} acreditado exitosamente!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al registrar pago: $e')),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmar y Acreditar Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentVerificationDialog(BuildContext context, Order order, Payment payment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Validar Comprobante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monto reportado: \$${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Método: ${payment.paymentMethod}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              if (payment.reference != null && payment.reference!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Referencia: ${payment.reference}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
              Builder(
                builder: (context) {
                  final rawPath = payment.receiptImage;
                  if (rawPath == null || rawPath.isEmpty) return const SizedBox.shrink();
                  final resolvedUrl = _resolveImageUrl(rawPath);
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReceiptImageViewer(imageUrl: resolvedUrl),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              resolvedUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 120,
                                color: const Color(0xFFF1F5F9),
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 4),
                                    Text('No se pudo cargar la imagen', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Ver en grande',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
            ),
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(verifyPaymentProvider({
                    'paymentId': payment.id,
                    'status': 'REJECTED',
                    'orderId': order.id,
                    'rejectionReason': 'Comprobante no válido o ilegible',
                  }).future);
                  ref.invalidate(storeInstallmentsProvider(widget.storeId));
                  ref.invalidate(storeReceivablesProvider(widget.storeId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pago rechazado.'), backgroundColor: Color(0xFFDC2626)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
              ),
              child: const Text('Rechazar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(verifyPaymentProvider({
                    'paymentId': payment.id,
                    'status': 'APPROVED',
                    'orderId': order.id,
                  }).future);
                  ref.invalidate(storeInstallmentsProvider(widget.storeId));
                  ref.invalidate(storeReceivablesProvider(widget.storeId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Pago verificado y aprobado!'), backgroundColor: Color(0xFF10B981)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Aprobar Pago'),
            ),
          ],
        );
      },
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
