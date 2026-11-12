import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';

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
  final bool isAgeRestricted;
  final bool hasMultipleBranches;
  final Subcategory? subcategory;
  final String? instagram;
  final String? tiktok;
  final DateTime? deletionScheduledAt;
  final bool isDeleted;
  final bool aiEnabled;
  final String? companyId;
  final int pendingOrdersCount;
  final double commissionDebt;
  final int pendingCommissionReportsCount;
  final String? rankingDivisionTitle;
  final int currentPR;
  final int consecutiveSalesDays;
  final bool inDangerZone;

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
    this.isAgeRestricted = false,
    this.hasMultipleBranches = false,
    this.subcategory,
    this.instagram,
    this.tiktok,
    this.deletionScheduledAt,
    this.isDeleted = false,
    this.aiEnabled = false,
    this.companyId,
    this.pendingOrdersCount = 0,
    this.commissionDebt = 0.0,
    this.pendingCommissionReportsCount = 0,
    this.rankingDivisionTitle,
    this.currentPR = 0,
    this.consecutiveSalesDays = 0,
    this.inDangerZone = false,
  });

  bool get isCategoryOrSubcategoryRestricted =>
      (subcategory?.isAgeRestricted == true) ||
      (subcategory?.category?.isAgeRestricted == true);

  bool get isScheduledForDeletion =>
      deletionScheduledAt != null && deletionScheduledAt!.isAfter(DateTime.now());

  int get remainingGraceDays {
    if (deletionScheduledAt == null) return 0;
    final diff = deletionScheduledAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  bool get isOperationalActive => status == 'ACTIVE' && !isScheduledForDeletion && !isDeleted;
  bool get isTemporarilyInactive => status == 'INACTIVE' && !isScheduledForDeletion;

  bool get shouldShowBranch =>
      hasMultipleBranches && branchName != null && branchName!.trim().isNotEmpty;

  String get branchLabel =>
      shouldShowBranch ? 'Sucursal ${branchName!.trim()}' : '';

  String get combinedDisplayName =>
      shouldShowBranch ? '$name ($branchLabel)' : name;

  String get displayName => shouldShowBranch 
      ? '$branchLabel ($name)' 
      : name;

  bool needsOperationalAttention({
    int unreadDisputesCount = 0,
    bool canViewFinancials = true,
  }) {
    return pendingOrdersCount > 0 ||
        unreadDisputesCount > 0 ||
        (canViewFinancials &&
            (commissionDebt > 0 || pendingCommissionReportsCount > 0)) ||
        isScheduledForDeletion ||
        inDangerZone;
  }

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
    bool? isAgeRestricted,
    bool? hasMultipleBranches,
    Subcategory? subcategory,
    String? instagram,
    String? tiktok,
    DateTime? deletionScheduledAt,
    bool? isDeleted,
    bool? aiEnabled,
    String? companyId,
    int? pendingOrdersCount,
    double? commissionDebt,
    int? pendingCommissionReportsCount,
    String? rankingDivisionTitle,
    int? currentPR,
    int? consecutiveSalesDays,
    bool? inDangerZone,
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
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      hasMultipleBranches: hasMultipleBranches ?? this.hasMultipleBranches,
      subcategory: subcategory ?? this.subcategory,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      deletionScheduledAt: deletionScheduledAt ?? this.deletionScheduledAt,
      isDeleted: isDeleted ?? this.isDeleted,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      companyId: companyId ?? this.companyId,
      pendingOrdersCount: pendingOrdersCount ?? this.pendingOrdersCount,
      commissionDebt: commissionDebt ?? this.commissionDebt,
      pendingCommissionReportsCount:
          pendingCommissionReportsCount ?? this.pendingCommissionReportsCount,
      rankingDivisionTitle: rankingDivisionTitle ?? this.rankingDivisionTitle,
      currentPR: currentPR ?? this.currentPR,
      consecutiveSalesDays: consecutiveSalesDays ?? this.consecutiveSalesDays,
      inDangerZone: inDangerZone ?? this.inDangerZone,
    );
  }
}
