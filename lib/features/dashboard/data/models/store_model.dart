import '../../domain/entities/store.dart';

class StoreModel extends Store {
  const StoreModel({
    required super.id,
    required super.name,
    super.branchName,
    super.address,
    required super.logo,
    super.coverImage,
    super.description = '',
    super.phone = '',
    required super.status,
    super.productsCount = 0,
    super.salesToday = 0.0,
    super.currency = 'USD',
    super.timezone = 'America/Caracas',
    super.allowPartialPayments = false,
    super.partialPaymentsFeePercentage = 0.0,
    super.minInitialPaymentPercentage = 0.0,
    super.maxInstallments = 0,
    super.allowChat = true,
    super.installmentIntervalValue = 7,
    super.installmentIntervalUnit = 'DAYS',
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      branchName: json['branchName'] as String?,
      address: json['address'] as String?,
      logo: json['logo'] as String,
      coverImage: json['coverImage'] as String?,
      description: json['description'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String,
      productsCount: json['productsCount'] as int? ?? 0,
      salesToday: (json['salesToday'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      timezone: json['timezone'] as String? ?? 'America/Caracas',
      allowPartialPayments: json['allowPartialPayments'] as bool? ?? false,
      partialPaymentsFeePercentage: double.tryParse(json['partialPaymentsFeePercentage'].toString()) ?? 0.0,
      minInitialPaymentPercentage: double.tryParse(json['minInitialPaymentPercentage'].toString()) ?? 0.0,
      maxInstallments: json['maxInstallments'] as int? ?? 0,
      allowChat: json['allowChat'] as bool? ?? true,
      installmentIntervalValue: json['installmentIntervalValue'] as int? ?? 7,
      installmentIntervalUnit: json['installmentIntervalUnit'] as String? ?? 'DAYS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branchName': branchName,
      'address': address,
      'logo': logo,
      'coverImage': coverImage,
      'description': description,
      'phone': phone,
      'status': status,
      'productsCount': productsCount,
      'salesToday': salesToday,
      'currency': currency,
      'timezone': timezone,
      'allowPartialPayments': allowPartialPayments,
      'partialPaymentsFeePercentage': partialPaymentsFeePercentage,
      'minInitialPaymentPercentage': minInitialPaymentPercentage,
      'maxInstallments': maxInstallments,
      'allowChat': allowChat,
      'installmentIntervalValue': installmentIntervalValue,
      'installmentIntervalUnit': installmentIntervalUnit,
    };
  }
}
