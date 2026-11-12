import 'package:equatable/equatable.dart';

/// Commercial performance metrics for an item viewed by its store owner or
/// an authorized collaborator.
class ItemOwnerStats extends Equatable {
  final int unitsSold;
  final int ordersCount;
  final int favoritesCount;
  final double? grossRevenue;
  final double? netRevenue;
  final bool canViewFinancials;

  const ItemOwnerStats({
    this.unitsSold = 0,
    this.ordersCount = 0,
    this.favoritesCount = 0,
    this.grossRevenue,
    this.netRevenue,
    this.canViewFinancials = true,
  });

  factory ItemOwnerStats.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return ItemOwnerStats(
      unitsSold: parseInt(json['unitsSold']),
      ordersCount: parseInt(json['ordersCount']),
      favoritesCount: parseInt(json['favoritesCount']),
      grossRevenue: parseNullableDouble(json['grossRevenue']),
      netRevenue: parseNullableDouble(json['netRevenue']),
      canViewFinancials: json['canViewFinancials'] != false,
    );
  }

  @override
  List<Object?> get props => [
        unitsSold,
        ordersCount,
        favoritesCount,
        grossRevenue,
        netRevenue,
        canViewFinancials,
      ];
}
