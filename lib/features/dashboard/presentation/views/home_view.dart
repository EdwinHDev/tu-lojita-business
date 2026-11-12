import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_attention_banner.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_breakdown_bento_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_filters_bar.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_header_banner.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_image_resolver.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_kpi_carousel.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_operational_card.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_quick_actions_panel.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_sales_trend_chart.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_shimmer_skeleton.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final storesState = ref.watch(storesProvider);
    final unreadDisputesCount =
        ref.watch(unreadBusinessDisputeOrdersCountProvider);

    final user = authState is Authenticated ? authState.user : null;
    final userName = user?.firstName ?? 'Usuario';
    final companyLogoUrl = resolveDashboardImageUrl(user?.company?.logo);
    final canViewFinancials = user?.canViewFinancialMetrics ?? true;
    final isRestrictedCollaborator =
        user != null && user.isCollaborator && !user.hasFullBranchAccess;
    final filteredStores = isRestrictedCollaborator
        ? storesState.stores.where((s) => user.canAccessBranch(s.id)).toList()
        : storesState.stores;

    final analyticsState =
        canViewFinancials ? ref.watch(dashboardAnalyticsProvider) : null;
    final selectedStoreId = analyticsState?.selectedStoreId ?? 'all';

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.canvas,
      body: RefreshIndicator(
        onRefresh: () async {
          final futures = <Future>[
            ref.read(storesProvider.notifier).loadData(),
            ref.read(exchangeRateProvider.notifier).refreshRate(),
            ref.read(notificationsProvider.notifier).loadNotifications(),
          ];
          if (canViewFinancials) {
            futures.add(
              ref
                  .read(dashboardAnalyticsProvider.notifier)
                  .loadAnalytics(isRefresh: true),
            );
          }
          await Future.wait(futures);
        },
        color: TuLojitaBrandColors.indigo600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Single Integrated Header (greeting, clean logo, padded notification bell)
              HomeHeaderBanner(
                userName: userName,
                companyLogoUrl: companyLogoUrl,
                isCollaborator: user?.isCollaborator ?? false,
                collaboratorRole: user?.collaboratorRole,
                activeScopeLabel: user?.company?.name,
              ),
              const SizedBox(height: 14),

              // 2. Modo Operativo Básico (colaboradores sin permiso de métricas monetarias)
              if (!canViewFinancials) ...[
                HomeOperationalCard(
                  user: user,
                  stores: filteredStores,
                  unreadDisputesCount: unreadDisputesCount,
                  onViewStores: () =>
                      ref.read(dashboardIndexProvider.notifier).state = 1,
                ),
                const SizedBox(height: 20),
                HomeQuickActionsPanel(
                  stores: filteredStores,
                  selectedStoreId: 'all',
                ),
              ] else ...[
                // 2. Compact Dropdown Pills + Tasa BCV
                HomeFiltersBar(
                  selectedPeriod: analyticsState!.selectedPeriod,
                  selectedStoreId: analyticsState.selectedStoreId,
                  customStartDate: analyticsState.customStartDate,
                  customEndDate: analyticsState.customEndDate,
                  stores: filteredStores,
                  canSelectAllBranches: !isRestrictedCollaborator,
                  onPeriodSelected: (period) {
                    ref
                        .read(dashboardAnalyticsProvider.notifier)
                        .setPeriod(period);
                  },
                  onStoreSelected: (storeId) {
                    ref
                        .read(dashboardAnalyticsProvider.notifier)
                        .setStoreId(storeId);
                  },
                  onCustomRangeSelected: (start, end) {
                    ref
                        .read(dashboardAnalyticsProvider.notifier)
                        .setCustomDateRange(start, end);
                  },
                ),
                const SizedBox(height: 16),

                // 3. Loading Shimmer / Error / Loaded Bento Sections
                if (analyticsState.status == DashboardAnalyticsStatus.loading &&
                    analyticsState.analytics == null)
                  const HomeShimmerSkeleton()
                else if (analyticsState.status ==
                        DashboardAnalyticsStatus.error &&
                    analyticsState.analytics == null)
                  _buildErrorWidget(ref, analyticsState.errorMessage)
                else if (analyticsState.analytics != null) ...[
                  // 3.1 Conditional Amber 400 Attention Strip
                  HomeAttentionBanner(
                    user: user,
                    pendingOrders: analyticsState.analytics!.kpis.pendingOrders,
                    unreadDisputesCount: unreadDisputesCount,
                    summary: analyticsState.analytics!.operationalSummary,
                    stores: filteredStores,
                    selectedStoreId: selectedStoreId,
                    canViewFinancials: canViewFinancials,
                    margin: const EdgeInsets.only(bottom: 16),
                  ),

                  // 3.2 3-Slide Bento KPI Carousel (or Tablet Multi-Column Grid)
                  HomeKpiCarousel(
                    analytics: analyticsState.analytics!,
                    stores: filteredStores,
                    selectedStoreId: selectedStoreId,
                  ),
                  const SizedBox(height: 20),

                  // 3.3 Early Horizontal Operational Shortcuts Strip
                  HomeQuickActionsPanel(
                    stores: filteredStores,
                    selectedStoreId: selectedStoreId,
                  ),
                  const SizedBox(height: 20),

                  // 3.4 Hybrid Interactive Sales Trend Chart ([Área | Barras])
                  HomeSalesTrendChart(
                    salesChart: analyticsState.analytics!.salesChart,
                    period: analyticsState.selectedPeriod,
                  ),
                  const SizedBox(height: 20),

                  // 3.5 Unified Segmented Breakdown Bento ([Vendidos | Deseados | Métodos | Sedes])
                  HomeBreakdownBentoCard(
                    analytics: analyticsState.analytics!,
                    stores: filteredStores,
                    selectedStoreId: selectedStoreId,
                  ),
                ],
              ],
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(WidgetRef ref, String? error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.dangerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
      ),
      child: Column(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            color: TuLojitaBrandColors.danger,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            error ?? 'No se pudo cargar la información analítica.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(dashboardAnalyticsProvider.notifier).loadAnalytics(),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: Colors.white,
              size: 16,
            ),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TuLojitaBrandColors.indigo600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
