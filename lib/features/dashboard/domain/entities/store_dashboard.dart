import 'package:equatable/equatable.dart';

class StoreDashboard extends Equatable {
  final StoreStats stats;
  final List<StoreRecentSale> recentSales;
  final List<StorePendingOrder> pendingOrders;

  const StoreDashboard({
    required this.stats,
    required this.recentSales,
    this.pendingOrders = const [],
  });

  @override
  List<Object?> get props => [stats, recentSales, pendingOrders];
}

class StoreStats extends Equatable {
  final double salesToday;
  final double salesTodayPercentage;
  final String currency;
  final int totalItems;
  final int totalCategories;
  final int totalCustomers;
  final int pendingOrdersCount;
  final int openDisputesCount;
  final double commissionDebt;
  final int pendingCommissionReportsCount;
  final int activeStrikesCount;
  final int pendingMediationRequestsCount;
  final int paymentMethodsCount;
  final bool aiEnabled;

  const StoreStats({
    required this.salesToday,
    this.salesTodayPercentage = 0.0,
    required this.currency,
    required this.totalItems,
    required this.totalCategories,
    required this.totalCustomers,
    this.pendingOrdersCount = 0,
    this.openDisputesCount = 0,
    this.commissionDebt = 0.0,
    this.pendingCommissionReportsCount = 0,
    this.activeStrikesCount = 0,
    this.pendingMediationRequestsCount = 0,
    this.paymentMethodsCount = 0,
    this.aiEnabled = false,
  });

  @override
  List<Object?> get props => [
        salesToday,
        salesTodayPercentage,
        currency,
        totalItems,
        totalCategories,
        totalCustomers,
        pendingOrdersCount,
        openDisputesCount,
        commissionDebt,
        pendingCommissionReportsCount,
        activeStrikesCount,
        pendingMediationRequestsCount,
        paymentMethodsCount,
        aiEnabled,
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
  final String? itemTitle;
  final String? itemImageUrl;

  const StoreRecentSale({
    required this.id,
    required this.storeName,
    required this.amount,
    required this.currency,
    required this.time,
    required this.orderId,
    required this.status,
    this.itemTitle,
    this.itemImageUrl,
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
        itemTitle,
        itemImageUrl,
      ];
}

class StorePendingOrder extends Equatable {
  final String id;
  final String orderId;
  final String customerName;
  final double amount;
  final String currency;
  final String time;
  final String status;
  final String? itemTitle;
  final String? itemImageUrl;

  const StorePendingOrder({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.currency,
    required this.time,
    required this.status,
    this.itemTitle,
    this.itemImageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        customerName,
        amount,
        currency,
        time,
        status,
        itemTitle,
        itemImageUrl,
      ];
}
