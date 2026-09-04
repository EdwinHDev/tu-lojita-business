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
    required super.paymentMethods,
  });

  factory DashboardAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final kpisJson = json['kpis'] as Map<String, dynamic>? ?? {};
    final ratioJson = kpisJson['installmentRatio'] as Map<String, dynamic>? ?? {};
    final growthJson = kpisJson['growth'] as Map<String, dynamic>? ?? {};

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
      paymentMethods: paymentMethods,
    );
  }
}
