import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class RemoteNotificationDataSource {
  final Dio _dio;

  RemoteNotificationDataSource(this._dio);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      final List data = response.data;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markDisputeRead(String orderId) async {
    try {
      await _dio.patch('/notifications/order/$orderId/dispute-read');
    } catch (_) {
      // Silently catch network errors
    }
  }
}

