import '../../domain/entities/store_dashboard.dart';

double _toDouble(dynamic value, [double fallback = 0.0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class StoreDashboardModel extends StoreDashboard {
  const StoreDashboardModel({
    required super.stats,
    required super.recentSales,
    super.pendingOrders = const [],
  });

  factory StoreDashboardModel.fromJson(Map<String, dynamic> json) {
    final statsMap = (json['stats'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final recentList = json['recentSales'] as List? ?? const [];
    final pendingList = json['pendingOrders'] as List? ?? const [];

    return StoreDashboardModel(
      stats: StoreStatsModel.fromJson(statsMap),
      recentSales: recentList
          .whereType<Map>()
          .map((e) => StoreRecentSaleModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
      pendingOrders: pendingList
          .whereType<Map>()
          .map(
              (e) => StorePendingOrderModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class StoreStatsModel extends StoreStats {
  const StoreStatsModel({
    required super.salesToday,
    super.salesTodayPercentage = 0.0,
    required super.currency,
    required super.totalItems,
    required super.totalCategories,
    required super.totalCustomers,
    super.pendingOrdersCount = 0,
    super.openDisputesCount = 0,
    super.commissionDebt = 0.0,
    super.pendingCommissionReportsCount = 0,
    super.activeStrikesCount = 0,
    super.pendingMediationRequestsCount = 0,
    super.paymentMethodsCount = 0,
    super.aiEnabled = false,
  });

  factory StoreStatsModel.fromJson(Map<String, dynamic> json) {
    final salesTodayJson =
        (json['salesToday'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return StoreStatsModel(
      salesToday: _toDouble(salesTodayJson['amount']),
      salesTodayPercentage: _toDouble(salesTodayJson['percentage']),
      currency: salesTodayJson['currency'] as String? ?? 'USD',
      totalItems: _toInt(json['totalItems']),
      totalCategories: _toInt(json['totalCategories']),
      totalCustomers: _toInt(json['totalCustomers']),
      pendingOrdersCount: _toInt(json['pendingOrdersCount']),
      openDisputesCount: _toInt(json['openDisputesCount']),
      commissionDebt: _toDouble(json['commissionDebt']),
      pendingCommissionReportsCount:
          _toInt(json['pendingCommissionReportsCount']),
      activeStrikesCount: _toInt(json['activeStrikesCount']),
      pendingMediationRequestsCount:
          _toInt(json['pendingMediationRequestsCount']),
      paymentMethodsCount: _toInt(json['paymentMethodsCount']),
      aiEnabled: json['aiEnabled'] == true,
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
    super.itemTitle,
    super.itemImageUrl,
  });

  factory StoreRecentSaleModel.fromJson(Map<String, dynamic> json) {
    return StoreRecentSaleModel(
      id: json['id'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      time: json['time'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      itemTitle: json['itemTitle'] as String?,
      itemImageUrl: json['itemImageUrl'] as String?,
    );
  }
}

class StorePendingOrderModel extends StorePendingOrder {
  const StorePendingOrderModel({
    required super.id,
    required super.orderId,
    required super.customerName,
    required super.amount,
    required super.currency,
    required super.time,
    required super.status,
    super.itemTitle,
    super.itemImageUrl,
  });

  factory StorePendingOrderModel.fromJson(Map<String, dynamic> json) {
    return StorePendingOrderModel(
      id: json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Cliente',
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      time: json['time'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      itemTitle: json['itemTitle'] as String?,
      itemImageUrl: json['itemImageUrl'] as String?,
    );
  }
}
