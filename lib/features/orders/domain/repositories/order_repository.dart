import '../entities/order.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrdersPaginated(String storeId, int limit, int offset, {String? status});
  Future<Order> updateOrderStatus(String orderId, String status, {String? reason});
  Future<Order> getOrderById(String orderId);
  Future<List<Installment>> getStoreInstallments(String storeId);
  Future<void> verifyExtension(String installmentId, String status, {String? merchantComment});
  Future<Order> verifyPayment(String paymentId, String status, String orderId);
  Future<List<Installment>> getStoreReceivables(String storeId);
  Future<Map<String, dynamic>> getOrderStatement(String orderId);
}
