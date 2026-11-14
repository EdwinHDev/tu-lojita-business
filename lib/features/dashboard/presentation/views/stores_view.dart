import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import '../providers/stores_notifier.dart';
import '../providers/stores_state.dart';
import '../widgets/store_empty_state.dart';
import '../widgets/store_list_tile.dart';
import '../widgets/stores/single_store_quick_actions_card.dart';
import '../widgets/stores/stores_filters_bar.dart';
import '../widgets/stores/stores_header_banner.dart';
import '../widgets/stores/stores_shimmer_skeleton.dart';
import '../widgets/stores/stores_summary_bento_card.dart';

class StoresView extends ConsumerStatefulWidget {
  const StoresView({super.key});

  @override
  ConsumerState<StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends ConsumerState<StoresView> {
  StoresFilterOption _selectedFilter = StoresFilterOption.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DashboardStats _effectiveStats(StoresState state, List<Store> stores) {
    if (state.stats != null) return state.stats!;
    final salesTodaySum =
        stores.fold<double>(0.0, (sum, s) => sum + s.salesToday);
    final productsSum =
        stores.fold<int>(0, (sum, s) => sum + s.productsCount);
    return DashboardStats(
      salesToday: SalesStats(
        amount: salesTodaySum,
        percentage: 0,
        currency: 'USD',
      ),
      totalStores: CountStats(count: stores.length, increment: 0),
      totalProducts: CountStats(count: productsSum, increment: 0),
      totalCustomers: const CountStats(count: 0, increment: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesState = ref.watch(storesProvider);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isCollaborator = user?.isCollaborator ?? false;
    final canManageBranches =
        !isCollaborator || (user?.canManageBranches ?? false);
    final canViewFinancials =
        !isCollaborator || (user?.canViewFinancialMetrics ?? false);

    final exchangeConfig = ref.watch(exchangeRateProvider).asData?.value;
    final unreadDisputesByStore =
        ref.watch(unreadBusinessDisputeCountByStoreProvider);

    if (storesState.isLoading && storesState.stores.isEmpty) {
      return const StoresShimmerSkeleton();
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
                  color: TuLojitaBrandColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  color: TuLojitaBrandColors.danger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ocurrió un error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                storesState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TuLojitaBrandColors.inkSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(storesProvider.notifier).loadData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.indigo600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stores = storesState.stores;

    if (stores.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(storesProvider.notifier).loadData(),
          ref.read(exchangeRateProvider.notifier).refreshRate(),
          ref.read(notificationsProvider.notifier).loadNotifications(),
        ]),
        color: TuLojitaBrandColors.indigo600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StoresHeaderBanner(
                storeCount: 0,
                canManageBranches: canManageBranches,
                companyLogo: user?.company?.logo,
                onCreateStore: () => context.go('/dashboard/stores/create'),
              ),
              const SizedBox(height: 12),
              StoreEmptyState(
                canCreateStore: canManageBranches,
                onCreatePressed: () => context.go('/dashboard/stores/create'),
              ),
            ],
          ),
        ),
      );
    }

    final effectiveFilter =
        stores.length >= 2 ? _selectedFilter : StoresFilterOption.all;
    final effectiveQuery = stores.length >= 4 ? _searchQuery : '';
    final filteredStores = applyStoresFilter(
      stores: stores,
      filter: effectiveFilter,
      query: effectiveQuery,
      unreadDisputesByStore: unreadDisputesByStore,
      canViewFinancials: canViewFinancials,
    );

    final stats = _effectiveStats(storesState, stores);

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.canvas,
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(storesProvider.notifier).loadData(),
          ref.read(exchangeRateProvider.notifier).refreshRate(),
          ref.read(notificationsProvider.notifier).loadNotifications(),
        ]),
        color: TuLojitaBrandColors.indigo600,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StoresHeaderBanner(
                      storeCount: stores.length,
                      canManageBranches: canManageBranches,
                      companyLogo: user?.company?.logo,
                      onCreateStore: () =>
                          context.go('/dashboard/stores/create'),
                    ),
                    const SizedBox(height: 14),
                    StoresSummaryBentoCard(
                      stats: stats,
                      stores: stores,
                      unreadDisputesByStore: unreadDisputesByStore,
                      canViewFinancials: canViewFinancials,
                    ),
                    if (stores.length >= 2) ...[
                      const SizedBox(height: 16),
                      StoresFiltersBar(
                        stores: stores,
                        unreadDisputesByStore: unreadDisputesByStore,
                        canViewFinancials: canViewFinancials,
                        selectedFilter: _selectedFilter,
                        onFilterSelected: (opt) {
                          setState(() => _selectedFilter = opt);
                        },
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (filteredStores.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: TuLojitaBrandColors.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedSearch01,
                          color: TuLojitaBrandColors.inkSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ninguna sucursal coincide con el filtro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TuLojitaBrandColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedFilter = StoresFilterOption.all;
                              _searchQuery = '';
                            });
                          },
                          child: const Text(
                            'Limpiar filtros',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TuLojitaBrandColors.indigo600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final store = filteredStores[index];
                      return StoreListTile(
                        store: store,
                        exchangeConfig: exchangeConfig,
                        unreadDisputesCount:
                            unreadDisputesByStore[store.id] ?? 0,
                        canViewFinancials: canViewFinancials,
                        fallbackLogo: user?.company?.logo,
                        onTap: () => context.go('/dashboard/stores/${store.id}'),
                      );
                    },
                    childCount: filteredStores.length,
                  ),
                ),
              ),
            if (stores.length == 1)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: SingleStoreQuickActionsCard(
                    store: stores.first,
                    user: user,
                    unreadDisputesCount:
                        unreadDisputesByStore[stores.first.id] ?? 0,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}
