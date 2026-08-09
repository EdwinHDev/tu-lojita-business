import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/repositories/order_repository_impl.dart';

final ordersRepositoryProvider = Provider<OrderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRepositoryImpl(dio: dio);
});

// ------------------------------------------------------------------
// State class
// ------------------------------------------------------------------
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef OrderFilter = ({String storeId, String? status});

// ------------------------------------------------------------------
// Notifier — receives filter via constructor (Riverpod v3 pattern)
// ------------------------------------------------------------------
class OrdersNotifier extends Notifier<OrdersState> {
  final OrderFilter filter;
  int _currentOffset = 0;
  final int _limit = 20;

  OrdersNotifier(this.filter);

  @override
  OrdersState build() {
    _currentOffset = 0;
    Future.microtask(_fetchInitial);
    return const OrdersState(isLoading: true);
  }

  Future<void> _fetchInitial() async {
    if (!ref.mounted) return;
    state = const OrdersState(isLoading: true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final items = await repo.getOrdersPaginated(filter.storeId, _limit, 0, status: filter.status);
      
      if (!ref.mounted) return;

      _currentOffset = items.length;
      state = OrdersState(
        orders: items,
        isLoading: false,
        hasMore: items.length == _limit,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = OrdersState(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    _currentOffset = 0;
    await _fetchInitial();
  }

  Future<void> fetchNextPage() async {
    if (!ref.mounted || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final nextItems = await repo.getOrdersPaginated(filter.storeId, _limit, _currentOffset, status: filter.status);
      
      if (!ref.mounted) return;

      _currentOffset += nextItems.length;
      state = state.copyWith(
        orders: [...state.orders, ...nextItems],
        isLoading: false,
        hasMore: nextItems.length == _limit,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Order?> updateOrderStatus(String orderId, String newStatus, {String? reason}) async {
    if (!ref.mounted) return null;
    try {
      final repo = ref.read(ordersRepositoryProvider);
      final updatedOrder = await repo.updateOrderStatus(orderId, newStatus, reason: reason);
      
      if (!ref.mounted) return updatedOrder;

      final index = state.orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final newList = [...state.orders];
        newList[index] = updatedOrder;
        state = state.copyWith(orders: newList);
      }
      return updatedOrder;
    } catch (_) {
      if (!ref.mounted) return null;
      return null;
    }
  }
}

// ------------------------------------------------------------------
// Provider — factory receives the filter arg (Riverpod v3 syntax)
// ------------------------------------------------------------------
final ordersNotifierProvider = NotifierProvider.autoDispose
    .family<OrdersNotifier, OrdersState, OrderFilter>(
  (filter) => OrdersNotifier(filter),
);

final orderByIdProvider = FutureProvider.family<Order, String>((ref, orderId) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.getOrderById(orderId);
});

final storeInstallmentsProvider = FutureProvider.family<List<Installment>, String>((ref, storeId) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.getStoreInstallments(storeId);
});

final verifyExtensionProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final repo = ref.read(ordersRepositoryProvider);
  final installmentId = params['installmentId'] as String;
  final status = params['status'] as String;
  final merchantComment = params['merchantComment'] as String?;
  final storeId = params['storeId'] as String;
  
  await repo.verifyExtension(installmentId, status, merchantComment: merchantComment);
  ref.invalidate(storeInstallmentsProvider(storeId));
});

final verifyPaymentProvider = FutureProvider.family<Order, Map<String, dynamic>>((ref, params) async {
  final repo = ref.read(ordersRepositoryProvider);
  final paymentId = params['paymentId'] as String;
  final status = params['status'] as String;
  final orderId = params['orderId'] as String;
  
  final updatedOrder = await repo.verifyPayment(paymentId, status, orderId);
  ref.invalidate(orderByIdProvider(orderId));
  return updatedOrder;
});

final storeReceivablesProvider = FutureProvider.family<List<Installment>, String>((ref, storeId) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.getStoreReceivables(storeId);
});

final orderStatementProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, orderId) async {
  final repo = ref.read(ordersRepositoryProvider);
  return repo.getOrderStatement(orderId);
});

