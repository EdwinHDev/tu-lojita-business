import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';
import 'package:tu_lojita_business/features/chat/presentation/screens/order_chat_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

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
      length: 6,
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
              onChatTap: order.status != 'CANCELLED' && order.status != 'FULLY_PAID'
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
}
