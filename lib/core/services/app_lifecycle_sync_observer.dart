import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

class AppLifecycleSyncObserver with WidgetsBindingObserver {
  final Ref _ref;
  DateTime? _lastSyncTime;
  static const Duration _cooldownDuration = Duration(seconds: 3);

  final Map<String, FutureOr<void> Function()> _activeSyncTargets = {};

  AppLifecycleSyncObserver(this._ref);

  void init() {
    WidgetsBinding.instance.addObserver(this);
    log('AppLifecycleSyncObserver initialized for Business app', name: 'LifecycleSync');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeSyncTargets.clear();
    log('AppLifecycleSyncObserver disposed for Business app', name: 'LifecycleSync');
  }

  /// Registers a scoped screen refresh callback (e.g. for the currently visible OrderDetailsScreen).
  void registerTarget(String key, FutureOr<void> Function() callback) {
    _activeSyncTargets[key] = callback;
  }

  /// Unregisters the screen callback when the widget unmounts.
  void unregisterTarget(String key) {
    _activeSyncTargets.remove(key);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() async {
    final authState = _ref.read(authProvider);
    if (authState is! Authenticated) {
      log('Business resume sync skipped: user is not authenticated', name: 'LifecycleSync');
      return;
    }

    final now = DateTime.now();
    if (_lastSyncTime != null && now.difference(_lastSyncTime!) < _cooldownDuration) {
      log('Resume sync skipped: within 3s cooldown', name: 'LifecycleSync');
      return;
    }
    _lastSyncTime = now;

    log('App resumed: verifying socket and performing scoped sync', name: 'LifecycleSync');

    // 1. Verify WebSocket connection
    try {
      final socketService = _ref.read(socketServiceProvider);
      if (!socketService.isConnected) {
        log('Socket disconnected on resume, reconnecting...', name: 'LifecycleSync');
        await socketService.init();
      }
    } catch (e) {
      log('Error re-initializing socket on resume: $e', name: 'LifecycleSync');
    }

    // 2. Refresh unread notifications
    try {
      _ref.invalidate(notificationsProvider);
    } catch (_) {}

    // 3. Trigger scoped sync on currently mounted screens without resetting UI
    final targets = Map<String, FutureOr<void> Function()>.from(_activeSyncTargets);
    for (final entry in targets.entries) {
      try {
        log('Executing scoped sync for target: ${entry.key}', name: 'LifecycleSync');
        await entry.value();
      } catch (e) {
        log('Error executing sync for target ${entry.key}: $e', name: 'LifecycleSync');
      }
    }
  }
}

final appLifecycleSyncObserverProvider = Provider<AppLifecycleSyncObserver>((ref) {
  final observer = AppLifecycleSyncObserver(ref);
  observer.init();
  ref.onDispose(() => observer.dispose());
  return observer;
});
