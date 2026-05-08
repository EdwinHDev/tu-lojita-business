import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final Dio dio;

  OrderRepositoryImpl({required this.dio});

  @override
  Future<List<Order>> getOrdersPaginated(String storeId, int limit, int offset) async {
    try {
      final response = await dio.get(
        '/order',
        queryParameters: {
          'storeId': storeId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data['items'];
        return items.map((json) => Order.fromJson(json)).toList();
      } else {
        throw ServerException('Error al cargar las órdenes');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Order> updateOrderStatus(String orderId, String status, {String? reason}) async {
    try {
      final response = await dio.patch(
        '/order/$orderId',
        data: {
          'status': status,
          'rejectionReason': reason,
        },
      );

      if (response.statusCode == 200) {
        return Order.fromJson(response.data);
      } else {
        throw ServerException('Error al actualizar el estado de la orden');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await dio.get('/order/$orderId');

      if (response.statusCode == 200) {
        return Order.fromJson(response.data);
      } else {
        throw ServerException('Error al cargar la orden');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
