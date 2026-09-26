import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/ranking_models.dart';

final storeRankingProvider =
    FutureProvider.family<StoreRankingData, String>((ref, storeId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/ranking/stores/$storeId');
  return StoreRankingData.fromJson(response.data as Map<String, dynamic>);
});

final storeEventsProvider =
    FutureProvider.family<List<RankingEventItem>, String>((ref, storeId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/ranking/stores/$storeId/events?limit=30');
  final items = response.data['items'] as List<dynamic>? ?? [];
  return items
      .map((item) => RankingEventItem.fromJson(item as Map<String, dynamic>))
      .toList();
});

final storeAchievementsProvider =
    FutureProvider.family<List<AchievementItem>, String>((ref, storeId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/ranking/stores/$storeId/achievements');
  final list = response.data as List<dynamic>? ?? [];
  return list
      .map((item) => AchievementItem.fromJson(item as Map<String, dynamic>))
      .toList();
});

final dailyMissionsProvider =
    FutureProvider.family<List<DailyMissionItem>, String>((ref, storeId) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/ranking/stores/$storeId/missions/daily');
  final list = response.data as List<dynamic>? ?? [];
  return list
      .map((item) => DailyMissionItem.fromJson(item as Map<String, dynamic>))
      .toList();
});

class MissionClaimNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> claimMission(String storeId, String missionCode) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/ranking/stores/$storeId/missions/$missionCode/claim');
      state = const AsyncValue.data(null);
      ref.invalidate(dailyMissionsProvider(storeId));
      ref.invalidate(storeRankingProvider(storeId));
      ref.invalidate(storeEventsProvider(storeId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final missionClaimNotifierProvider =
    NotifierProvider<MissionClaimNotifier, AsyncValue<void>>(MissionClaimNotifier.new);

class ShowcaseNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> updateShowcase(String storeId, List<String> achievementIds) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/ranking/stores/$storeId/achievements/showcase', data: {
        'achievementIds': achievementIds,
      });
      state = const AsyncValue.data(null);
      ref.invalidate(storeRankingProvider(storeId));
      ref.invalidate(storeAchievementsProvider(storeId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final showcaseNotifierProvider =
    NotifierProvider<ShowcaseNotifier, AsyncValue<void>>(ShowcaseNotifier.new);
