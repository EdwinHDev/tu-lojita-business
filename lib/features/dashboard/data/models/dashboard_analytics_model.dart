import '../../domain/entities/dashboard_analytics.dart';

class DashboardAnalyticsModel extends DashboardAnalytics {
  const DashboardAnalyticsModel({
    required super.period,
    required super.startDate,
    required super.endDate,
    required super.storeId,
    required super.currency,
    required super.kpis,
    required super.salesChart,
    required super.storesPerformance,
    required super.topProducts,
    super.topDesiredProducts = const [],
    required super.paymentMethods,
    super.operationalSummary = const OperationalSummary(),
  });

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  factory DashboardAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final kpisJson = _asMap(json['kpis']);
    final ratioJson = _asMap(kpisJson['installmentRatio']);
    final growthJson = _asMap(kpisJson['growth']);

    final kpis = KpiMetrics(
      totalSales: double.tryParse(kpisJson['totalSales']?.toString() ?? '0') ?? 0.0,
      totalCollected: double.tryParse(kpisJson['totalCollected']?.toString() ?? '0') ?? 0.0,
      accountsReceivable: double.tryParse(kpisJson['accountsReceivable']?.toString() ?? '0') ?? 0.0,
      totalOrders: int.tryParse(kpisJson['totalOrders']?.toString() ?? '0') ?? 0,
      completedOrders: int.tryParse(kpisJson['completedOrders']?.toString() ?? '0') ?? 0,
      pendingOrders: int.tryParse(kpisJson['pendingOrders']?.toString() ?? '0') ?? 0,
      averageTicket: double.tryParse(kpisJson['averageTicket']?.toString() ?? '0') ?? 0.0,
      installmentRatio: InstallmentRatio(
        installmentOrdersCount: int.tryParse(ratioJson['installmentOrdersCount']?.toString() ?? '0') ?? 0,
        singlePaymentOrdersCount: int.tryParse(ratioJson['singlePaymentOrdersCount']?.toString() ?? '0') ?? 0,
        installmentPercentage: double.tryParse(ratioJson['installmentPercentage']?.toString() ?? '0') ?? 0.0,
        singlePaymentPercentage: double.tryParse(ratioJson['singlePaymentPercentage']?.toString() ?? '0') ?? 0.0,
      ),
      growth: GrowthMetrics(
        salesGrowthPercentage: double.tryParse(growthJson['salesGrowthPercentage']?.toString() ?? '0') ?? 0.0,
        ordersGrowthPercentage: double.tryParse(growthJson['ordersGrowthPercentage']?.toString() ?? '0') ?? 0.0,
      ),
    );

    final salesChart = (json['salesChart'] as List<dynamic>? ?? [])
        .map((p) => SalesChartPoint(
              label: p['label']?.toString() ?? '',
              date: p['date']?.toString() ?? '',
              sales: double.tryParse(p['sales']?.toString() ?? '0') ?? 0.0,
              ordersCount: int.tryParse(p['ordersCount']?.toString() ?? '0') ?? 0,
            ))
        .toList();

    final storesPerformance = (json['storesPerformance'] as List<dynamic>? ?? [])
        .map((s) => StorePerformance(
              storeId: s['storeId']?.toString() ?? '',
              storeName: s['storeName']?.toString() ?? '',
              totalSales: double.tryParse(s['totalSales']?.toString() ?? '0') ?? 0.0,
              ordersCount: int.tryParse(s['ordersCount']?.toString() ?? '0') ?? 0,
              percentageOfTotal: double.tryParse(s['percentageOfTotal']?.toString() ?? '0') ?? 0.0,
            ))
        .toList();

    final topProducts = (json['topProducts'] as List<dynamic>? ?? [])
        .map((tp) => TopProduct(
              itemId: tp['itemId']?.toString() ?? '',
              title: tp['title']?.toString() ?? '',
              mainImage: tp['mainImage']?.toString(),
              unitsSold: int.tryParse(tp['unitsSold']?.toString() ?? '0') ?? 0,
              totalRevenue: double.tryParse(tp['totalRevenue']?.toString() ?? '0') ?? 0.0,
              storeId: tp['storeId']?.toString(),
              storeName: tp['storeName']?.toString(),
            ))
        .toList();

    final paymentMethods = (json['paymentMethods'] as List<dynamic>? ?? [])
        .map((pm) => PaymentMethodShare(
              method: pm['method']?.toString() ?? '',
              label: pm['label']?.toString() ?? '',
              totalAmount: double.tryParse(pm['totalAmount']?.toString() ?? '0') ?? 0.0,
              percentage: double.tryParse(pm['percentage']?.toString() ?? '0') ?? 0.0,
              transactionCount: int.tryParse(pm['transactionCount']?.toString() ?? '0') ?? 0,
            ))
        .toList();

    final topDesiredProducts = (json['topDesiredProducts'] as List<dynamic>? ?? [])
        .map((td) => TopDesiredProduct(
              itemId: td['itemId']?.toString() ?? '',
              title: td['title']?.toString() ?? '',
              mainImage: td['mainImage']?.toString(),
              favoritesCount: int.tryParse(td['favoritesCount']?.toString() ?? '0') ?? 0,
              price: double.tryParse(td['price']?.toString() ?? '0') ?? 0.0,
              stockQuantity: td['stockQuantity'] != null
                  ? double.tryParse(td['stockQuantity']?.toString() ?? '0')
                  : null,
              trackInventory: td['trackInventory'] == true,
              hasVariants: td['hasVariants'] == true,
              storeId: td['storeId']?.toString(),
              storeName: td['storeName']?.toString(),
            ))
        .toList();

    final opRaw = json['operationalSummary'];
    final opMap = opRaw is Map ? Map<String, dynamic>.from(opRaw) : null;
    final storeAlertsRaw = opMap?['storeAlerts'] as List<dynamic>? ?? const [];
    final storeAlerts = storeAlertsRaw
        .whereType<Map>()
        .map((raw) {
          final sa = Map<String, dynamic>.from(raw);
          return StoreOperationalAlert(
            storeId: sa['storeId']?.toString() ?? '',
            storeName: sa['storeName']?.toString() ?? '',
            pendingOrders:
                int.tryParse(sa['pendingOrders']?.toString() ?? '0') ?? 0,
            accountsReceivable: double.tryParse(
                  sa['accountsReceivable']?.toString() ?? '0',
                ) ??
                0.0,
            commissionDebt:
                double.tryParse(sa['commissionDebt']?.toString() ?? '0') ?? 0.0,
            pendingCommissionReportsCount: int.tryParse(
                  sa['pendingCommissionReportsCount']?.toString() ?? '0',
                ) ??
                0,
            activePromotionsCount: int.tryParse(
                  sa['activePromotionsCount']?.toString() ?? '0',
                ) ??
                0,
            pendingPromotionsCount: int.tryParse(
                  sa['pendingPromotionsCount']?.toString() ?? '0',
                ) ??
                0,
            isScheduledForDeletion: sa['isScheduledForDeletion'] == true,
          );
        })
        .where((sa) => sa.storeId.isNotEmpty)
        .toList();

    final rawTopStoreId = opMap?['topRankingStoreId']?.toString();
    final rawTopStoreName = opMap?['topRankingStoreName']?.toString();

    final operationalSummary = opMap == null
        ? const OperationalSummary()
        : OperationalSummary(
            totalCommissionDebt: double.tryParse(
                  opMap['totalCommissionDebt']?.toString() ?? '0',
                ) ??
                0.0,
            storesWithDebtCount: int.tryParse(
                  opMap['storesWithDebtCount']?.toString() ?? '0',
                ) ??
                0,
            pendingCommissionReportsCount: int.tryParse(
                  opMap['pendingCommissionReportsCount']?.toString() ?? '0',
                ) ??
                0,
            activePromotionsCount: int.tryParse(
                  opMap['activePromotionsCount']?.toString() ?? '0',
                ) ??
                0,
            pendingPromotionsCount: int.tryParse(
                  opMap['pendingPromotionsCount']?.toString() ?? '0',
                ) ??
                0,
            topDivision: opMap['topDivision']?.toString(),
            topDivisionTitle: opMap['topDivisionTitle']?.toString(),
            highestPR:
                int.tryParse(opMap['highestPR']?.toString() ?? '0') ?? 0,
            maxConsecutiveSalesDays: int.tryParse(
                  opMap['maxConsecutiveSalesDays']?.toString() ?? '0',
                ) ??
                0,
            dailyMissionsCompletedToday: int.tryParse(
                  opMap['dailyMissionsCompletedToday']?.toString() ?? '0',
                ) ??
                0,
            storesInDangerZoneCount: int.tryParse(
                  opMap['storesInDangerZoneCount']?.toString() ?? '0',
                ) ??
                0,
            storesScheduledForDeletionCount: int.tryParse(
                  opMap['storesScheduledForDeletionCount']?.toString() ?? '0',
                ) ??
                0,
            storeAlerts: storeAlerts,
            topRankingStoreId: (rawTopStoreId != null && rawTopStoreId.isNotEmpty)
                ? rawTopStoreId
                : null,
            topRankingStoreName:
                (rawTopStoreName != null && rawTopStoreName.isNotEmpty)
                    ? rawTopStoreName
                    : null,
          );

    return DashboardAnalyticsModel(
      period: json['period']?.toString() ?? 'month',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? 'all',
      currency: json['currency']?.toString() ?? 'USD',
      kpis: kpis,
      salesChart: salesChart,
      storesPerformance: storesPerformance,
      topProducts: topProducts,
      topDesiredProducts: topDesiredProducts,
      paymentMethods: paymentMethods,
      operationalSummary: operationalSummary,
    );
  }
}
