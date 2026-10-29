import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';
import 'package:tu_lojita_business/features/chat/presentation/screens/order_chat_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  final String storeId;

  const OrderListScreen({super.key, required this.storeId});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
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

  Tab _buildTab(String label, bool showDot, {int? badgeCount}) {
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
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadDisputeOrderIds = ref.watch(unreadBusinessDisputeOrderIdsProvider);
    final allOrdersState = ref.watch(
      ordersNotifierProvider((storeId: widget.storeId, status: null, hasDispute: null)),
    );
    final disputedOrders = allOrdersState.orders
        .where((o) => unreadDisputeOrderIds.contains(o.id) || o.hasActiveDispute)
        .toList();

    final activeDisputesOrdersCount =
        ref.watch(ordersWithActiveDisputesCountProvider(widget.storeId));

    final hasDisputeAll = unreadDisputeOrderIds.isNotEmpty || activeDisputesOrdersCount > 0;
    final hasDisputePending = disputedOrders.any((o) => o.status == 'PENDING');
    final hasDisputePartiallyPaid = disputedOrders.any((o) => o.status == 'PARTIALLY_PAID');
    final hasDisputeFullyPaid = disputedOrders.any((o) => o.status == 'FULLY_PAID');
    final hasDisputeCancelled = disputedOrders.any((o) => o.status == 'CANCELLED');

    return DefaultTabController(
      length: 7,
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Gestión de Órdenes',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF4F46E5),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              _buildTab('Todas', hasDisputeAll),
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
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFilteredList((storeId: widget.storeId, status: null, hasDispute: null)),
                  _buildFilteredList((storeId: widget.storeId, status: 'PENDING', hasDispute: null)),
                  _buildFilteredList((storeId: widget.storeId, status: 'PARTIALLY_PAID', hasDispute: null)),
                  _buildFilteredList((storeId: widget.storeId, status: 'FULLY_PAID', hasDispute: null)),
                  _buildFilteredList((storeId: widget.storeId, status: 'CANCELLED', hasDispute: null)),
                  _buildFilteredList((storeId: widget.storeId, status: null, hasDispute: true)),
                  _buildAppointmentsCalendarView(allOrdersState),
                ],
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

  Widget _buildFilteredList(OrderFilter filter) {
    final ordersState = ref.watch(ordersNotifierProvider(filter));

    if (ordersState.isLoading && ordersState.orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
      );
    }

    final filteredOrders = ordersState.orders.where((order) {
      final matchesQuery = _searchQuery.isEmpty ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (order.user != null &&
              '${order.user!['firstName']} ${order.user!['lastName'] ?? ''}'
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));

      return matchesQuery;
    }).toList();

    if (filteredOrders.isEmpty) {
      final isDisputeTab = filter.hasDispute == true;

      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(ordersNotifierProvider(filter).notifier).refresh();
        },
        color: const Color(0xFF4F46E5),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isDisputeTab
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: isDisputeTab
                          ? const Icon(
                              Icons.gavel_rounded,
                              size: 36,
                              color: Color(0xFFEF4444),
                            )
                          : const HugeIcon(
                              icon: HugeIcons.strokeRoundedInvoice01,
                              size: 32,
                              color: Color(0xFF94A3B8),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No se encontraron resultados'
                        : (isDisputeTab
                            ? 'No hay reclamos abiertos'
                            : 'No hay órdenes aún'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Prueba con términos diferentes o ID de orden.'
                        : (isDisputeTab
                            ? '¡Excelente! No tienes reclamos pendientes de resolución.'
                            : 'Las órdenes en este estado aparecerán aquí.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(ordersNotifierProvider(filter).notifier).refresh();
      },
      color: const Color(0xFF4F46E5),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
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
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
              );
            }
            final order = filteredOrders[index];
            final authState = ref.watch(authProvider);
            final user = authState is Authenticated ? authState.user : null;
            final canChat = user?.canChatWithCustomer ?? true;
            final unreadDisputeOrderIds = ref.watch(unreadBusinessDisputeOrderIdsProvider);
            final hasUnreadDispute = unreadDisputeOrderIds.contains(order.id);
            final hasActiveDispute = order.hasActiveDispute || hasUnreadDispute;

            return OrderCard(
              order: order,
              hasActiveDispute: hasActiveDispute,
              hasUnreadDispute: hasUnreadDispute,
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
                                ? '${order.user!['firstName']} ${order.user!['lastName'] ?? ''}'.trim()
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

  Widget _buildAppointmentsCalendarView(OrdersState allOrdersState) {
    final bookingOrders = allOrdersState.orders.where((o) => o.hasSlotBookings).toList();

    if (allOrdersState.isLoading && bookingOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookingOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.read(ordersNotifierProvider((storeId: widget.storeId, status: null, hasDispute: null)).notifier).refresh();
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
              child: const Icon(Icons.calendar_today, size: 32, color: Color(0xFF7C3AED)),
            ),
            const Text(
              'No hay citas agendadas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
        ref.read(ordersNotifierProvider((storeId: widget.storeId, status: null, hasDispute: null)).notifier).refresh();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookingOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = bookingOrders[index];
          final customer = order.user != null ? '${order.user!['firstName'] ?? ''} ${order.user!['lastName'] ?? ''}'.trim() : 'Cliente';
          final firstItem = order.orderItems.isNotEmpty ? order.orderItems.first.title : 'Servicio';

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
                          child: const Icon(Icons.event_available, color: Color(0xFF7C3AED), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.isNotEmpty ? customer : 'Cliente',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                firstItem,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: order.status == 'FULLY_PAID' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status == 'FULLY_PAID' ? 'PAGADO' : 'PENDIENTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: order.status == 'FULLY_PAID' ? const Color(0xFF065F46) : const Color(0xFF92400E),
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

                      return Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$label ($start - $end)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6D28D9)),
                          ),
                        ],
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
