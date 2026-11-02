import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tu_lojita_business/core/network/firebase_messaging_service.dart';

void main() {
  group('Business FCM Notification Fallback and Extraction Tests', () {
    test('extracts title and body from notification when present and non-empty', () {
      final message = RemoteMessage(
        data: {
          'orderId': 'biz-order-456',
        },
        notification: const RemoteNotification(
          title: 'Nueva Venta Recibida',
          body: 'Se ha registrado una orden en tu tienda',
        ),
      );

      final extracted = FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Nueva Venta Recibida');
      expect(extracted['body'], 'Se ha registrado una orden en tu tienda');
      expect(extracted['orderId'], 'biz-order-456');
    });

    test('falls back to data fields when notification fields are empty strings', () {
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

      final extracted = FirebaseMessagingService.extractMessageDataForTest(message);
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

      final extracted = FirebaseMessagingService.extractMessageDataForTest(message);
      expect(extracted['title'], 'Mensaje de Soporte');
      expect(extracted['body'], 'Tienes una respuesta en la mediación');
    });
  });
}
