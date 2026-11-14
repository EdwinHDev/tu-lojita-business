import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../data/repositories/crm_repository.dart';
import '../../domain/entities/crm_entities.dart';

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CrmRepository(dio);
});

class _NullableStringNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

class _StringNotifier extends Notifier<String> {
  final String initial;
  _StringNotifier(this.initial);

  @override
  String build() => initial;

  @override
  set state(String value) => super.state = value;
}

final crmSelectedStoreIdProvider =
    NotifierProvider<_NullableStringNotifier, String?>(
  _NullableStringNotifier.new,
);

final crmSearchQueryProvider = NotifierProvider<_StringNotifier, String>(
  () => _StringNotifier(''),
);

final crmSelectedSegmentProvider =
    NotifierProvider<_NullableStringNotifier, String?>(
  _NullableStringNotifier.new,
);

final crmSortByProvider = NotifierProvider<_StringNotifier, String>(
  () => _StringNotifier('ltv'),
);

final crmSummaryProvider = FutureProvider.autoDispose<CrmSummary?>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated || !authState.user.canAccessCrm) {
    return null;
  }
  final companyId = authState.user.company?.id;
  if (companyId == null || companyId.isEmpty) return null;

  final storeId = ref.watch(crmSelectedStoreIdProvider);
  return ref.read(crmRepositoryProvider).getSummary(
        companyId,
        storeId: storeId,
      );
});

final crmCustomersProvider =
    FutureProvider.autoDispose<List<CrmCustomer>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated || !authState.user.canAccessCrm) {
    return [];
  }
  final companyId = authState.user.company?.id;
  if (companyId == null || companyId.isEmpty) return [];

  final storeId = ref.watch(crmSelectedStoreIdProvider);
  final search = ref.watch(crmSearchQueryProvider);
  final segment = ref.watch(crmSelectedSegmentProvider);
  final sortBy = ref.watch(crmSortByProvider);

  return ref.read(crmRepositoryProvider).getCustomers(
        companyId,
        storeId: storeId,
        search: search,
        segment: segment,
        sortBy: sortBy,
      );
});

final crmCustomerDetailProvider =
    FutureProvider.autoDispose.family<CrmCustomerDetail, String>((ref, customerId) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) {
    throw Exception('Sesión requerida');
  }
  final companyId = authState.user.company?.id ?? '';
  final storeId = ref.watch(crmSelectedStoreIdProvider);
  return ref.read(crmRepositoryProvider).getCustomerDetail(
        companyId,
        customerId,
        storeId: storeId,
      );
});

final crmOffersConfigProvider =
    FutureProvider.autoDispose<CrmOffersConfig>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState is! Authenticated) {
    throw Exception('Sesión requerida');
  }
  final companyId = authState.user.company?.id ?? '';
  return ref.read(crmRepositoryProvider).getOffersConfig(companyId);
});
