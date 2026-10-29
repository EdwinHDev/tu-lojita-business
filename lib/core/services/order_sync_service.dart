import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderSyncEvent {
  final String orderId;
  final String? storeId;
  final String type;
  final String? title;
  final String? body;
  final Map<String, dynamic> rawData;

  const OrderSyncEvent({
    required this.orderId,
    this.storeId,
    required this.type,
    this.title,
    this.body,
    required this.rawData,
  });

  @override
  String toString() =>
      'OrderSyncEvent(orderId: $orderId, storeId: $storeId, type: $type)';
}

class OrderSyncService {
  final _eventController = StreamController<OrderSyncEvent>.broadcast();

  Stream<OrderSyncEvent> get events => _eventController.stream;

  Stream<OrderSyncEvent> eventsForOrder(String orderId) {
    return _eventController.stream.where((event) => event.orderId == orderId);
  }

  /// Universal order and store information extractor from any incoming socket,
  /// FCM push notification, or background launch payload.
  OrderSyncEvent? parsePayload(Map<String, dynamic> data) {
    try {
      final type = _extractString(data, ['type', 'notificationType']) ?? '';

      // Check non-order types to avoid false positives
      if (_isNonOrderType(type)) {
        return null;
      }

      final orderId = _extractOrderId(data);
      if (orderId == null || orderId.isEmpty) {
        return null;
      }

      final storeId = _extractStoreId(data);
      final title = _extractString(data, ['title', 'notificationTitle']);
      final body = _extractString(data, ['body', 'message', 'notificationBody']);

      return OrderSyncEvent(
        orderId: orderId,
        storeId: storeId,
        type: type,
        title: title,
        body: body,
        rawData: data,
      );
    } catch (e, stack) {
      log('Error parsing OrderSyncEvent: $e\n$stack', name: 'OrderSyncService');
      return null;
    }
  }

  /// Processes raw incoming socket or notification payload and dispatches
  /// to the broadcast stream if relevant. Returns the event if parsed.
  OrderSyncEvent? handleIncomingPayload(Map<String, dynamic> data) {
    final event = parsePayload(data);
    if (event != null) {
      log('Dispatching order sync event: $event', name: 'OrderSyncService');
      _eventController.add(event);
    }
    return event;
  }

  String? _extractOrderId(Map<String, dynamic> data) {
    // 1. Direct fields
    if (data['orderId'] != null && data['orderId'].toString().isNotEmpty) {
      return data['orderId'].toString();
    }

    // 2. Nested order map
    if (data['order'] is Map && data['order']['id'] != null) {
      return data['order']['id'].toString();
    }

    // 3. Payload inside "data" sub-map (common in FCM)
    if (data['data'] is Map) {
      final nested = Map<String, dynamic>.from(data['data'] as Map);
      final nestedId = _extractOrderId(nested);
      if (nestedId != null) return nestedId;
    }

    // 4. Fallback to targetId if it looks like an order or type is order related
    final type = _extractString(data, ['type', 'notificationType']) ?? '';
    final targetId = _extractString(data, ['targetId']);
    if (targetId != null && targetId.isNotEmpty && _isOrderTarget(type, data)) {
      return targetId;
    }

    return null;
  }

  String? _extractStoreId(Map<String, dynamic> data) {
    if (data['storeId'] != null && data['storeId'].toString().isNotEmpty) {
      return data['storeId'].toString();
    }
    if (data['store'] is Map && data['store']['id'] != null) {
      return data['store']['id'].toString();
    }
    if (data['data'] is Map) {
      final nested = Map<String, dynamic>.from(data['data'] as Map);
      final nestedStoreId = _extractStoreId(nested);
      if (nestedStoreId != null) return nestedStoreId;
    }
    return null;
  }

  String? _extractString(Map<String, dynamic> data, List<String> candidateKeys) {
    for (final key in candidateKeys) {
      if (data[key] != null && data[key].toString().isNotEmpty) {
        return data[key].toString();
      }
    }
    if (data['data'] is Map) {
      final nested = Map<String, dynamic>.from(data['data'] as Map);
      for (final key in candidateKeys) {
        if (nested[key] != null && nested[key].toString().isNotEmpty) {
          return nested[key].toString();
        }
      }
    }
    return null;
  }

  bool _isNonOrderType(String type) {
    if (type.isEmpty) return false;
    final upper = type.toUpperCase();
    return upper.startsWith('DIVISION') ||
        upper.startsWith('ACHIEVEMENT') ||
        upper.startsWith('STORE_FLAGGED') ||
        upper.startsWith('WEEKLY_RANKING') ||
        upper == 'CUSTOMER_BLOCKED' ||
        upper == 'CUSTOMER_UNBLOCKED' ||
        upper.startsWith('PENALTY') ||
        (upper.contains('REPORT') &&
            !upper.contains('UNRECEIVED') &&
            !upper.contains('PAYMENT_REPORTED') &&
            !upper.contains('REFUND_REPORTED'));
  }

  bool _isOrderTarget(String type, Map<String, dynamic> data) {
    final upper = type.toUpperCase();
    if (_isNonOrderType(upper)) return false;
    // Check if targetId is an order ID rather than a store/user ID
    if (upper.contains('ORDER') ||
        upper.contains('PAYMENT') ||
        upper.contains('INSTALLMENT') ||
        upper.contains('REFUND') ||
        upper.contains('DISPUTE') ||
        upper.contains('MEDIATION') ||
        upper.contains('UNRECEIVED')) {
      return true;
    }
    final title = _extractString(data, ['title', 'notificationTitle'])?.toUpperCase() ?? '';
    final body = _extractString(data, ['body', 'message', 'notificationBody'])?.toUpperCase() ?? '';
    if (title.contains('ORDEN') ||
        title.contains('PEDIDO') ||
        title.contains('REEMBOLSO') ||
        title.contains('CANCELAC') ||
        title.contains('ACUERDO') ||
        title.contains('RESOLUC') ||
        body.contains('ORDEN') ||
        body.contains('PEDIDO') ||
        body.contains('REEMBOLSO') ||
        body.contains('CANCELAC') ||
        body.contains('ACUERDO') ||
        body.contains('RESOLUC')) {
      return true;
    }
    // If targetId is provided and storeId is also separately present, targetId is likely orderId
    if (data.containsKey('storeId') && data['targetId'] != data['storeId']) {
      return true;
    }
    final targetId = _extractString(data, ['targetId']) ?? '';
    final uuidRegex = RegExp(r'^[0-9a-fA-F-]{36}$');
    if (uuidRegex.hasMatch(targetId) && !upper.contains('USER') && !upper.contains('STORE')) {
      return true;
    }
    return false;
  }

  void dispose() {
    _eventController.close();
  }
}

final orderSyncServiceProvider = Provider<OrderSyncService>((ref) {
  final service = OrderSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});
