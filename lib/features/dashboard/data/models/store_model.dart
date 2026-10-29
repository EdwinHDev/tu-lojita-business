import 'package:tu_lojita_business/features/categories/data/models/subcategory_model.dart';
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
    super.installmentFrequencyOptions = const [],
    super.allowInstallmentExtensions = false,
    super.maxExtensionDays = 7,
    super.maxCreditLimit,
    super.isAgeRestricted = false,
    super.hasMultipleBranches = false,
    super.subcategory,
    super.instagram,
    super.tiktok,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final subcategory = json['subcategory'] != null
        ? SubcategoryModel.fromJson(json['subcategory'] as Map<String, dynamic>)
        : null;

    final isRestrictedByRubro =
        (subcategory?.isAgeRestricted == true) ||
        (subcategory?.category?.isAgeRestricted == true);

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
      installmentFrequencyOptions: (json['installmentFrequencyOptions'] as List?)
              ?.map((e) => StoreInstallmentFrequency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      allowInstallmentExtensions: json['allowInstallmentExtensions'] as bool? ?? false,
      maxExtensionDays: json['maxExtensionDays'] as int? ?? 7,
      maxCreditLimit: json['maxCreditLimit'] != null ? double.tryParse(json['maxCreditLimit'].toString()) : null,
      isAgeRestricted: isRestrictedByRubro || (json['isAgeRestricted'] as bool? ?? false),
      hasMultipleBranches: json['hasMultipleBranches'] == true,
      subcategory: subcategory,
      instagram: json['instagram'] as String?,
      tiktok: json['tiktok'] as String?,
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
      'installmentFrequencyOptions': installmentFrequencyOptions.map((e) => e.toJson()).toList(),
      'allowInstallmentExtensions': allowInstallmentExtensions,
      'maxExtensionDays': maxExtensionDays,
      'maxCreditLimit': maxCreditLimit,
      'isAgeRestricted': isAgeRestricted,
      'hasMultipleBranches': hasMultipleBranches,
      'instagram': instagram,
      'tiktok': tiktok,
    };
  }
}
