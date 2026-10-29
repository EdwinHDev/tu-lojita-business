import 'dart:developer';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/network/notification_deduplicator.dart';

import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/collaborators/presentation/providers/collaborators_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_category_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_notifier.dart';
import 'package:tu_lojita_business/features/subscription/presentation/providers/subscription_provider.dart';

class SessionPurgeService {
  final Ref _ref;

  SessionPurgeService(this._ref);

  /// Executes a comprehensive purge across all layers:
  /// 1. Sockets & real-time listeners teardown
  /// 2. Flutter image memory eviction
  /// 3. In-memory Riverpod business state resets and invalidation
  /// 4. Local auth storage and session tokens wipe
  Future<void> purge() async {
    log('SessionPurgeService: Starting full session and cache purge...');

    // 0. Unregister FCM device token from backend while JWT is still available
    try {
      await _ref
          .read(firebaseMessagingServiceProvider)
          .unregisterDeviceToken()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      log('SessionPurgeService: Warning during FCM device unregister: $e');
    }
    NotificationDeduplicator().clear();

    // 1. Wipe secure storage and tokens FIRST so nothing reloads from persistence
    await _purgeStorage();

    // 2. Sockets & Transports teardown
    _purgeSockets();

    // 3. Flutter Image Cache eviction
    _purgeImageCache();

    // 4. Reset and Invalidate Riverpod Business Providers
    _resetAndInvalidateProviders();

    log('SessionPurgeService: Session and cache purge completed successfully.');
  }

  void _purgeSockets() {
    try {
      final socketService = _ref.read(socketServiceProvider);
      socketService.leaveAllStores();
      socketService.disconnect();
    } catch (e) {
      log('SessionPurgeService: Warning during socket disconnect: $e');
    }
  }

  void _purgeImageCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      log('SessionPurgeService: Image cache and live images cleared.');
    } catch (e) {
      log('SessionPurgeService: Image cache clear skipped (binding not initialized or headless test): $e');
    }
  }

  void _resetAndInvalidateProviders() {
    // Explicit notifier resets for immediate empty state
    try {
      _ref.read(storesProvider.notifier).reset();
    } catch (_) {}

    try {
      _ref.read(dashboardAnalyticsProvider.notifier).reset();
    } catch (_) {}

    try {
      _ref.read(itemListProvider.notifier).reset();
    } catch (_) {}

    try {
      _ref.read(companyOnboardingProvider.notifier).reset();
    } catch (_) {}

    // Invalidate all business and company scoped state providers
    _ref.invalidate(storesProvider);
    _ref.invalidate(dashboardAnalyticsProvider);
    _ref.invalidate(itemListProvider);
    _ref.invalidate(storeSettingsProvider);
    _ref.invalidate(storeDetailsProvider);
    _ref.invalidate(storeCategoryProvider);
    _ref.invalidate(companyOnboardingProvider);
    _ref.invalidate(subscriptionProvider);
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(rolesNotifierProvider);
    _ref.invalidate(collaboratorsNotifierProvider);
    _ref.invalidate(dashboardIndexProvider);
  }

  Future<void> _purgeStorage() async {
    try {
      final localAuth = _ref.read(localAuthDataSourceProvider);
      await localAuth.clearAll();
    } catch (e) {
      log('SessionPurgeService: Warning during storage clearAll: $e');
    }
  }
}

final sessionPurgeServiceProvider = Provider<SessionPurgeService>((ref) {
  return SessionPurgeService(ref);
});
