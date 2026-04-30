class DashboardStats {
  final SalesStats salesToday;
  final CountStats totalStores;
  final CountStats totalProducts;
  final CountStats totalCustomers;

  const DashboardStats({
    required this.salesToday,
    required this.totalStores,
    required this.totalProducts,
    required this.totalCustomers,
  });
}

class SalesStats {
  final double amount;
  final double percentage;
  final String currency;

  const SalesStats({
    required this.amount,
    required this.percentage,
    required this.currency,
  });
}

class CountStats {
  final int count;
  final int increment; // newThisMonth or addedThisWeek

  const CountStats({
    required this.count,
    required this.increment,
  });
}
