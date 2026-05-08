import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/stores_repository.dart';
import 'dashboard_providers.dart';
import 'stores_state.dart';

class StoresNotifier extends Notifier<StoresState> {
  @override
  StoresState build() {
    // Initial fetch
    Future.microtask(() => loadData());
    return const StoresState();
  }

  StoresRepository get _repository => ref.read(storesRepositoryProvider);

  Future<void> loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    final companyId = authState.user.company?.id;
    if (companyId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await Future.wait([
        _repository.getCompanyStores(companyId),
        _repository.getDashboardStats(companyId),
      ]);

      if (!ref.mounted) return;

      state = state.copyWith(
        stores: results[0] as List<Store>,
        stats: results[1] as DashboardStats,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> createStore({
    required String branchName,
    required String phone,
    required String description,
    required String subCategoryId,
    Map<String, dynamic>? address,
  }) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      state = state.copyWith(errorMessage: 'No has iniciado sesión o tu sesión ha expirado.');
      return false;
    }

    final company = authState.user.company;
    if (company == null) {
      state = state.copyWith(errorMessage: 'No se encontró una empresa asociada a tu cuenta.');
      return false;
    }

    try {
      final newStoreData = {
        'companyId': company.id,
        'name': branchName, // Primary name required by DTO
        'branchName': branchName, // Optional branch name
        'phone': phone,
        'rif': company.rif, // Mandatory for @IsRif validation
        'logo': company.logo, // Mandatory @MinLength(1)
        'description': description,
        'subCategoryId': subCategoryId,
        'mainAddress': ?address,
      };

      await _repository.createStore(newStoreData);
      
      if (!ref.mounted) return false;

      await loadData(); // Refresh list
      return true;
    } on DioException catch (e) {
      if (!ref.mounted) return false;
      String message = e.toString();
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          final serverMessage = data['message'];
          message = serverMessage is List ? serverMessage.join(', ') : serverMessage.toString();
        }
      }
      state = state.copyWith(errorMessage: message);
      return false;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final storesProvider = NotifierProvider<StoresNotifier, StoresState>(() {
  return StoresNotifier();
});
