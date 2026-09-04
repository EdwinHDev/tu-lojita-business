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
  final List<PaymentMethodShare> paymentMethods;

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
    required this.paymentMethods,
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

  const TopProduct({
    required this.itemId,
    required this.title,
    this.mainImage,
    required this.unitsSold,
    required this.totalRevenue,
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
