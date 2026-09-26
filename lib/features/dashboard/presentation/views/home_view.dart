import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_analytics_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/ranking/presentation/widgets/store_rank_header_card.dart';
import 'package:tu_lojita_business/features/ranking/presentation/widgets/daily_missions_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final analyticsState = ref.watch(dashboardAnalyticsProvider);
    final storesState = ref.watch(storesProvider);

    String userName = 'Usuario';
    String companyLogoUrl = '';
    if (authState is Authenticated) {
      userName = authState.user.firstName;
      final company = authState.user.company;
      if (company != null && company.logo.isNotEmpty) {
        companyLogoUrl = company.logo.startsWith('http')
            ? company.logo
            : '${Envs.apiBaseUrlImages}/${company.logo.startsWith('/') ? company.logo.substring(1) : company.logo}';
      }
    }

    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(dashboardAnalyticsProvider.notifier).loadAnalytics(isRefresh: true),
            ref.read(storesProvider.notifier).loadData(),
          ]);
        },
        color: const Color(0xFF4F46E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              _buildHeader(userName, companyLogoUrl),
              const SizedBox(height: 16),

              // Rango & Retención Comercial Gamificada
              if (storesState.stores.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final activeStoreId = (analyticsState.selectedStoreId != 'all' &&
                            analyticsState.selectedStoreId.isNotEmpty)
                        ? analyticsState.selectedStoreId
                        : storesState.stores.first.id;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StoreRankHeaderCard(storeId: activeStoreId),
                        const SizedBox(height: 16),
                        DailyMissionsCard(storeId: activeStoreId),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ],

              // 2. Multi-temporal & Branch Filters Bar
              _BranchAndPeriodFilters(
                selectedPeriod: analyticsState.selectedPeriod,
                selectedStoreId: analyticsState.selectedStoreId,
                customStartDate: analyticsState.customStartDate,
                customEndDate: analyticsState.customEndDate,
                stores: storesState.stores,
                onPeriodSelected: (period) {
                  ref.read(dashboardAnalyticsProvider.notifier).setPeriod(period);
                },
                onStoreSelected: (storeId) {
                  ref.read(dashboardAnalyticsProvider.notifier).setStoreId(storeId);
                },
                onCustomRangeSelected: (start, end) {
                  ref.read(dashboardAnalyticsProvider.notifier).setCustomDateRange(start, end);
                },
              ),
              const SizedBox(height: 24),

              // 3. Analytics KPI Metrics Grid
              if (analyticsState.status == DashboardAnalyticsStatus.loading &&
                  analyticsState.analytics == null)
                _buildLoadingShimmer()
              else if (analyticsState.status == DashboardAnalyticsStatus.error &&
                  analyticsState.analytics == null)
                _buildErrorWidget(ref, analyticsState.errorMessage)
              else if (analyticsState.analytics != null) ...[
                _KpiCardsGrid(
                  kpis: analyticsState.analytics!.kpis,
                  currencyFormatter: currencyFormatter,
                ),
                const SizedBox(height: 28),

                // 4. Sales Trend Timeline Chart
                if (analyticsState.analytics!.salesChart.isNotEmpty) ...[
                  _SalesTrendChartSection(
                    salesChart: analyticsState.analytics!.salesChart,
                    currencyFormatter: currencyFormatter,
                    period: analyticsState.selectedPeriod,
                  ),
                  const SizedBox(height: 28),
                ],

                // 5. Branch Office Performance (if more than 1 store or all selected)
                if (analyticsState.selectedStoreId == 'all' &&
                    analyticsState.analytics!.storesPerformance.isNotEmpty) ...[
                  _BranchPerformanceSection(
                    performanceList: analyticsState.analytics!.storesPerformance,
                    currencyFormatter: currencyFormatter,
                  ),
                  const SizedBox(height: 28),
                ],

                // 6. Top 5 Best-Selling Products
                if (analyticsState.analytics!.topProducts.isNotEmpty) ...[
                  _TopProductsSection(
                    topProducts: analyticsState.analytics!.topProducts,
                    currencyFormatter: currencyFormatter,
                  ),
                  const SizedBox(height: 28),
                ],

                // 7. Payment Methods Distribution
                if (analyticsState.analytics!.paymentMethods.isNotEmpty) ...[
                  _PaymentMethodsSection(
                    paymentMethods: analyticsState.analytics!.paymentMethods,
                    currencyFormatter: currencyFormatter,
                  ),
                  const SizedBox(height: 28),
                ],
              ],

              // 8. Quick Actions Panel
              _QuickActionsPanel(ref: ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String companyLogoUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $userName! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rendimiento y control de ventas en tiempo real.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (companyLogoUrl.isNotEmpty)
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              image: DecorationImage(
                image: NetworkImage(companyLogoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2.5),
          SizedBox(height: 14),
          Text(
            'Cargando analítica en tiempo real...',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(WidgetRef ref, String? error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
      ),
      child: Column(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlertCircle,
            color: Color(0xFFEF4444),
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
            onPressed: () => ref.read(dashboardAnalyticsProvider.notifier).loadAnalytics(),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: Colors.white, size: 16),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// FILTERS BAR (Sucursal + Períodos: Hoy, Semana, Mes, etc.)
/// ---------------------------------------------------------
class _BranchAndPeriodFilters extends StatelessWidget {
  final String selectedPeriod;
  final String selectedStoreId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final List<dynamic> stores;
  final ValueChanged<String> onPeriodSelected;
  final ValueChanged<String> onStoreSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;

  const _BranchAndPeriodFilters({
    required this.selectedPeriod,
    required this.selectedStoreId,
    required this.customStartDate,
    required this.customEndDate,
    required this.stores,
    required this.onPeriodSelected,
    required this.onStoreSelected,
    required this.onCustomRangeSelected,
  });

  String get _selectedStoreLabel {
    if (selectedStoreId == 'all') return 'Todas las sucursales';
    final store = stores.where((s) => s.id == selectedStoreId).firstOrNull;
    if (store != null) {
      return store.branchName.isNotEmpty ? '${store.name} (${store.branchName})' : store.name;
    }
    return 'Sucursal seleccionada';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de Sucursal
        InkWell(
          onTap: () => _showStoreSelectorModal(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: Color(0xFF4F46E5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alcance de Tienda',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          textBaseline: TextBaseline.alphabetic,
                        ),
                      ),
                      Text(
                        _selectedStoreLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Carrusel Horizontal de Períodos
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildPeriodChip('today', 'Hoy', HugeIcons.strokeRoundedClock01),
              _buildPeriodChip('week', 'Esta Semana', HugeIcons.strokeRoundedCalendar03),
              _buildPeriodChip('month', 'Este Mes', HugeIcons.strokeRoundedCalendar01),
              _buildPeriodChip('six_months', '6 Meses', HugeIcons.strokeRoundedAnalytics01),
              _buildPeriodChip('year', 'Este Año', HugeIcons.strokeRoundedChartLineData02),
              _buildCustomDateRangeChip(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String periodKey, String label, dynamic icon) {
    final isSelected = selectedPeriod == periodKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: HugeIcon(
          icon: icon,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          size: 15,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF4F46E5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        onSelected: (_) => onPeriodSelected(periodKey),
      ),
    );
  }

  Widget _buildCustomDateRangeChip(BuildContext context) {
    final isSelected = selectedPeriod == 'custom';
    String label = 'Rango 📅';
    if (isSelected && customStartDate != null && customEndDate != null) {
      final f = DateFormat('dd MMM', 'es');
      label = '${f.format(customStartDate!)} - ${f.format(customEndDate!)}';
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: HugeIcon(
          icon: HugeIcons.strokeRoundedCalendarAdd01,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          size: 15,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
        backgroundColor: isSelected ? const Color(0xFF4F46E5) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        onPressed: () async {
          final now = DateTime.now();
          final initialRange = DateTimeRange(
            start: customStartDate ?? now.subtract(const Duration(days: 15)),
            end: customEndDate ?? now,
          );

          final result = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024, 1, 1),
            lastDate: now.add(const Duration(days: 1)),
            initialDateRange: initialRange,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF4F46E5),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1E293B),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (result != null) {
            onCustomRangeSelected(result.start, result.end);
          }
        },
      ),
    );
  }

  void _showStoreSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrar por Sucursal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF2FF),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Color(0xFF4F46E5)),
                  ),
                  title: const Text(
                    'Todas las sucursales',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text('Consolidado de toda la empresa'),
                  trailing: selectedStoreId == 'all'
                      ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5))
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    onStoreSelected('all');
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                ...stores.map((store) {
                  final isSelected = selectedStoreId == store.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF1F5F9),
                      backgroundImage: store.logo.isNotEmpty ? NetworkImage(store.logo) : null,
                      child: store.logo.isEmpty
                          ? const HugeIcon(icon: HugeIcons.strokeRoundedStore01, color: Color(0xFF64748B))
                          : null,
                    ),
                    title: Text(
                      store.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(store.branchName.isNotEmpty ? store.branchName : 'Sede principal'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5))
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      onStoreSelected(store.id);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------
/// KPI CARDS GRID (Ventas, Cobrado, Por Cobrar, Órdenes, etc)
/// ---------------------------------------------------------
class _KpiCardsGrid extends StatelessWidget {
  final KpiMetrics kpis;
  final NumberFormat currencyFormatter;

  const _KpiCardsGrid({
    required this.kpis,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final salesGrowth = kpis.growth.salesGrowthPercentage;
    final growthBadge = salesGrowth >= 0 ? '+${salesGrowth.toStringAsFixed(1)}%' : '${salesGrowth.toStringAsFixed(1)}%';
    final isPositive = salesGrowth >= 0;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.14,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        // 1. Ventas Totales
        _MetricCard(
          title: 'Ventas Totales',
          value: currencyFormatter.format(kpis.totalSales),
          icon: HugeIcons.strokeRoundedMoney01,
          badgeText: growthBadge,
          badgeColor: isPositive ? const Color(0xFF047857) : const Color(0xFFDC2626),
          badgeBgColor: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          accentColor: const Color(0xFF047857),
          accentBgColor: const Color(0xFFECFDF5),
        ),

        // 2. Ingresos Recaudados (Bancos)
        _MetricCard(
          title: 'Recaudado en Bancos',
          value: currencyFormatter.format(kpis.totalCollected),
          icon: HugeIcons.strokeRoundedBank,
          badgeText: 'Cobrado',
          badgeColor: const Color(0xFF1D4ED8),
          badgeBgColor: const Color(0xFFEFF6FF),
          accentColor: const Color(0xFF1D4ED8),
          accentBgColor: const Color(0xFFEFF6FF),
        ),

        // 3. Saldo por Cobrar (Cuotas)
        _MetricCard(
          title: 'Por Cobrar (Cuotas)',
          value: currencyFormatter.format(kpis.accountsReceivable),
          icon: HugeIcons.strokeRoundedHourglass,
          badgeText: 'Cartera activa',
          badgeColor: const Color(0xFFC2410C),
          badgeBgColor: const Color(0xFFFFF7ED),
          accentColor: const Color(0xFFC2410C),
          accentBgColor: const Color(0xFFFFF7ED),
        ),

        // 4. Total de Órdenes
        _MetricCard(
          title: 'Total Pedidos',
          value: '${kpis.totalOrders}',
          icon: HugeIcons.strokeRoundedPackage,
          badgeText: '${kpis.completedOrders} pagadas',
          badgeColor: const Color(0xFF7E22CE),
          badgeBgColor: const Color(0xFFFAF5FF),
          accentColor: const Color(0xFF7E22CE),
          accentBgColor: const Color(0xFFFAF5FF),
        ),

        // 5. Ticket Promedio
        _MetricCard(
          title: 'Ticket Promedio',
          value: currencyFormatter.format(kpis.averageTicket),
          icon: HugeIcons.strokeRoundedTarget01,
          badgeText: 'Por pedido',
          badgeColor: const Color(0xFF0F766E),
          badgeBgColor: const Color(0xFFF0FDFA),
          accentColor: const Color(0xFF0F766E),
          accentBgColor: const Color(0xFFF0FDFA),
        ),

        // 6. Modalidad en Cuotas
        _MetricCard(
          title: '% en Cuotas',
          value: '${kpis.installmentRatio.installmentPercentage.toStringAsFixed(0)}%',
          icon: HugeIcons.strokeRoundedCreditCard,
          badgeText: '${kpis.installmentRatio.singlePaymentPercentage.toStringAsFixed(0)}% único',
          badgeColor: const Color(0xFF4338CA),
          badgeBgColor: const Color(0xFFEEF2FF),
          accentColor: const Color(0xFF4338CA),
          accentBgColor: const Color(0xFFEEF2FF),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final dynamic icon;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;
  final Color accentColor;
  final Color accentBgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.accentColor,
    required this.accentBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentBgColor,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: icon,
                  color: accentColor,
                  size: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// GRÁFICO DE TENDENCIA DE VENTAS
/// ---------------------------------------------------------
class _SalesTrendChartSection extends StatelessWidget {
  final List<SalesChartPoint> salesChart;
  final NumberFormat currencyFormatter;
  final String period;

  const _SalesTrendChartSection({
    required this.salesChart,
    required this.currencyFormatter,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final maxSales = salesChart.fold<double>(
      0.0,
      (max, p) => p.sales > max ? p.sales : max,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Evolución de Ventas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedAnalytics01, color: Color(0xFF4F46E5), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Pico: ${currencyFormatter.format(maxSales)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfico de Barras Responsivo
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: salesChart.map((point) {
                final heightFactor = maxSales > 0 ? (point.sales / maxSales).clamp(0.06, 1.0) : 0.06;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Tooltip(
                          message: '${point.label}: ${currencyFormatter.format(point.sales)} (${point.ordersCount} pedidos)',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            height: 100 * heightFactor,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            point.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// RENDIMIENTO POR SUCURSAL
/// ---------------------------------------------------------
class _BranchPerformanceSection extends StatelessWidget {
  final List<StorePerformance> performanceList;
  final NumberFormat currencyFormatter;

  const _BranchPerformanceSection({
    required this.performanceList,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rendimiento por Sucursal',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: performanceList.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedStore01,
                                color: Color(0xFF4F46E5),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormatter.format(item.totalSales),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (item.percentageOfTotal / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEEF2FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${item.percentageOfTotal.toStringAsFixed(1)}% (${item.ordersCount} ped)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// TOP 5 PRODUCTOS MÁS VENDIDOS
/// ---------------------------------------------------------
class _TopProductsSection extends StatelessWidget {
  final List<TopProduct> topProducts;
  final NumberFormat currencyFormatter;

  const _TopProductsSection({
    required this.topProducts,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Productos Más Vendidos',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final prod = entry.value;
              final isLast = index == topProducts.length - 1;

              final imageUrl = prod.mainImage != null && prod.mainImage!.isNotEmpty
                  ? (prod.mainImage!.startsWith('http')
                      ? prod.mainImage!
                      : '${Envs.apiBaseUrlImages}/${prod.mainImage!.startsWith('/') ? prod.mainImage!.substring(1) : prod.mainImage}')
                  : '';

              return Container(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12.0, top: index == 0 ? 0 : 12.0),
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    // Rank position badge
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: index == 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Image thumbnail
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const HugeIcon(icon: HugeIcons.strokeRoundedPackage, color: Color(0xFF94A3B8), size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${prod.unitsSold} unid. vendidas',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    // Total revenue
                    Text(
                      currencyFormatter.format(prod.totalRevenue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// DISTRIBUCIÓN POR MÉTODO DE PAGO
/// ---------------------------------------------------------
class _PaymentMethodsSection extends StatelessWidget {
  final List<PaymentMethodShare> paymentMethods;
  final NumberFormat currencyFormatter;

  const _PaymentMethodsSection({
    required this.paymentMethods,
    required this.currencyFormatter,
  });

  dynamic _getMethodIcon(String method) {
    if (method == 'PAGO_MOVIL') return HugeIcons.strokeRoundedSmartPhone01;
    if (method == 'TRANSFER') return HugeIcons.strokeRoundedBank;
    if (method == 'BINANCE') return HugeIcons.strokeRoundedBitcoin01;
    if (method == 'ZELLE') return HugeIcons.strokeRoundedMoney01;
    return HugeIcons.strokeRoundedCreditCard;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cobros por Método de Pago',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: paymentMethods.map((pm) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            HugeIcon(icon: _getMethodIcon(pm.method), color: const Color(0xFF4F46E5), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              pm.label,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                        Text(
                          currencyFormatter.format(pm.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (pm.percentage / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEEF2FF),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${pm.percentage.toStringAsFixed(1)}% (${pm.transactionCount} pagos)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// QUICK ACTIONS PANEL
/// ---------------------------------------------------------
class _QuickActionsPanel extends StatelessWidget {
  final WidgetRef ref;

  const _QuickActionsPanel({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos Rápidos',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 14),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          children: [
            _QuickActionCard(
              title: 'Nueva Sucursal',
              subtitle: 'Crear sedes físicas/virtuales',
              icon: HugeIcons.strokeRoundedAdd01,
              onTap: () => context.go('/dashboard/stores/create'),
            ),
            _QuickActionCard(
              title: 'Notificaciones',
              subtitle: 'Revisar alertas activas',
              icon: HugeIcons.strokeRoundedNotification01,
              onTap: () => context.go('/dashboard/notifications'),
            ),
            _QuickActionCard(
              title: 'Ajustes Empresa',
              subtitle: 'Editar detalles generales',
              icon: HugeIcons.strokeRoundedSettings01,
              onTap: () => context.go('/dashboard/settings/company'),
            ),
            _QuickActionCard(
              title: 'Ajustes de Perfil',
              subtitle: 'Gestionar mi cuenta',
              icon: HugeIcons.strokeRoundedUser02,
              onTap: () => ref.read(dashboardIndexProvider.notifier).state = 2,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: icon,
                color: const Color(0xFF4F46E5),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: Color(0xFF4F46E5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
