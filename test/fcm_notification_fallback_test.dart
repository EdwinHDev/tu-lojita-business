import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/network/firebase_messaging_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString:
          'API_BASE_URL=https://api.test.com/api/v1\nAPI_BASE_URL_IMAGES=https://images.test.com\n',
    );
  });

  final pushedRoutes = <MapEntry<String, Object?>>[];
  final openedModals = <MapEntry<String, Map<String, dynamic>>>[];
  final markedReadIds = <String>[];
  String simulatedCurrentPath = '/dashboard';
  Set<String>? allowedPermissions;
  Set<String>? allowedBranches;
  String? fallbackStoreId;

  late FirebaseMessagingService service;
  late GoRouter dummyRouter;

  setUp(() {
    pushedRoutes.clear();
    openedModals.clear();
    markedReadIds.clear();
    simulatedCurrentPath = '/dashboard';
    allowedPermissions = null;
    allowedBranches = null;
    fallbackStoreId = 'store-default-1';

    FirebaseMessagingService.resetForTesting();
    FirebaseMessagingService.debugCurrentPathOverride =
        () => simulatedCurrentPath;
    FirebaseMessagingService.debugPushRouteOverride =
        (route, extra) => pushedRoutes.add(MapEntry(route, extra));
    FirebaseMessagingService.debugModalOverride =
        (type, details) => openedModals.add(MapEntry(type, details));

    dummyRouter = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => throw UnimplementedError(),
        ),
      ],
    );

    final dio = Dio(BaseOptions(
      baseUrl: 'https://invalid.local.test',
      connectTimeout: const Duration(milliseconds: 50),
    ));

    service = FirebaseMessagingService(
      dio,
      () => dummyRouter,
      onMarkAsRead: (id) => markedReadIds.add(id),
      hasPermission: (perm) =>
          allowedPermissions == null || allowedPermissions!.contains(perm),
      canAccessBranch: (storeId) =>
          allowedBranches == null || allowedBranches!.contains(storeId),
      getFallbackStoreId: () => fallbackStoreId,
    );
  });

  tearDown(() {
    FirebaseMessagingService.resetForTesting();
  });

  group('Business FCM Notification Fallback and Extraction Tests', () {
    test('extracts title, body, and messageId when present and non-empty', () {
      final message = RemoteMessage(
        messageId: 'biz-msg-1',
        data: {
          'orderId': 'biz-order-456',
        },
        notification: const RemoteNotification(
          title: 'Nueva Venta Recibida',
          body: 'Se ha registrado una orden en tu tienda',
        ),
      );

      final extracted =
          FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Nueva Venta Recibida');
      expect(extracted['body'], 'Se ha registrado una orden en tu tienda');
      expect(extracted['orderId'], 'biz-order-456');
      expect(extracted['messageId'], 'biz-msg-1');
    });

    test('falls back to data fields when notification fields are empty strings',
        () {
      final message = RemoteMessage(
        data: {
          'title': 'Título Empresa Data',
          'body': 'Cuerpo Empresa Data',
          'type': 'ORDER_CREATED',
        },
        notification: const RemoteNotification(
          title: '   ',
          body: '',
        ),
      );

      final extracted =
          FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Título Empresa Data');
      expect(extracted['body'], 'Cuerpo Empresa Data');
      expect(extracted['type'], 'ORDER_CREATED');
    });

    test('falls back to data fields when notification object is null', () {
      final message = RemoteMessage(
        data: {
          'title': 'Mensaje de Soporte',
          'body': 'Tienes una respuesta en la mediación',
        },
      );

      final extracted =
          FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Mensaje de Soporte');
      expect(extracted['body'], 'Tienes una respuesta en la mediación');
    });

    test(
        'falls back to context-aware defaults when both notification and data have empty strings',
        () {
      final message = RemoteMessage(
        data: {
          'title': '   ',
          'body': '',
          'type': 'ORDER_CREATED',
        },
        notification: const RemoteNotification(
          title: '',
          body: '   ',
        ),
      );

      final extracted =
          FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Actualización de Pedido');
      expect(
          extracted['body'], 'Has recibido un nuevo pedido en tu comercio.');
    });

    test(
        'falls back to general merchant defaults when payload is completely devoid of title, body, and type',
        () {
      final message = RemoteMessage(
        data: {},
      );

      final extracted =
          FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Tu Lojita Comercio');
      expect(
          extracted['body'], 'Tienes una nueva notificación en tu comercio.');
    });
  });

  group('Cold/Warm Start Queue, Login Retention, Logout Reset & Deduplication',
      () {
    test(
        'queues notification across /onboarding -> /login -> /splash and consumes once /dashboard is ready',
        () async {
      simulatedCurrentPath = '/onboarding';
      service.queueOrNavigate({
        'notificationId': 'biz-cold-1',
        'type': 'ORDER_CREATED',
        'orderId': 'ord-biz-101',
        'storeId': 'store-default-1',
      });

      expect(pushedRoutes, isEmpty);
      expect(FirebaseMessagingService.pendingNotificationForTest, isNotNull);

      // Even during login or splash, remains queued
      simulatedCurrentPath = '/login';
      expect(pushedRoutes, isEmpty);

      // Dashboard mounts and consumes pending notification
      simulatedCurrentPath = '/dashboard';
      service.markAppReadyAndConsumePendingNotification();
      await Future<void>.delayed(Duration.zero);

      expect(pushedRoutes.map((e) => e.key), ['/dashboard/orders/ord-biz-101']);
      expect(markedReadIds, ['biz-cold-1']);
      expect(FirebaseMessagingService.pendingNotificationForTest, isNull);
    });

    test('deduplicates repeated tap of identical messageId/notificationId',
        () async {
      service.markAppReadyAndConsumePendingNotification();

      final payload = {
        'messageId': 'msg-biz-dup',
        'notificationId': 'notif-biz-dup',
        'type': 'CHAT_MESSAGE',
        'orderId': 'ord-biz-77',
        'channelType': 'DIRECT',
      };

      service.queueOrNavigate(payload);
      service.queueOrNavigate(payload);
      await Future<void>.delayed(Duration.zero);

      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/orders/ord-biz-77/chat'],
      );
    });

    test('resets readiness on logout so subsequent taps queue until re-login',
        () {
      service.markAppReadyAndConsumePendingNotification();
      FirebaseMessagingService.resetReadinessOnLogout();

      service.queueOrNavigate({
        'notificationId': 'notif-after-logout',
        'type': 'ORDER_CREATED',
        'orderId': 'ord-999',
      });

      expect(pushedRoutes, isEmpty);
      expect(FirebaseMessagingService.pendingNotificationForTest, isNotNull);
    });

    test('enforces collaborator branch access and role permission guards',
        () async {
      service.markAppReadyAndConsumePendingNotification();

      // Unauthorized branch -> redirects safely to /dashboard/notifications
      allowedBranches = {'store-allowed'};
      await service.handleNotificationNavigation({
        'notificationId': 'n-unauth-branch',
        'type': 'ORDER_CREATED',
        'orderId': 'ord-secret',
        'storeId': 'store-other',
      });
      expect(pushedRoutes.map((e) => e.key), ['/dashboard/notifications']);

      // Missing permission -> blocks navigation
      pushedRoutes.clear();
      allowedBranches = null;
      allowedPermissions = {'items:view'};
      await service.handleNotificationNavigation({
        'notificationId': 'n-unauth-perm',
        'type': 'ORDER_CREATED',
        'orderId': 'ord-secret-2',
        'storeId': 'store-default-1',
      });
      expect(pushedRoutes, isEmpty);
    });
  });

  group('Complete Business NotificationType Deep-Link Matrix', () {
    setUp(() {
      simulatedCurrentPath = '/dashboard';
      service.markAppReadyAndConsumePendingNotification();
    });

    test('routes all order, payment, refund, review, and general-order types',
        () async {
      final types = [
        'ORDER_CREATED',
        'ORDER_APPROVED',
        'ORDER_REJECTED',
        'ORDER_STATUS_CHANGED',
        'PAYMENT_REPORTED',
        'PAYMENT_APPROVED',
        'PAYMENT_REJECTED',
        'REFUND_REPORTED',
        'REFUND_CONFIRMED',
        'BUYER_REVIEW_PROMPT',
        'ORDER_REVIEW_RECEIVED',
        'GENERAL',
      ];

      for (var i = 0; i < types.length; i++) {
        pushedRoutes.clear();
        await service.handleNotificationNavigation({
          'notificationId': 'b-ord-$i',
          'type': types[i],
          'orderId': 'ord-b-$i',
          'storeId': 'store-default-1',
          'title': 'Actualización de pedido',
          'body': 'Detalle del pedido actualizado',
        });
        expect(
          pushedRoutes.map((e) => e.key),
          ['/dashboard/orders/ord-b-$i'],
          reason: types[i],
        );
      }
    });

    test('routes direct chat and support chat nested under /dashboard',
        () async {
      await service.handleNotificationNavigation({
        'notificationId': 'b-chat-1',
        'type': 'CHAT_MESSAGE',
        'orderId': 'ord-c1',
        'channelType': 'DIRECT',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/orders/ord-c1/chat'],
      );

      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-chat-2',
        'type': 'CHAT_MESSAGE',
        'orderId': 'ord-c2',
        'channelType': 'DISPUTE_MERCHANT_SUPPORT',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/orders/ord-c2/support-chat'],
      );

      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-chat-3',
        'type': 'SUPPORT_CHAT_MESSAGE',
        'targetId': 'ord-c3',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/orders/ord-c3/support-chat'],
      );
    });

    test('routes order disputes vs store-block mediation requests accurately',
        () async {
      await service.handleNotificationNavigation({
        'notificationId': 'b-disp-1',
        'type': 'DISPUTE_ESCALATED',
        'orderId': 'ord-d1',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/orders/ord-d1?openDispute=true'],
      );

      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-disp-2',
        'type': 'MEDIATION_REQUEST',
        'orderId': 'ord-d2',
        'targetId': 'ord-d2',
        'title': 'Nuevo reclamo recibido',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/orders/ord-d2?openDispute=true'],
      );

      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-med-store',
        'type': 'MEDIATION_REQUEST',
        'storeId': 'store-m9',
        'targetId': 'med-req-55',
        'title': 'Nueva solicitud de mediación',
        'body': 'Un cliente envió una solicitud de mediación por bloqueo.',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/stores/store-m9/mediation-requests'],
      );
    });

    test(
        'routes catalog, health modals, reports, moderation, ranking, achievements, and general info',
        () async {
      // ITEM_HIDDEN
      await service.handleNotificationNavigation({
        'notificationId': 'b-item-1',
        'type': 'ITEM_HIDDEN',
        'storeId': 'store-cat-1',
      });
      expect(
        pushedRoutes.map((e) => e.key),
        ['/dashboard/stores/store-cat-1/items'],
      );

      // STRIKE_APPLIED & STORE_SUSPENDED -> StoreHealthSheet
      openedModals.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-strike-1',
        'type': 'STRIKE_APPLIED',
        'storeId': 'store-h1',
      });
      expect(openedModals.single.key, 'STORE_HEALTH');
      expect(openedModals.single.value['storeId'], 'store-h1');

      // REPORT_RESOLUTION -> ReportDetailSheet
      openedModals.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-rep-1',
        'type': 'REPORT_RESOLUTION',
        'targetId': 'rep-77',
      });
      expect(openedModals.single.key, 'REPORT_DETAIL');
      expect(openedModals.single.value['targetId'], 'rep-77');

      // Moderation notice ('Acceso al chat restaurado') -> ChatPenaltyExplanationModal
      openedModals.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-mod-restored',
        'type': 'GENERAL',
        'title': 'Acceso al chat restaurado',
        'body': 'Tu acceso al chat de órdenes ha sido restablecido.',
      });
      expect(openedModals.single.key, 'CHAT_PENALTY');

      // DIVISION_UP / DIVISION_DOWN / STORE_FLAGGED
      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-div-up',
        'type': 'DIVISION_UP',
        'storeId': 'store-r1',
        'body': '¡Subiste a ORO!',
      });
      expect(pushedRoutes.single.key, '/dashboard/ranking/celebration');
      expect((pushedRoutes.single.value as Map)['division'], 'ORO');

      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-div-down',
        'type': 'DIVISION_DOWN',
        'storeId': 'store-r1',
        'body': 'Descendiste a PLATA.',
      });
      expect(pushedRoutes.single.key, '/dashboard/ranking/division-down');
      expect((pushedRoutes.single.value as Map)['division'], 'PLATA');

      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-flagged',
        'type': 'STORE_FLAGGED',
        'storeId': 'store-r1',
        'body': 'Actividad inusual detectada',
      });
      expect(pushedRoutes.single.key, '/dashboard/ranking/flagged');

      // Ranking alerts -> /dashboard/stores/:storeId/ranking
      for (final rType in [
        'WEEKLY_RANKING_SUMMARY',
        'STREAK_EXPIRING',
        'CATEGORY_RIVALRY',
        'RANK_SHIELD_EXPIRING',
        'DANGER_ZONE_ALERT',
      ]) {
        pushedRoutes.clear();
        await service.handleNotificationNavigation({
          'notificationId': 'b-rk-$rType',
          'type': rType,
          'storeId': 'store-r1',
        });
        expect(
          pushedRoutes.map((e) => e.key),
          ['/dashboard/stores/store-r1/ranking'],
          reason: rType,
        );
      }

      // ACHIEVEMENT_UNLOCKED
      pushedRoutes.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-ach-1',
        'type': 'ACHIEVEMENT_UNLOCKED',
        'storeId': 'store-r1',
        'title': '¡Logro Desbloqueado!',
        'body': 'Obtuviste "Primeros Pasos" (+50 LP)',
      });
      expect(
        pushedRoutes.single.key,
        '/dashboard/ranking/achievement-unlocked',
      );
      expect(
        (pushedRoutes.single.value as Map)['achievementTitle'],
        'Primeros Pasos',
      );
      expect((pushedRoutes.single.value as Map)['lpBonus'], 50);

      // GENERAL informational without order/store target -> /dashboard/notifications + GENERAL_INFO dialog
      pushedRoutes.clear();
      openedModals.clear();
      await service.handleNotificationNavigation({
        'notificationId': 'b-gen-info',
        'type': 'GENERAL',
        'title': 'Comunicado oficial',
        'body': 'Actualización de términos comerciales.',
      });
      expect(pushedRoutes.map((e) => e.key), ['/dashboard/notifications']);
      expect(openedModals.single.key, 'GENERAL_INFO');
    });
  });
}
