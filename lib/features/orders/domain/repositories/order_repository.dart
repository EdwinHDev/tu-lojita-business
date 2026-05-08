import '../entities/order.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrdersPaginated(String storeId, int limit, int offset);
  Future<Order> updateOrderStatus(String orderId, String status, {String? reason});
  Future<Order> getOrderById(String orderId);
}
