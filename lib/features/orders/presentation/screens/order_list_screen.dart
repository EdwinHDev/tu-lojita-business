import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/chat/presentation/screens/order_chat_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/orders_bento_shimmer.dart';
import 'order_details_screen.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  final String storeId;

  const OrderListScreen({super.key, required this.storeId});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  String _serverSearch = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    final currentText = _searchController.text;
    if (currentText != _searchQuery && mounted) {
      setState(() {
        _searchQuery = currentText;
      });
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      final normalized = currentText.trim();
      if (normalized != _serverSearch) {
        setState(() {
          _serverSearch = normalized;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  Tab _buildTab(
    String label,
    bool showDot, {
    int? badgeCount,
    Color dotColor = const Color(0xFFEF4444),
  }) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount != null && badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (showDot) ...[
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  OrderFilter _tabFilter({
    String? status,
    bool? hasDispute,
    bool? hasPendingPayment,
  }) {
    return buildOrderFilter(
      storeId: widget.storeId,
      status: status,
      hasDispute: hasDispute,
      hasPendingPayment: hasPendingPayment,
      search: _serverSearch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadDisputeOrderIds =
        ref.watch(unreadBusinessDisputeOrderIdsProvider);
    final allFilter = _tabFilter();
    final allOrdersState = ref.watch(ordersNotifierProvider(allFilter));
    final disputedOrders = allOrdersState.orders
        .where((o) => unreadDisputeOrderIds.contains(o.id) || o.hasActiveDispute)
        .toList();

    final activeDisputesOrdersCount =
        ref.watch(ordersWithActiveDisputesCountProvider(widget.storeId));

    final hasPendingVerification = allOrdersState.orders.any(
      (o) =>
          !o.isCancelled &&
          o.payments.any((p) => p.status.toUpperCase() == 'WAITING_VERIFICATION'),
    );
    final hasDisputeAll =
        unreadDisputeOrderIds.isNotEmpty || activeDisputesOrdersCount > 0;
    final hasDisputePending = disputedOrders.any((o) => o.status == 'PENDING');
    final hasDisputePartiallyPaid =
        disputedOrders.any((o) => o.status == 'PARTIALLY_PAID');
    final hasDisputeFullyPaid =
        disputedOrders.any((o) => o.status == 'FULLY_PAID');
    final hasDisputeCancelled =
        disputedOrders.any((o) => o.status == 'CANCELLED');

    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: TuLojitaBrandColors.canvas,
        appBar: AppBar(
          backgroundColor: TuLojitaBrandColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Color(0xFF1E293B),
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Gestión de Órdenes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: TuLojitaBrandColors.inkPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          bottom: TabBar(
            isScrollable: true,
            labelColor: TuLojitaBrandColors.indigo600,
            unselectedLabelColor: TuLojitaBrandColors.inkSecondary,
            indicatorColor: TuLojitaBrandColors.indigo600,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              _buildTab('Todas', hasDisputeAll),
              _buildTab(
                'Por verificar',
                hasPendingVerification,
                dotColor: TuLojitaBrandColors.amber500,
              ),
              _buildTab('Pendientes', hasDisputePending),
              _buildTab('Abonadas', hasDisputePartiallyPaid),
              _buildTab('Pagadas', hasDisputeFullyPaid),
              _buildTab('Canceladas', hasDisputeCancelled),
              _buildTab(
                'Reclamos',
                unreadDisputeOrderIds.isNotEmpty,
                badgeCount: activeDisputesOrdersCount,
              ),
              _buildTab('Agenda Citas', false),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildHeaderSearchAndBcvBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFilteredList(_tabFilter()),
                  _buildFilteredList(_tabFilter(hasPendingPayment: true)),
                  _buildFilteredList(_tabFilter(status: 'PENDING')),
                  _buildFilteredList(_tabFilter(status: 'PARTIALLY_PAID')),
                  _buildFilteredList(_tabFilter(status: 'FULLY_PAID')),
                  _buildFilteredList(_tabFilter(status: 'CANCELLED')),
                  _buildFilteredList(_tabFilter(hasDispute: true)),
                  _buildAppointmentsCalendarView(allOrdersState, allFilter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSearchAndBcvBar() {
    final exchangeConfig = ref.watch(exchangeRateProvider).asData?.value;
    final showBcvPill =
        exchangeConfig != null && PriceFormatter.isDualEnabled(exchangeConfig);

    return Container(
      color: TuLojitaBrandColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBcvPill) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.canvas,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TuLojitaBrandColors.borderMuted),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedDollarCircle,
                    color: TuLojitaBrandColors.indigo600,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tasa BCV: ${PriceFormatter.formatRateValue(exchangeConfig.rate, symbol: exchangeConfig.symbol)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _searchController,
            style: const TextStyle(
              fontSize: 14,
              color: TuLojitaBrandColors.inkPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar cliente, referencia o ID de orden...',
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: TuLojitaBrandColors.inkSecondary,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _serverSearch = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: TuLojitaBrandColors.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: TuLojitaBrandColors.indigo100,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(OrderFilter filter) {
    final ordersState = ref.watch(ordersNotifierProvider(filter));

    if (ordersState.isLoading && ordersState.orders.isEmpty) {
      return const OrderListBentoShimmer();
    }

    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filteredOrders = ordersState.orders.where((order) {
      if (normalizedQuery.isEmpty) return true;
      final customerFullName = order.user != null
          ? '${order.user!['firstName'] ?? ''} ${order.user!['lastName'] ?? ''}'
              .trim()
              .toLowerCase()
          : '';
      final matchesOrderId = order.id.toLowerCase().contains(normalizedQuery);
      final matchesStore =
          (order.storeName ?? '').toLowerCase().contains(normalizedQuery);
      final matchesCustomer = customerFullName.contains(normalizedQuery);
      final matchesReference = order.payments.any(
        (p) => (p.reference ?? '').toLowerCase().contains(normalizedQuery),
      );
      return matchesOrderId ||
          matchesStore ||
          matchesCustomer ||
          matchesReference;
    }).toList();

    if (filteredOrders.isEmpty) {
      final isDisputeTab = filter.hasDispute == true;
      final isVerifyTab = filter.hasPendingPayment == true;

      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(ordersNotifierProvider(filter).notifier).refresh();
        },
        color: TuLojitaBrandColors.indigo600,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isDisputeTab
                            ? TuLojitaBrandColors.dangerBg
                            : (isVerifyTab
                                ? TuLojitaBrandColors.amber50
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: isDisputeTab
                            ? const Icon(
                                Icons.gavel_rounded,
                                size: 36,
                                color: Color(0xFFEF4444),
                              )
                            : (isVerifyTab
                                ? const Icon(
                                    Icons.fact_check_rounded,
                                    size: 34,
                                    color: TuLojitaBrandColors.amber700,
                                  )
                                : const HugeIcon(
                                    icon: HugeIcons.strokeRoundedInvoice01,
                                    size: 32,
                                    color: Color(0xFF94A3B8),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      normalizedQuery.isNotEmpty
                          ? 'No se encontraron resultados'
                          : (isDisputeTab
                              ? 'No hay reclamos abiertos'
                              : (isVerifyTab
                                  ? 'Sin comprobantes por verificar'
                                  : 'No hay órdenes aún')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      normalizedQuery.isNotEmpty
                          ? 'Prueba con nombre del cliente, referencia bancaria o ID de orden.'
                          : (isDisputeTab
                              ? '¡Excelente! No tienes reclamos pendientes de resolución.'
                              : (isVerifyTab
                                  ? 'Todos los pagos enviados ya fueron revisados.'
                                  : 'Las órdenes en este estado aparecerán aquí.')),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: TuLojitaBrandColors.inkSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canChat = user?.canChatWithCustomer ?? true;
    final canViewCustomerData = user?.canViewSensitiveCustomerData ?? true;
    final unreadDisputeOrderIds =
        ref.watch(unreadBusinessDisputeOrderIdsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ordersNotifierProvider(filter).notifier).refresh();
      },
      color: TuLojitaBrandColors.indigo600,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent - 200) {
            ref.read(ordersNotifierProvider(filter).notifier).fetchNextPage();
          }
          return true;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length + (ordersState.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredOrders.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 150,
                  child: OrderListBentoShimmer(itemCount: 1),
                ),
              );
            }
            final order = filteredOrders[index];
            final hasUnreadDispute = unreadDisputeOrderIds.contains(order.id);
            final hasActiveDispute = order.hasActiveDispute || hasUnreadDispute;

            return OrderCard(
              order: order,
              hasActiveDispute: hasActiveDispute,
              hasUnreadDispute: hasUnreadDispute,
              canViewCustomerData: canViewCustomerData,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(
                      order: order,
                      storeId: widget.storeId,
                      autoOpenDispute: hasUnreadDispute,
                    ),
                  ),
                );
                if (result == true || mounted) {
                  ref.read(ordersNotifierProvider(filter).notifier).refresh();
                }
              },
              onChatTap: canChat &&
                      order.status != 'FULLY_PAID' &&
                      (order.status != 'CANCELLED' ||
                          order.payments.any((p) =>
                              p.status == 'WAITING_VERIFICATION' ||
                              p.status == 'REFUND_PENDING' ||
                              p.status == 'PENDING'))
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderChatScreen(
                            orderId: order.id,
                            userName: order.user?['firstName'] != null
                                ? '${order.user!['firstName']} ${order.user!['lastName'] ?? ''}'
                                    .trim()
                                : 'Cliente',
                          ),
                        ),
                      );
                    }
                  : null,
              onDisputeTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(
                      order: order,
                      storeId: widget.storeId,
                      autoOpenDispute: true,
                    ),
                  ),
                );
                if (result == true || mounted) {
                  ref.read(ordersNotifierProvider(filter).notifier).refresh();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentsCalendarView(
    OrdersState allOrdersState,
    OrderFilter allFilter,
  ) {
    final bookingOrders =
        allOrdersState.orders.where((o) => o.hasSlotBookings).toList();

    if (allOrdersState.isLoading && bookingOrders.isEmpty) {
      return const OrderListBentoShimmer();
    }

    if (bookingOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(ordersNotifierProvider(allFilter).notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 48),
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 32,
                color: Color(0xFF7C3AED),
              ),
            ),
            const Text(
              'No hay citas agendadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuando los clientes reserven turnos para tus servicios, aparecerán organizados cronológicamente aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ordersNotifierProvider(allFilter).notifier).refresh();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookingOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = bookingOrders[index];
          final customer = order.user != null
              ? '${order.user!['firstName'] ?? ''} ${order.user!['lastName'] ?? ''}'
                  .trim()
              : 'Cliente';
          final firstItem = order.orderItems.isNotEmpty
              ? order.orderItems.first.title
              : 'Servicio';

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.event_available,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.isNotEmpty ? customer : 'Cliente',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                firstItem,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TuLojitaBrandColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.status == 'FULLY_PAID'
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status == 'FULLY_PAID'
                                ? 'PAGADO'
                                : 'PENDIENTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: order.status == 'FULLY_PAID'
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    ...order.slotBookings.map((sb) {
                      final slot = sb['slot'] is Map ? sb['slot'] : {};
                      final date = sb['bookingDate']?.toString() ?? '-';
                      final start = slot['startTime']?.toString() ?? '';
                      final end = slot['endTime']?.toString() ?? '';
                      final label = slot['label']?.toString() ?? 'Turno';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 16, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$date · $label ($start - $end)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5B21B6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
