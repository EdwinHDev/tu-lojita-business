import '../../domain/entities/store_dashboard.dart';

class StoreDashboardModel extends StoreDashboard {
  const StoreDashboardModel({
    required super.stats,
    required super.recentSales,
  });

  factory StoreDashboardModel.fromJson(Map<String, dynamic> json) {
    return StoreDashboardModel(
      stats: StoreStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      recentSales: (json['recentSales'] as List)
          .map((e) => StoreRecentSaleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StoreStatsModel extends StoreStats {
  const StoreStatsModel({
    required super.salesToday,
    required super.currency,
    required super.totalItems,
    required super.totalCategories,
    required super.totalCustomers,
  });

  factory StoreStatsModel.fromJson(Map<String, dynamic> json) {
    final salesTodayJson = json['salesToday'] as Map<String, dynamic>;
    return StoreStatsModel(
      salesToday: (salesTodayJson['amount'] as num).toDouble(),
      currency: salesTodayJson['currency'] as String,
      totalItems: json['totalItems'] as int,
      totalCategories: json['totalCategories'] as int,
      totalCustomers: json['totalCustomers'] as int,
    );
  }
}

class StoreRecentSaleModel extends StoreRecentSale {
  const StoreRecentSaleModel({
    required super.id,
    required super.storeName,
    required super.amount,
    required super.currency,
    required super.time,
    required super.orderId,
    required super.status,
  });

  factory StoreRecentSaleModel.fromJson(Map<String, dynamic> json) {
    return StoreRecentSaleModel(
      id: json['id'] as String,
      storeName: json['storeName'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      time: json['time'] as String,
      orderId: json['orderId'] as String,
      status: json['status'] as String,
    );
  }
}
