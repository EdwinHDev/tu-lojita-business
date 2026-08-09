class StoreInstallmentFrequency {
  final int value;
  final String unit;
  final String label;

  const StoreInstallmentFrequency({
    required this.value,
    required this.unit,
    required this.label,
  });

  factory StoreInstallmentFrequency.fromJson(Map<String, dynamic> json) {
    return StoreInstallmentFrequency(
      value: json['value'] as int,
      unit: json['unit'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'label': label,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreInstallmentFrequency &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          unit == other.unit;

  @override
  int get hashCode => value.hashCode ^ unit.hashCode;
}

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
  final String timezone;

  final bool allowPartialPayments;
  final double partialPaymentsFeePercentage;
  final double minInitialPaymentPercentage;
  final int maxInstallments;
  final bool allowChat;
  final int installmentIntervalValue;
  final String installmentIntervalUnit;
  final List<StoreInstallmentFrequency> installmentFrequencyOptions;

  final bool allowInstallmentExtensions;
  final int maxExtensionDays;
  final double? maxCreditLimit;

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
    this.timezone = 'America/Caracas',
    this.allowPartialPayments = false,
    this.partialPaymentsFeePercentage = 0.0,
    this.minInitialPaymentPercentage = 0.0,
    this.maxInstallments = 0,
    this.allowChat = true,
    this.installmentIntervalValue = 7,
    this.installmentIntervalUnit = 'DAYS',
    this.installmentFrequencyOptions = const [],
    this.allowInstallmentExtensions = false,
    this.maxExtensionDays = 7,
    this.maxCreditLimit,
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
    String? timezone,
    bool? allowPartialPayments,
    double? partialPaymentsFeePercentage,
    double? minInitialPaymentPercentage,
    int? maxInstallments,
    bool? allowChat,
    int? installmentIntervalValue,
    String? installmentIntervalUnit,
    List<StoreInstallmentFrequency>? installmentFrequencyOptions,
    bool? allowInstallmentExtensions,
    int? maxExtensionDays,
    double? maxCreditLimit,
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
      timezone: timezone ?? this.timezone,
      allowPartialPayments: allowPartialPayments ?? this.allowPartialPayments,
      partialPaymentsFeePercentage: partialPaymentsFeePercentage ?? this.partialPaymentsFeePercentage,
      minInitialPaymentPercentage: minInitialPaymentPercentage ?? this.minInitialPaymentPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      allowChat: allowChat ?? this.allowChat,
      installmentIntervalValue: installmentIntervalValue ?? this.installmentIntervalValue,
      installmentIntervalUnit: installmentIntervalUnit ?? this.installmentIntervalUnit,
      installmentFrequencyOptions: installmentFrequencyOptions ?? this.installmentFrequencyOptions,
      allowInstallmentExtensions: allowInstallmentExtensions ?? this.allowInstallmentExtensions,
      maxExtensionDays: maxExtensionDays ?? this.maxExtensionDays,
      maxCreditLimit: maxCreditLimit ?? this.maxCreditLimit,
    );
  }
}
