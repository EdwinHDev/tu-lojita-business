import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/remote_notification_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';

import '../../../../core/network/socket_service.dart';
import '../../../../core/network/firebase_messaging_service.dart';
import '../../../../core/router/app_router.dart';

final firebaseMessagingServiceProvider =
    Provider<FirebaseMessagingService>((ref) {
  final dio = ref.watch(dioProvider);
  final service = FirebaseMessagingService(
    dio,
    () => ref.read(routerProvider),
    onMarkAsRead: (id) {
      ref.read(notificationRepositoryProvider).markAsRead(id).then((_) {
        ref.invalidate(notificationsProvider);
      }).catchError((_) {});
    },
  );
  service.init();
  return service;
});

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

/// Conjunto de IDs de órdenes con reclamos no leídos para comercio (Nivel 3 y 2)
final unreadBusinessDisputeOrderIdsProvider = Provider<Set<String>>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications
      .where((n) =>
          !n.isRead &&
          (n.type == 'MEDIATION_REQUEST' || n.type == 'MEDIATION_RESPONSE') &&
          !n.title.toLowerCase().contains('mediación') &&
          !n.title.toLowerCase().contains('mediacion'))
      .map((n) => n.targetId ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();
});

/// Conteo de órdenes con reclamos no leídos para el comercio (Nivel 1 Bottom Navigation Bar)
final unreadBusinessDisputeOrdersCountProvider = Provider<int>((ref) {
  final orderIds = ref.watch(unreadBusinessDisputeOrderIdsProvider);
  return orderIds.length;
});

