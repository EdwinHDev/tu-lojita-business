import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/store_ai_remote_datasource.dart';
import '../../data/repositories/store_ai_repository_impl.dart';
import '../../domain/entities/store_ai_models.dart';
import '../../domain/repositories/store_ai_repository.dart';

final storeAiRemoteDataSourceProvider = Provider<StoreAiRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return StoreAiRemoteDataSource(dio);
});

final storeAiRepositoryProvider = Provider<StoreAiRepository>((ref) {
  final remote = ref.watch(storeAiRemoteDataSourceProvider);
  return StoreAiRepositoryImpl(remote);
});

final storeAiSettingsProvider =
    FutureProvider.autoDispose.family<StoreAiSettings, String>(
  (ref, storeId) async {
    final repo = ref.watch(storeAiRepositoryProvider);
    return repo.getSettings(storeId);
  },
);

final storeAiCatalogProvider =
    FutureProvider.autoDispose.family<StoreAiCatalog, String>(
  (ref, storeId) async {
    final repo = ref.watch(storeAiRepositoryProvider);
    return repo.getCatalog(storeId);
  },
);

final platformAiGlobalEnabledProvider = FutureProvider<bool>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/platform-settings/public');
    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final aiMap = data['aiImageEnhancement'];
      if (aiMap is Map && aiMap['enabled'] != null) {
        return aiMap['enabled'] == true;
      }
    }
    return false;
  } catch (_) {
    return false;
  }
});
