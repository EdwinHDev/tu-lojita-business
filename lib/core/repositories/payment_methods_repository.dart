import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../models/store_payment_method.dart';

final paymentMethodsRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return PaymentMethodsRepository(dio);
});

class PaymentMethodsRepository {
  final Dio _dio;

  PaymentMethodsRepository(this._dio);

  Future<List<StorePaymentMethod>> getStoreMethods(String storeId) async {
    try {
      final response = await _dio.get('/store-payment-methods/store/$storeId/management');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => StorePaymentMethod.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<StorePaymentMethod?> createMethod(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/store-payment-methods', data: data);
      if (response.statusCode == 201) {
        return StorePaymentMethod.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<StorePaymentMethod?> updateMethod(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/store-payment-methods/$id', data: data);
      if (response.statusCode == 200) {
        return StorePaymentMethod.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteMethod(String id) async {
    try {
      final response = await _dio.delete('/store-payment-methods/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final storePaymentMethodsProvider = FutureProvider.family<List<StorePaymentMethod>, String>((ref, storeId) async {
  final repository = ref.watch(paymentMethodsRepositoryProvider);
  return await repository.getStoreMethods(storeId);
});
