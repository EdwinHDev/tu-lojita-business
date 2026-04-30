import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/stores_notifier.dart';
import '../providers/stores_state.dart';
import '../widgets/store_list_tile.dart';
import '../widgets/store_metric_card.dart';
import '../widgets/store_empty_state.dart';

class StoresView extends ConsumerWidget {
  const StoresView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesState = ref.watch(storesProvider);

    if (storesState.isLoading && storesState.stores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (storesState.errorMessage != null && storesState.stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${storesState.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(storesProvider.notifier).loadData(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (storesState.stores.isEmpty) {
      return StoreEmptyState(
        onCreatePressed: () => context.go('/dashboard/stores/create'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/dashboard/stores/create'),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(storesProvider.notifier).loadData(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Resumen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMetrics(storesState),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Mis Tiendas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final store = storesState.stores[index];
                    return StoreListTile(
                      store: store,
                      onTap: () {
                        context.go('/dashboard/stores/${store.id}');
                      },
                    );
                  },
                  childCount: storesState.stores.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(StoresState storesState) {
    final stats = storesState.stats;
    if (stats == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            StoreMetricCard(
              title: 'Ventas Hoy',
              value: '${stats.salesToday.amount.toStringAsFixed(2)} ${stats.salesToday.currency}',
              icon: HugeIcons.strokeRoundedMoney01,
              color: Colors.green,
              subtitle: '+${stats.salesToday.percentage}%',
            ),
            const SizedBox(width: 12),
            StoreMetricCard(
              title: 'Tiendas',
              value: '${stats.totalStores.count}',
              icon: HugeIcons.strokeRoundedStore01,
              color: Colors.blue,
              subtitle: '+${stats.totalStores.increment} mes',
            ),
            const SizedBox(width: 12),
            StoreMetricCard(
              title: 'Productos',
              value: '${stats.totalProducts.count}',
              icon: HugeIcons.strokeRoundedPackage,
              color: Colors.orange,
              subtitle: '+${stats.totalProducts.increment} sem',
            ),
          ],
        ),
      ),
    );
  }

}

