import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.salesToday,
    required super.totalStores,
    required super.totalProducts,
    required super.totalCustomers,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      salesToday: SalesStatsModel.fromJson(json['salesToday'] as Map<String, dynamic>),
      totalStores: CountStatsModel.fromJson(json['totalStores'] as Map<String, dynamic>, 'newThisMonth'),
      totalProducts: CountStatsModel.fromJson(json['totalProducts'] as Map<String, dynamic>, 'addedThisWeek'),
      totalCustomers: CountStatsModel.fromJson(json['totalCustomers'] as Map<String, dynamic>, 'newThisMonth'),
    );
  }
}

class SalesStatsModel extends SalesStats {
  const SalesStatsModel({
    required super.amount,
    required super.percentage,
    required super.currency,
  });

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) {
    return SalesStatsModel(
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}

class CountStatsModel extends CountStats {
  const CountStatsModel({
    required super.count,
    required super.increment,
  });

  factory CountStatsModel.fromJson(Map<String, dynamic> json, String incrementKey) {
    return CountStatsModel(
      count: json['count'] as int,
      increment: json[incrementKey] as int,
    );
  }
}
