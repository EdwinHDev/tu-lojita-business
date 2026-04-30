import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tu_lojita_business/core/network/api_client.dart';
import 'package:tu_lojita_business/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:tu_lojita_business/features/auth/data/datasources/remote_auth_data_source.dart';
import 'package:tu_lojita_business/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tu_lojita_business/features/auth/domain/repositories/auth_repository.dart';
import 'package:tu_lojita_business/features/auth/data/interceptors/auth_interceptor.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localAuthDataSourceProvider = Provider<LocalAuthDataSource>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LocalAuthDataSourceImpl(storage);
});

final dioProvider = Provider<Dio>((ref) {
  final apiClient = ApiClient();
  final localDataSource = ref.watch(localAuthDataSourceProvider);
  
  apiClient.dio.interceptors.add(
    AuthInterceptor(localDataSource, apiClient.dio),
  );
  
  return apiClient.dio;
});

final remoteAuthDataSourceProvider = Provider<RemoteAuthDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return RemoteAuthDataSourceImpl(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(remoteAuthDataSourceProvider);
  final local = ref.watch(localAuthDataSourceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});
