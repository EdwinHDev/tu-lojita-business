class Store {
  final String id;
  final String name;
  final String? branchName;
  final String? address;
  final String logo;
  final String? coverImage;
  final String description;
  final String phone;
  final String status;
  final int productsCount;
  final double salesToday;
  final String currency;

  final bool allowPartialPayments;
  final double partialPaymentsFeePercentage;
  final double minInitialPaymentPercentage;
  final int maxInstallments;

  const Store({
    required this.id,
    required this.name,
    this.branchName,
    this.address,
    required this.logo,
    this.coverImage,
    this.description = '',
    this.phone = '',
    required this.status,
    this.productsCount = 0,
    this.salesToday = 0.0,
    this.currency = 'USD',
    this.allowPartialPayments = false,
    this.partialPaymentsFeePercentage = 0.0,
    this.minInitialPaymentPercentage = 0.0,
    this.maxInstallments = 0,
  });

  String get displayName => branchName != null && branchName!.isNotEmpty 
    ? '$branchName ($name)' 
    : name;

  Store copyWith({
    String? id,
    String? name,
    String? branchName,
    String? address,
    String? logo,
    String? coverImage,
    String? description,
    String? phone,
    String? status,
    int? productsCount,
    double? salesToday,
    String? currency,
    bool? allowPartialPayments,
    double? partialPaymentsFeePercentage,
    double? minInitialPaymentPercentage,
    int? maxInstallments,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      branchName: branchName ?? this.branchName,
      address: address ?? this.address,
      logo: logo ?? this.logo,
      coverImage: coverImage ?? this.coverImage,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      productsCount: productsCount ?? this.productsCount,
      salesToday: salesToday ?? this.salesToday,
      currency: currency ?? this.currency,
      allowPartialPayments: allowPartialPayments ?? this.allowPartialPayments,
      partialPaymentsFeePercentage: partialPaymentsFeePercentage ?? this.partialPaymentsFeePercentage,
      minInitialPaymentPercentage: minInitialPaymentPercentage ?? this.minInitialPaymentPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
    );
  }
}
