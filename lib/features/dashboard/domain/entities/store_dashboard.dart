import 'package:equatable/equatable.dart';

class StoreDashboard extends Equatable {
  final StoreStats stats;
  final List<StoreRecentSale> recentSales;

  const StoreDashboard({
    required this.stats,
    required this.recentSales,
  });

  @override
  List<Object?> get props => [stats, recentSales];
}

class StoreStats extends Equatable {
  final double salesToday;
  final String currency;
  final int totalItems;
  final int totalCategories;
  final int totalCustomers;

  const StoreStats({
    required this.salesToday,
    required this.currency,
    required this.totalItems,
    required this.totalCategories,
    required this.totalCustomers,
  });

  @override
  List<Object?> get props => [
        salesToday,
        currency,
        totalItems,
        totalCategories,
        totalCustomers,
      ];
}

class StoreRecentSale extends Equatable {
  final String id;
  final String storeName;
  final double amount;
  final String currency;
  final String time;
  final String orderId;
  final String status;

  const StoreRecentSale({
    required this.id,
    required this.storeName,
    required this.amount,
    required this.currency,
    required this.time,
    required this.orderId,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        storeName,
        amount,
        currency,
        time,
        orderId,
        status,
      ];
}
