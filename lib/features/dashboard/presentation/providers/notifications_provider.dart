import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/remote_notification_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';

import '../../../../core/network/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final localAuth = ref.watch(localAuthDataSourceProvider);
  final socket = SocketService(localAuth);
  socket.init();
  ref.onDispose(() => socket.dispose());
  return socket;
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final remoteDataSource = RemoteNotificationDataSource(dio);
  return NotificationRepositoryImpl(remoteDataSource);
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  // Escuchar cambios por socket para invalidar este provider
  final socket = ref.watch(socketServiceProvider);
  final subscription = socket.notificationsStream.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => subscription.cancel());

  return await ref.watch(notificationRepositoryProvider).getNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
