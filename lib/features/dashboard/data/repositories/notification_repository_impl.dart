import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'remote_notification_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final RemoteNotificationDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<AppNotification>> getNotifications() async {
    return await _remoteDataSource.getNotifications();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markDisputeRead(String orderId) async {
    await _remoteDataSource.markDisputeRead(orderId);
  }
}
