enum SubscriptionStatus {
  paymentRequired,
  pendingVerification,
  active,
  gracePeriod,
  suspended;

  static SubscriptionStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'GRACE_PERIOD':
        return SubscriptionStatus.gracePeriod;
      case 'PENDING_VERIFICATION':
        return SubscriptionStatus.pendingVerification;
      case 'SUSPENDED':
        return SubscriptionStatus.suspended;
      case 'PAYMENT_REQUIRED':
      default:
        return SubscriptionStatus.paymentRequired;
    }
  }

  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Activa';
      case SubscriptionStatus.gracePeriod:
        return 'Período de Gracia (3 días)';
      case SubscriptionStatus.pendingVerification:
        return 'En Verificación (24-72h)';
      case SubscriptionStatus.suspended:
        return 'Suspendida por Mora';
      case SubscriptionStatus.paymentRequired:
        return 'Pago Requerido';
    }
  }
}

class CompanySubscription {
  final String id;
  final double monthlyFee;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? gracePeriodEnd;
  final double accumulatedDebt;

  const CompanySubscription({
    required this.id,
    required this.monthlyFee,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.gracePeriodEnd,
    this.accumulatedDebt = 0.0,
  });

  factory CompanySubscription.fromJson(Map<String, dynamic> json) {
    return CompanySubscription(
      id: json['id'] ?? '',
      monthlyFee: double.tryParse(json['monthlyFee']?.toString() ?? '20.0') ?? 20.0,
      status: SubscriptionStatus.fromString(json['status']?.toString() ?? 'PAYMENT_REQUIRED'),
      currentPeriodStart: json['currentPeriodStart'] != null ? DateTime.tryParse(json['currentPeriodStart']) : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null ? DateTime.tryParse(json['currentPeriodEnd']) : null,
      gracePeriodEnd: json['gracePeriodEnd'] != null ? DateTime.tryParse(json['gracePeriodEnd']) : null,
      accumulatedDebt: double.tryParse(json['accumulatedDebt']?.toString() ?? '0') ?? 0.0,
    );
  }
}
