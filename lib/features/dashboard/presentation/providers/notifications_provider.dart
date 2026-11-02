import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/remote_notification_data_source.dart';
import '../../data/repositories/notification_repository_impl.dart';

import '../../../../core/network/socket_service.dart';
import '../../../../core/network/firebase_messaging_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/notification_helper.dart';
import 'stores_notifier.dart';

final firebaseMessagingServiceProvider =
    Provider<FirebaseMessagingService>((ref) {
  final dio = ref.watch(dioProvider);
  final service = FirebaseMessagingService(
    dio,
    () => ref.read(routerProvider),
    onMarkAsRead: (id) {
      ref.read(notificationsProvider.notifier).markAsRead(id);
    },
    onNotificationReceived: () {
      ref.read(notificationsProvider.notifier).loadNotifications();
    },
    hasPermission: (perm) {
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        return authState.user.hasPermission(perm);
      }
      return false;
    },
    canAccessBranch: (storeId) {
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        if (!authState.user.isCollaborator) return true;
        return authState.user.canAccessBranch(storeId);
      }
      return true;
    },
    getFallbackStoreId: () => ref.read(storesProvider).stores.firstOrNull?.id,
    ensureStoresLoaded: () async {
      if (ref.read(storesProvider).stores.isEmpty) {
        await ref.read(storesProvider.notifier).loadData();
      }
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

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  final Set<String> _pendingReadIds = {};
  final Set<String> _pendingDisputeReadOrderIds = {};

  @override
  Future<List<AppNotification>> build() async {
    final socket = ref.watch(socketServiceProvider);
    final subscription = socket.notificationsStream.listen((_) {
      loadNotifications();
    });
    ref.onDispose(() => subscription.cancel());

    return await _fetchWithPendingReads();
  }

  Future<List<AppNotification>> _fetchWithPendingReads() async {
    final items = await ref.read(notificationRepositoryProvider).getNotifications();
    if (_pendingReadIds.isEmpty && _pendingDisputeReadOrderIds.isEmpty) {
      return items;
    }
    return items.map((n) {
      if (_pendingReadIds.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      if (n.targetId != null &&
          _pendingDisputeReadOrderIds.contains(n.targetId) &&
          (n.type == 'MEDIATION_REQUEST' ||
              n.type == 'MEDIATION_RESPONSE' ||
              n.type == 'DISPUTE_ESCALATED')) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  Future<void> loadNotifications() async {
    try {
      final items = await _fetchWithPendingReads();
      if (!ref.mounted) return;
      state = AsyncValue.data(items);
    } catch (e, st) {
      if (!ref.mounted) return;
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> markAsRead(String id) async {
    if (id.isEmpty) return;
    _pendingReadIds.add(id);
    NotificationHelper.cancelNotification(id.hashCode);

    if (state.value != null) {
      state = AsyncData([
        for (final n in state.value!)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ]);
    }

    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
    } catch (_) {}
  }

  Future<void> markDisputeRead(String orderId) async {
    if (orderId.isEmpty) return;
    _pendingDisputeReadOrderIds.add(orderId);

    if (state.value != null) {
      state = AsyncData([
        for (final n in state.value!)
          if (n.targetId == orderId &&
              (n.type == 'MEDIATION_REQUEST' ||
                  n.type == 'MEDIATION_RESPONSE' ||
                  n.type == 'DISPUTE_ESCALATED') &&
              !(n.storeId != null &&
                  n.storeId!.isNotEmpty &&
                  n.targetId == n.storeId)) ...[
            () {
              _pendingReadIds.add(n.id);
              NotificationHelper.cancelNotification(n.id.hashCode);
              return n.copyWith(isRead: true);
            }(),
          ] else
            n,
      ]);
    }

    try {
      await ref.read(notificationRepositoryProvider).markDisputeRead(orderId);
    } catch (_) {}
  }

  Future<void> markOrderNotificationsAsRead(
    String orderId, {
    bool onlyChat = false,
    bool isSupportChat = false,
  }) async {
    if (orderId.isEmpty) return;
    NotificationHelper.cancelNotification(orderId.hashCode);
    if (isSupportChat) {
      NotificationHelper.cancelNotification((orderId.hashCode + 1).abs());
    }

    List<AppNotification> currentList;
    if (state.value != null) {
      currentList = state.value!;
    } else {
      try {
        currentList = await future;
      } catch (_) {
        return;
      }
    }

    final toMark = currentList.where((n) {
      if (n.isRead) return false;
      if (n.targetId != orderId) return false;
      if (n.storeId != null && n.storeId!.isNotEmpty && n.targetId == n.storeId) {
        return false;
      }
      if (onlyChat) {
        final ch = (n.channelType ?? '').toUpperCase();
        final isSupport = n.type == 'SUPPORT_CHAT_MESSAGE' ||
            ch.contains('SUPPORT') ||
            (ch.isEmpty &&
                (n.title.toLowerCase().contains('soporte') ||
                    n.body.toLowerCase().contains('soporte')));
        if (isSupportChat) return isSupport;
        return n.type == 'CHAT_MESSAGE' && !isSupport;
      }
      return true;
    }).toList();

    if (toMark.isNotEmpty) {
      final idsToMark = toMark.map((n) => n.id).toSet();
      _pendingReadIds.addAll(idsToMark);
      for (final n in toMark) {
        NotificationHelper.cancelNotification(n.id.hashCode);
      }

      if (state.value != null) {
        state = AsyncData([
          for (final n in state.value!)
            if (idsToMark.contains(n.id)) n.copyWith(isRead: true) else n,
        ]);
      }

      try {
        await Future.wait(
          toMark.map((n) => ref.read(notificationRepositoryProvider).markAsRead(n.id)),
        );
      } catch (_) {}
    }

    if (!onlyChat) {
      await markDisputeRead(orderId);
    }
  }

  void reset() {
    _pendingReadIds.clear();
    _pendingDisputeReadOrderIds.clear();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Conjunto de IDs de órdenes con reclamos no leídos para comercio (Nivel 3 y 2)
final unreadBusinessDisputeOrderIdsProvider = Provider<Set<String>>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? [];
  return notifications
      .where((n) {
        if (n.isRead) return false;
        if (n.type != 'MEDIATION_REQUEST' &&
            n.type != 'MEDIATION_RESPONSE' &&
            n.type != 'DISPUTE_ESCALATED') {
          return false;
        }
        final targetId = n.targetId ?? '';
        if (targetId.isEmpty) return false;
        // Excluir mediaciones de bloqueo a nivel de tienda (donde targetId == storeId)
        if (n.storeId != null &&
            n.storeId!.isNotEmpty &&
            targetId == n.storeId) {
          return false;
        }
        final ch = (n.channelType ?? '').toUpperCase();
        final isOrderDispute = n.type == 'DISPUTE_ESCALATED' ||
            ch == 'DISPUTE_BUYER_SELLER' ||
            ch.contains('DISPUTE') ||
            n.title.toLowerCase().contains('reclamo') ||
            n.body.toLowerCase().contains('reclamo') ||
            n.body.toLowerCase().contains('pedido') ||
            n.body.toLowerCase().contains('orden');
        return isOrderDispute;
      })
      .map((n) => n.targetId!)
      .toSet();
});

/// Conteo de órdenes con reclamos no leídos para el comercio (Nivel 1 Bottom Navigation Bar)
final unreadBusinessDisputeOrdersCountProvider = Provider<int>((ref) {
  final orderIds = ref.watch(unreadBusinessDisputeOrderIdsProvider);
  return orderIds.length;
});

