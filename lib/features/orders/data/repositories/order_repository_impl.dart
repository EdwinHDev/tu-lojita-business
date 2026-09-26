import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/error_parser.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final Dio dio;

  OrderRepositoryImpl({required this.dio});

  @override
  Future<List<Order>> getOrdersPaginated(String storeId, int limit, int offset, {String? status, bool? hasDispute}) async {
    try {
      final queryParams = <String, dynamic>{
        'storeId': storeId,
        'limit': limit,
        'offset': offset,
      };
      if (status != null) {
        queryParams['status'] = status;
      }
      if (hasDispute != null) {
        queryParams['hasDispute'] = hasDispute;
      }

      final response = await dio.get(
        '/order',
        queryParameters: queryParams,
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

  @override
  Future<List<Installment>> getStoreInstallments(String storeId) async {
    try {
      final response = await dio.get('/order/store/$storeId/installments');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Installment.fromJson(json)).toList();
      } else {
        throw ServerException('Error al cargar las cuotas de la tienda');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> verifyExtension(String installmentId, String status, {String? merchantComment}) async {
    try {
      final response = await dio.post(
        '/order/installment/$installmentId/verify-extension',
        data: {
          'status': status,
          'merchantComment': merchantComment,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Error al verificar la prórroga');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Order> verifyPayment(String paymentId, String status, String orderId, {String? rejectionReason}) async {
    try {
      final response = await dio.post(
        '/payment/$paymentId/verify',
        data: {
          'status': status,
          if (rejectionReason != null && rejectionReason.isNotEmpty)
            'rejectionReason': rejectionReason,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException('Error al verificar el comprobante de pago');
      }

      // Fetch the updated order details
      return await getOrderById(orderId);
    } catch (e) {
      throw ServerException(ErrorParser.parse(e));
    }
  }

  @override
  Future<List<Installment>> getStoreReceivables(String storeId) async {
    try {
      final response = await dio.get('/order/store/$storeId/installments/receivables');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Installment.fromJson(json)).toList();
      } else {
        throw ServerException('Error al cargar la tesorería proyectada');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderStatement(String orderId) async {
    try {
      final response = await dio.get('/order/$orderId/statement');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException('Error al cargar el estado de cuenta');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> registerManualPayment(
    String orderId,
    double amount,
    String paymentMethod, {
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '/order/$orderId/manual-payment',
        data: {
          'amount': amount,
          'paymentMethod': paymentMethod,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException('Error al registrar el pago manual');
      }
    } catch (e) {
      throw ServerException(ErrorParser.parse(e));
    }
  }
}

