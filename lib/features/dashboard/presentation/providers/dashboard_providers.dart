import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/stores_repository_impl.dart';
import '../../data/repositories/store_dashboard_repository_impl.dart';
import '../../data/repositories/store_category_repository_impl.dart';
import '../../../items/data/repositories/item_repository_impl.dart';
import '../../domain/repositories/stores_repository.dart';
import '../../domain/repositories/store_dashboard_repository.dart';
import '../../domain/repositories/store_category_repository.dart';
import '../../../items/domain/repositories/item_repository.dart';

final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StoresRepositoryImpl(dio);
});

final storeDashboardRepositoryProvider = Provider<StoreDashboardRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StoreDashboardRepositoryImpl(dio);
});

final storeCategoryRepositoryProvider = Provider<StoreCategoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StoreCategoryRepositoryImpl(dio);
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ItemRepositoryImpl(dio);
});
