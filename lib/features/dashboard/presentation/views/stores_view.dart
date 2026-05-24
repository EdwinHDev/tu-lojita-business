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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  color: Color(0xFFB91C1C),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ocurrió un error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                storesState.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(storesProvider.notifier).loadData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
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
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 4,
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
          size: 24,
        ),
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
                      'Resumen de hoy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMetrics(storesState),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Mis Sucursales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
      clipBehavior: Clip.none,
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
              subtitle: stats.totalStores.increment > 0 ? '+${stats.totalStores.increment} mes' : null,
            ),
            const SizedBox(width: 12),
            StoreMetricCard(
              title: 'Productos',
              value: '${stats.totalProducts.count}',
              icon: HugeIcons.strokeRoundedPackage,
              color: Colors.orange,
              subtitle: stats.totalProducts.increment > 0 ? '+${stats.totalProducts.increment} sem' : null,
            ),
          ],
        ),
      ),
    );
  }

}

