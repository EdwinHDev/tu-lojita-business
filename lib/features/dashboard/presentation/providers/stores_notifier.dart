import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/data/datasources/image_remote_data_source.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/stores_repository.dart';
import 'dashboard_providers.dart';
import 'notifications_provider.dart';
import 'stores_state.dart';

class StoresNotifier extends Notifier<StoresState> {
  @override
  StoresState build() {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is! Authenticated) {
        reset();
      }
    });
    // Initial fetch
    Future.microtask(() => loadData());
    return const StoresState();
  }

  void reset() {
    state = const StoresState();
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

      final storesList = results[0] as List<Store>;
      for (final s in storesList) {
        ref.read(socketServiceProvider).joinStore(s.id);
      }

      state = state.copyWith(
        stores: storesList,
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
    String? subCategoryId,
    double latitude = 10.4806,
    double longitude = -66.9036,
    String timezone = 'America/Caracas',
    Map<String, dynamic>? address,
    File? coverImageFile,
    String? instagram,
    String? tiktok,
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
      String? coverImageUrl;
      if (coverImageFile != null) {
        final imageDataSource = ImageRemoteDataSourceImpl(ref.read(dioProvider));
        coverImageUrl = await imageDataSource.uploadImage(coverImageFile);
      }

      Map<String, dynamic>? mappedAddress;
      if (address != null) {
        mappedAddress = {
          'address': address['street'] ?? address['address'] ?? '',
          'city': address['city'] ?? '',
          'state': address['state'] ?? '',
          'latitude': latitude,
          'longitude': longitude,
        };
      }

      final effectiveSubcategoryId = subCategoryId ?? company.subcategoryId;

      final newStoreData = {
        'companyId': company.id,
        'name': company.name, // Primary commercial name
        'branchName': branchName, // Branch name (e.g., Principal)
        'phone': phone,
        'rif': company.rif, // Mandatory for @IsRif validation
        'logo': company.logo, // Mandatory @MinLength(1)
        'description': description,
        // ignore: use_null_aware_elements
        if (effectiveSubcategoryId != null) 'subCategoryId': effectiveSubcategoryId,
        // ignore: use_null_aware_elements
        if (coverImageUrl != null) 'coverImage': coverImageUrl,
        if (instagram != null && instagram.isNotEmpty) 'instagram': instagram,
        if (tiktok != null && tiktok.isNotEmpty) 'tiktok': tiktok,
        'mainAddress': mappedAddress,
        'timezone': timezone,
      };

      try {
        await _repository.createStore(newStoreData);
      } on DioException catch (dioErr) {
        final errData = dioErr.response?.data;
        final errMsg = (errData is Map && errData.containsKey('message'))
            ? (errData['message'] is List
                ? (errData['message'] as List).join(', ')
                : errData['message'].toString())
            : '';
        if ((errMsg.contains('property instagram should not exist') ||
                errMsg.contains('property tiktok should not exist')) &&
            (newStoreData.containsKey('instagram') || newStoreData.containsKey('tiktok'))) {
          final fallbackData = Map<String, dynamic>.from(newStoreData)
            ..remove('instagram')
            ..remove('tiktok');
          await _repository.createStore(fallbackData);
        } else {
          rethrow;
        }
      }
      
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

  Future<bool> setupExistingStore({
    required String storeId,
    required String branchName,
    required String phone,
    required String description,
    File? coverImageFile,
    String? instagram,
    String? tiktok,
  }) async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      state = state.copyWith(errorMessage: 'No has iniciado sesión o tu sesión ha expirado.');
      return false;
    }

    try {
      String? coverImageUrl;
      if (coverImageFile != null) {
        final imageDataSource = ImageRemoteDataSourceImpl(ref.read(dioProvider));
        coverImageUrl = await imageDataSource.uploadImage(coverImageFile);
      }

      final updateData = <String, dynamic>{
        'branchName': branchName,
        'phone': phone,
        'description': description,
        // ignore: use_null_aware_elements
        if (coverImageUrl != null) 'coverImage': coverImageUrl,
        // ignore: use_null_aware_elements
        if (instagram != null) 'instagram': instagram,
        // ignore: use_null_aware_elements
        if (tiktok != null) 'tiktok': tiktok,
      };

      try {
        await _repository.updateStore(storeId, updateData);
      } on DioException catch (dioErr) {
        final errData = dioErr.response?.data;
        final errMsg = (errData is Map && errData.containsKey('message'))
            ? (errData['message'] is List
                ? (errData['message'] as List).join(', ')
                : errData['message'].toString())
            : '';
        if ((errMsg.contains('property instagram should not exist') ||
                errMsg.contains('property tiktok should not exist')) &&
            (updateData.containsKey('instagram') || updateData.containsKey('tiktok'))) {
          final fallbackData = Map<String, dynamic>.from(updateData)
            ..remove('instagram')
            ..remove('tiktok');
          await _repository.updateStore(storeId, fallbackData);
        } else {
          rethrow;
        }
      }

      if (!ref.mounted) return false;

      await loadData();
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
