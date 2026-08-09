import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

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

  @override
  Widget build(BuildContext context) {

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
              Tab(text: 'Abonadas'),
              Tab(text: 'Pagadas'),
              Tab(text: 'Canceladas'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildFilteredList((storeId: widget.storeId, status: null)),
                  _buildFilteredList((storeId: widget.storeId, status: 'PENDING')),
                  _buildFilteredList((storeId: widget.storeId, status: 'PARTIALLY_PAID')),
                  _buildFilteredList((storeId: widget.storeId, status: 'FULLY_PAID')),
                  _buildFilteredList((storeId: widget.storeId, status: 'CANCELLED')),
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedInvoice01,
                      size: 32,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isNotEmpty ? 'No se encontraron resultados' : 'No hay órdenes aún',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Prueba con términos diferentes o ID de orden.'
                        : 'Las órdenes en este estado aparecerán aquí.',
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
            return OrderCard(
              order: order,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(
                      order: order,
                      storeId: widget.storeId,
                    ),
                  ),
                );
                if ((result == true || mounted)) {
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
