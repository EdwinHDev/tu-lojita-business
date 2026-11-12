import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item_owner_stats.dart';

/// Fetches per-item commercial performance metrics for the owner detail view.
/// Disables Riverpod 3 exponential retries so HTTP/network errors immediately
/// surface the resilient fallback state instead of stalling on shimmer.
final itemOwnerStatsProvider = FutureProvider.autoDispose.family<ItemOwnerStats, String>(
  (ref, itemId) async {
    final repository = ref.watch(itemRepositoryProvider);
    return repository.getItemOwnerStats(itemId);
  },
  retry: (retryCount, error) => null,
);
