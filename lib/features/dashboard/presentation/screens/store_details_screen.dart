import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../../ranking/presentation/widgets/daily_missions_card.dart';
import '../../../ranking/presentation/widgets/store_rank_header_card.dart';
import '../../../store_ai/presentation/providers/store_ai_providers.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/store_dashboard.dart';
import '../../../auth/domain/entities/user.dart';
import '../providers/notifications_provider.dart';
import '../providers/store_details_notifier.dart';
import '../widgets/home/home_image_resolver.dart';
import '../widgets/store_details/store_details_activity_section.dart';
import '../widgets/store_details/store_details_identity_card.dart';
import '../widgets/store_details/store_details_management_sheet.dart';
import '../widgets/store_details/store_details_metrics_bento.dart';
import '../widgets/store_details/store_readiness_checklist_card.dart';
import '../widgets/store_details/store_scheduled_deletion_card.dart';
import '../widgets/store_details/store_suspension_banner_card.dart';
import '../widgets/store_details/store_urgent_alerts_strip.dart';
import '../widgets/store_details_skeletons.dart';
import 'settings/store_health_sheet.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final collapsed = _scrollController.offset > 88;
    if (collapsed != _isCollapsed && mounted) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeDetailsProvider).forStore(widget.storeId);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    final isCollab = user?.isCollaborator ?? false;
    final canViewFinancials =
        !isCollab || (user != null && user.canViewFinancialMetrics);
    final canViewSales =
        !isCollab || (user != null && user.canViewSalesHistory);
    final canViewOrders = !isCollab ||
        (user != null && (user.canViewOrders || user.canProcessOrders));
    final canManageBranches =
        !isCollab || (user != null && user.canManageBranches);
    final canViewOperationalKpis = canViewOrders ||
        !isCollab ||
        (user != null &&
            (user.canEditProducts ||
                user.canManageStock ||
                user.canChangePrices ||
                user.canManageBranches));

    final unreadDisputesByStore =
        ref.watch(unreadBusinessDisputeCountByStoreProvider);
    final unreadDisputesCount = unreadDisputesByStore[widget.storeId] ?? 0;
    final isGlobalAiEnabled =
        ref.watch(platformAiGlobalEnabledProvider).value ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.store == null && !state.isLoading && state.errorMessage == null) {
        ref.read(storeDetailsProvider.notifier).loadData(widget.storeId);
      }
    });

    final store = state.store;
    final coverUrl = resolveDashboardImageUrl(store?.coverImage);

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.canvas,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(platformAiGlobalEnabledProvider);
            await Future.wait([
              ref.read(storeDetailsProvider.notifier).refresh(widget.storeId),
              ref.read(exchangeRateProvider.notifier).refreshRate(),
            ]);
          },
          color: TuLojitaBrandColors.indigo600,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(
                context,
                store: store,
                stats: state.dashboard?.stats,
                user: user,
                unreadDisputesCount: unreadDisputesCount,
                isGlobalAiEnabled: isGlobalAiEnabled,
                coverUrl: coverUrl,
              ),

              // 1. Identity Card / Skeleton / Error Retry
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _buildIdentityContent(store, state),
                ),
              ),

              // 2. Scheduled Deletion Recovery Banner
              if (store != null && store.isScheduledForDeletion)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: StoreScheduledDeletionCard(
                      store: store,
                      canManageLifecycle: canManageBranches,
                    ),
                  ),
                ),

              // 2b. Store Suspension & Reactivation Bento Card
              if (store != null && store.status.toUpperCase() == 'SUSPENDED')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: StoreSuspensionBannerCard(
                      store: store,
                      stats: state.dashboard?.stats,
                      canViewFinancials: canViewFinancials,
                      onTapPayAndReactivate: () => context.push(
                        '/dashboard/stores/${widget.storeId}/debts',
                      ),
                      onOpenHealthSheet: () =>
                          StoreHealthSheet.show(context, widget.storeId),
                    ),
                  ),
                ),

              // 3. Urgent Branch Alerts Strip
              if (store != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: StoreUrgentAlertsStrip(
                      store: store,
                      stats: state.dashboard?.stats,
                      user: user,
                      unreadDisputesCount: unreadDisputesCount,
                      onOpenHealthSheet: () =>
                          StoreHealthSheet.show(context, widget.storeId),
                    ),
                  ),
                ),

              // 4. Branch Setup Readiness Checklist (active unconfigured stores)
              if (store != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: StoreReadinessChecklistCard(
                      store: store,
                      dashboard: state.dashboard,
                      user: user,
                    ),
                  ),
                ),

              // 5. Permission-Adaptive Bento KPI Metrics
              if (canViewFinancials || canViewOperationalKpis)
                SliverToBoxAdapter(
                  child: state.dashboard != null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: StoreDetailsMetricsBento(
                            stats: state.dashboard!.stats,
                            canViewFinancials: canViewFinancials,
                            canViewOrders: canViewOrders,
                            onTapPendingOrders: canViewOrders
                                ? () => context.push(
                                      '/dashboard/stores/${widget.storeId}/orders',
                                    )
                                : null,
                            onTapItems: () => context.push(
                              '/dashboard/stores/${widget.storeId}/items',
                            ),
                            onTapCategories: () => context.push(
                              '/dashboard/stores/${widget.storeId}/categories',
                            ),
                          ),
                        )
                      : const StoreMetricsSkeleton(),
                ),

              // 6. Store Ranking Progression & Daily Missions directly beneath Métricas Clave
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StoreRankHeaderCard(storeId: widget.storeId),
                      const SizedBox(height: 12),
                      DailyMissionsCard(storeId: widget.storeId),
                    ],
                  ),
                ),
              ),

              // 8. Live Activity Feed: Pending Orders & Recent Sales
              if (canViewOrders || canViewSales)
                SliverToBoxAdapter(
                  child: state.dashboard != null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: StoreDetailsActivitySection(
                            storeId: widget.storeId,
                            dashboard: state.dashboard!,
                            canViewOrders: canViewOrders,
                            canViewSales: canViewSales,
                            canViewFinancials: canViewFinancials,
                          ),
                        )
                      : (canViewSales
                          ? const StoreRecentSalesSkeleton()
                          : const SizedBox.shrink()),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 36)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityContent(Store? store, StoreDetailsData state) {
    if (store != null) {
      return StoreDetailsIdentityCard(
        store: store,
        dashboardTotalItems: state.dashboard?.stats.totalItems,
      );
    }

    if (state.errorMessage != null && !state.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
              icon: HugeIcons.strokeRoundedAlertCircle,
              color: TuLojitaBrandColors.danger,
              size: 28,
            ),
            const SizedBox(height: 8),
            const Text(
              'No pudimos cargar la sucursal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: TuLojitaBrandColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(storeDetailsProvider.notifier).refresh(widget.storeId),
              style: ElevatedButton.styleFrom(
                backgroundColor: TuLojitaBrandColors.indigo600,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return const StoreHeaderCardSkeleton();
  }

  Widget _buildSliverAppBar(
    BuildContext context, {
    required Store? store,
    required StoreStats? stats,
    required User? user,
    required int unreadDisputesCount,
    required bool isGlobalAiEnabled,
    required String coverUrl,
  }) {
    final titleText =
        store != null ? (store.shouldShowBranch ? store.branchLabel : store.name) : '';
    final hasUrgentAttention = store != null &&
        StoreDetailsManagementSheet.hasAttentionAlerts(
          store: store,
          stats: stats,
          user: user,
          unreadDisputesCount: unreadDisputesCount,
        );

    return SliverAppBar(
      pinned: true,
      expandedHeight: 148,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: TuLojitaBrandColors.indigo600,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Volver',
            padding: EdgeInsets.zero,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _isCollapsed && titleText.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        child: Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        if (store != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Material(
              color: Colors.black.withValues(alpha: 0.35),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Compartir enlace público',
                padding: EdgeInsets.zero,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedShare01,
                  color: Colors.white,
                  size: 19,
                ),
                onPressed: () {
                  final publicUrl = 'https://tulojita.com/tienda/${store.id}';
                  Clipboard.setData(ClipboardData(text: publicUrl));
                  NotificationService.showSuccess(
                    context,
                    'Enlace público de tu tienda copiado',
                  );
                },
              ),
            ),
          ),
        if (store != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Gestión y configuración de sucursal',
                    padding: EdgeInsets.zero,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedSettings01,
                      color: Colors.white,
                      size: 19,
                    ),
                    onPressed: () => StoreDetailsManagementSheet.show(
                      context,
                      store: store,
                      stats: stats,
                      user: user,
                      unreadDisputesCount: unreadDisputesCount,
                      isGlobalAiEnabled: isGlobalAiEnabled,
                      onOpenHealthSheet: () {
                        if (mounted) {
                          StoreHealthSheet.show(this.context, widget.storeId);
                        }
                      },
                    ),
                  ),
                ),
                if (hasUrgentAttention)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey('gear_attention_dot'),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: TuLojitaBrandColors.amber400,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TuLojitaBrandColors.indigo600,
                    TuLojitaBrandColors.indigo700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (coverUrl.isNotEmpty)
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.36),
                    Colors.black.withValues(alpha: 0.12),
                    TuLojitaBrandColors.indigo700.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
