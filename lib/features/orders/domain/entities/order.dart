import 'order_item.dart';

class Payment {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? reference;
  final String? receiptImage;
  final String? rejectionReason;
  final int? installmentIndex;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.reference,
    this.receiptImage,
    this.rejectionReason,
    this.installmentIndex,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      currency: json['currency'] ?? '',
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? '',
      reference: json['reference'] as String?,
      receiptImage: json['receiptImage'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      installmentIndex: json['installmentIndex'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

extension PaymentX on Payment {
  String get displayLabel {
    switch (paymentMethod) {
      case 'PAGO_MOVIL':
        return 'Pago Móvil';
      case 'TRANSFER':
        return 'Transferencia Bancaria';
      case 'BINANCE':
        return 'Binance Pay';
      default:
        return paymentMethod;
    }
  }

  String get quotaLabel {
    if (installmentIndex == null) return 'Pago Total';
    if (installmentIndex == 1) return 'Pago Inicial (Cuota 1)';
    return 'Cuota #$installmentIndex';
  }

  String getQuotaLabel(Order order) {
    if (!order.isPartialPayment) {
      return 'Pago Total (1 de 1)';
    }

    final total = order.installments.isNotEmpty ? order.installments.length : 1;
    final idx = installmentIndex ?? _deduceInstallmentIndex(order);

    if (idx == 1) {
      return total > 1 ? 'Cuota 1 de $total (Inicial)' : 'Cuota 1 de 1';
    } else if (idx == total) {
      return 'Cuota $total de $total (Final)';
    } else {
      return 'Cuota $idx de $total';
    }
  }

  int _deduceInstallmentIndex(Order order) {
    final sorted = [...order.payments];
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    int approvedBefore = 0;
    for (final p in sorted) {
      if (p.id == id) break;
      if (p.status == 'APPROVED') {
        approvedBefore++;
      }
    }
    final deduced = approvedBefore + 1;
    final maxInst = order.installments.isNotEmpty ? order.installments.length : 1;
    return deduced > maxInst ? maxInst : deduced;
  }
}

class Order {
  final String id;
  final String status;
  final double totalAmount;
  final double feeAmount;
  final double platformCommissionRate;
  final double platformCommissionAmount;
  final double finalAmount;
  final double balance;
  final DateTime createdAt;
  final List<OrderItem> orderItems;
  final Map<String, dynamic>? user;
  final List<Payment> payments;
  final String? storeId;
  final String? rejectionReason;
  final List<Installment> installments;
  final bool isPartialPayment;
  final bool isFullyPaid;
  final double totalPaidAmount;
  final double remainingBalance;
  final int? monthlyDueDay;
  final DateTime? nextDueDate;
  final int? installmentIntervalValue;
  final String? installmentIntervalUnit;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    this.feeAmount = 0.0,
    this.platformCommissionRate = 0.0,
    this.platformCommissionAmount = 0.0,
    required this.finalAmount,
    required this.balance,
    required this.createdAt,
    required this.orderItems,
    this.user,
    this.payments = const [],
    this.storeId,
    this.rejectionReason,
    this.installments = const [],
    this.isPartialPayment = false,
    this.isFullyPaid = false,
    this.totalPaidAmount = 0.0,
    this.remainingBalance = 0.0,
    this.monthlyDueDay,
    this.nextDueDate,
    this.installmentIntervalValue,
    this.installmentIntervalUnit,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      status: json['status'] ?? 'PENDING',
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      feeAmount: double.tryParse(json['feeAmount']?.toString() ?? '0') ?? 0.0,
      platformCommissionRate:
          double.tryParse(json['platformCommissionRate']?.toString() ?? '0') ??
              0.0,
      platformCommissionAmount:
          double.tryParse(json['platformCommissionAmount']?.toString() ?? '0') ??
              0.0,
      finalAmount: double.tryParse(json['finalAmount']?.toString() ?? '0') ?? 0.0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      orderItems: (json['orderItems'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      user: json['user'] as Map<String, dynamic>?,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      storeId: json['storeId'] ?? json['store']?['id'],
      rejectionReason: json['rejectionReason'] as String?,
      installments: (json['installments'] as List<dynamic>?)
              ?.map((e) => Installment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPartialPayment: json['isPartialPayment'] ?? false,
      isFullyPaid: json['isFullyPaid'] ?? false,
      totalPaidAmount: double.tryParse(json['totalPaidAmount']?.toString() ?? '0') ?? 0.0,
      remainingBalance: double.tryParse(json['remainingBalance']?.toString() ?? '0') ?? 0.0,
      monthlyDueDay: json['monthlyDueDay'] as int?,
      nextDueDate: json['nextDueDate'] != null ? DateTime.tryParse(json['nextDueDate']) : null,
      installmentIntervalValue: json['installmentIntervalValue'] as int?,
      installmentIntervalUnit: json['installmentIntervalUnit'] as String?,
    );
  }
}

class Installment {
  final String id;
  final double amount;
  final double paidAmount;
  final double lateFeeApplied;
  final DateTime? dueDate;
  final DateTime? paymentDate;
  final String status;
  final Order? order;

  final String extensionStatus;
  final int? extensionRequestedDays;
  final String? extensionReason;
  final String? extensionMerchantComment;

  Installment({
    required this.id,
    required this.amount,
    required this.paidAmount,
    required this.lateFeeApplied,
    this.dueDate,
    this.paymentDate,
    required this.status,
    this.order,
    required this.extensionStatus,
    this.extensionRequestedDays,
    this.extensionReason,
    this.extensionMerchantComment,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paidAmount']?.toString() ?? '0') ?? 0.0,
      lateFeeApplied: double.tryParse(json['lateFeeApplied']?.toString() ?? '0') ?? 0.0,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      paymentDate: json['paymentDate'] != null ? DateTime.tryParse(json['paymentDate'].toString()) : null,
      status: json['status'] ?? 'PENDING',
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
      extensionStatus: json['extensionStatus'] ?? 'NONE',
      extensionRequestedDays: json['extensionRequestedDays'] as int?,
      extensionReason: json['extensionReason'] as String?,
      extensionMerchantComment: json['extensionMerchantComment'] as String?,
    );
  }
}
