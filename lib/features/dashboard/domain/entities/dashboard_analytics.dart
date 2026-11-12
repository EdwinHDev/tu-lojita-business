class DashboardAnalytics {
  final String period;
  final String startDate;
  final String endDate;
  final String storeId;
  final String currency;
  final KpiMetrics kpis;
  final List<SalesChartPoint> salesChart;
  final List<StorePerformance> storesPerformance;
  final List<TopProduct> topProducts;
  final List<TopDesiredProduct> topDesiredProducts;
  final List<PaymentMethodShare> paymentMethods;
  final OperationalSummary operationalSummary;

  const DashboardAnalytics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.storeId,
    required this.currency,
    required this.kpis,
    required this.salesChart,
    required this.storesPerformance,
    required this.topProducts,
    this.topDesiredProducts = const [],
    required this.paymentMethods,
    this.operationalSummary = const OperationalSummary(),
  });
}

class StoreOperationalAlert {
  final String storeId;
  final String storeName;
  final int pendingOrders;
  final double accountsReceivable;
  final double commissionDebt;
  final int pendingCommissionReportsCount;
  final int activePromotionsCount;
  final int pendingPromotionsCount;
  final bool isScheduledForDeletion;

  const StoreOperationalAlert({
    required this.storeId,
    required this.storeName,
    this.pendingOrders = 0,
    this.accountsReceivable = 0.0,
    this.commissionDebt = 0.0,
    this.pendingCommissionReportsCount = 0,
    this.activePromotionsCount = 0,
    this.pendingPromotionsCount = 0,
    this.isScheduledForDeletion = false,
  });
}

class OperationalSummary {
  final double totalCommissionDebt;
  final int storesWithDebtCount;
  final int pendingCommissionReportsCount;
  final int activePromotionsCount;
  final int pendingPromotionsCount;
  final String? topDivision;
  final String? topDivisionTitle;
  final int highestPR;
  final int maxConsecutiveSalesDays;
  final int dailyMissionsCompletedToday;
  final int storesInDangerZoneCount;
  final int storesScheduledForDeletionCount;
  final List<StoreOperationalAlert> storeAlerts;
  final String? topRankingStoreId;
  final String? topRankingStoreName;

  const OperationalSummary({
    this.totalCommissionDebt = 0.0,
    this.storesWithDebtCount = 0,
    this.pendingCommissionReportsCount = 0,
    this.activePromotionsCount = 0,
    this.pendingPromotionsCount = 0,
    this.topDivision,
    this.topDivisionTitle,
    this.highestPR = 0,
    this.maxConsecutiveSalesDays = 0,
    this.dailyMissionsCompletedToday = 0,
    this.storesInDangerZoneCount = 0,
    this.storesScheduledForDeletionCount = 0,
    this.storeAlerts = const [],
    this.topRankingStoreId,
    this.topRankingStoreName,
  });
}

class KpiMetrics {
  final double totalSales;
  final double totalCollected;
  final double accountsReceivable;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final double averageTicket;
  final InstallmentRatio installmentRatio;
  final GrowthMetrics growth;

  const KpiMetrics({
    required this.totalSales,
    required this.totalCollected,
    required this.accountsReceivable,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.averageTicket,
    required this.installmentRatio,
    required this.growth,
  });
}

class InstallmentRatio {
  final int installmentOrdersCount;
  final int singlePaymentOrdersCount;
  final double installmentPercentage;
  final double singlePaymentPercentage;

  const InstallmentRatio({
    required this.installmentOrdersCount,
    required this.singlePaymentOrdersCount,
    required this.installmentPercentage,
    required this.singlePaymentPercentage,
  });
}

class GrowthMetrics {
  final double salesGrowthPercentage;
  final double ordersGrowthPercentage;

  const GrowthMetrics({
    required this.salesGrowthPercentage,
    required this.ordersGrowthPercentage,
  });
}

class SalesChartPoint {
  final String label;
  final String date;
  final double sales;
  final int ordersCount;

  const SalesChartPoint({
    required this.label,
    required this.date,
    required this.sales,
    required this.ordersCount,
  });
}

class StorePerformance {
  final String storeId;
  final String storeName;
  final double totalSales;
  final int ordersCount;
  final double percentageOfTotal;

  const StorePerformance({
    required this.storeId,
    required this.storeName,
    required this.totalSales,
    required this.ordersCount,
    required this.percentageOfTotal,
  });
}

class TopProduct {
  final String itemId;
  final String title;
  final String? mainImage;
  final int unitsSold;
  final double totalRevenue;
  final String? storeId;
  final String? storeName;

  const TopProduct({
    required this.itemId,
    required this.title,
    this.mainImage,
    required this.unitsSold,
    required this.totalRevenue,
    this.storeId,
    this.storeName,
  });
}

class PaymentMethodShare {
  final String method;
  final String label;
  final double totalAmount;
  final double percentage;
  final int transactionCount;

  const PaymentMethodShare({
    required this.method,
    required this.label,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
  });
}

class TopDesiredProduct {
  final String itemId;
  final String title;
  final String? mainImage;
  final int favoritesCount;
  final double price;
  final double? stockQuantity;
  final bool trackInventory;
  final bool hasVariants;
  final String? storeId;
  final String? storeName;

  bool get isOutOfStock =>
      trackInventory && (stockQuantity == null || stockQuantity! <= 0);

  const TopDesiredProduct({
    required this.itemId,
    required this.title,
    this.mainImage,
    required this.favoritesCount,
    required this.price,
    this.stockQuantity,
    required this.trackInventory,
    this.hasVariants = false,
    this.storeId,
    this.storeName,
  });
}
