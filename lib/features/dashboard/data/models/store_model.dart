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
    super.allowPartialPayments = false,
    super.partialPaymentsFeePercentage = 0.0,
    super.minInitialPaymentPercentage = 0.0,
    super.maxInstallments = 0,
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
      allowPartialPayments: json['allowPartialPayments'] as bool? ?? false,
      partialPaymentsFeePercentage: double.tryParse(json['partialPaymentsFeePercentage'].toString()) ?? 0.0,
      minInitialPaymentPercentage: double.tryParse(json['minInitialPaymentPercentage'].toString()) ?? 0.0,
      maxInstallments: json['maxInstallments'] as int? ?? 0,
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
      'allowPartialPayments': allowPartialPayments,
      'partialPaymentsFeePercentage': partialPaymentsFeePercentage,
      'minInitialPaymentPercentage': minInitialPaymentPercentage,
      'maxInstallments': maxInstallments,
    };
  }
}
