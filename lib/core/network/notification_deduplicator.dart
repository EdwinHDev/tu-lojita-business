import 'dart:collection';

/// Deduplicador en memoria con ventana de tiempo deslizante (Sliding Window TTL).
/// Garantiza que eventos concurrentes entre WebSocket y Firebase Cloud Messaging
/// en primer plano no generen notificaciones, sonidos o banners duplicados en la app de comercios.
class NotificationDeduplicator {
  static final NotificationDeduplicator _instance =
      NotificationDeduplicator._internal();
  factory NotificationDeduplicator() => _instance;
  NotificationDeduplicator._internal();

  final Map<String, DateTime> _seenMap = HashMap();
  static const Duration defaultTtl = Duration(seconds: 45);

  /// Retorna `true` si el ID no ha sido procesado recientemente y lo registra.
  /// Retorna `false` si es un duplicado detectado dentro de la ventana TTL.
  bool shouldProcess(String? id, {Duration ttl = defaultTtl}) {
    if (id == null || id.isEmpty) {
      return true;
    }

    _cleanupOldEntries();

    final now = DateTime.now();
    final lastSeen = _seenMap[id];

    if (lastSeen != null && now.difference(lastSeen) < ttl) {
      return false; // Duplicado detectado y suprimido
    }

    _seenMap[id] = now;
    return true;
  }

  void _cleanupOldEntries() {
    if (_seenMap.length < 50) return;
    final now = DateTime.now();
    _seenMap.removeWhere((key, timestamp) =>
        now.difference(timestamp) > const Duration(minutes: 2));
  }

  void clear() {
    _seenMap.clear();
  }
}
