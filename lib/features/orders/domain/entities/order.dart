import 'order_item.dart';
import 'order_dispute.dart';
import '../../data/models/order_dispute_model.dart';

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
  final DateTime? updatedAt;

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
    this.updatedAt,
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null),
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
  final String? storeName;
  final String? rejectionReason;
  final String? cancellationReason;
  final String? cancellationNotes;
  final DateTime? cancelledAt;
  final bool cancellationResolutionConfirmed;
  final DateTime? cancellationResolvedAt;
  final String? cancellationResolutionStatus;
  final List<Installment> installments;
  final bool isPartialPayment;
  final bool isFullyPaid;
  final double totalPaidAmount;
  final double remainingBalance;
  final int? monthlyDueDay;
  final DateTime? nextDueDate;
  final int? installmentIntervalValue;
  final String? installmentIntervalUnit;
  final List<OrderDispute> disputes;
  final String? preOrderStatus;
  final DateTime? settlementDeadline;
  final List<Map<String, dynamic>> slotBookings;

  bool get isPreOrder => preOrderStatus != null && preOrderStatus != 'NONE';
  bool get hasSlotBookings => slotBookings.isNotEmpty;
  bool get isAwaitingStock => preOrderStatus == 'AWAITING_STOCK';
  bool get isStockArrived => preOrderStatus == 'STOCK_ARRIVED';
  bool get isReadyForSettlement => preOrderStatus == 'READY_FOR_SETTLEMENT';

  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  bool get isCancellationResolved =>
      cancellationResolutionConfirmed ||
      cancellationResolutionStatus == 'RESOLVED' ||
      (rejectionReason != null &&
          (rejectionReason!.contains('común acuerdo') ||
              rejectionReason!.contains('Cliente aceptó que el pago no fue recibido')));

  bool get hasPendingRefund =>
      isCancelled &&
      !isCancellationResolved &&
      payments.any((p) => p.status == 'WAITING_VERIFICATION' || p.status == 'PENDING');

  bool get isFullyRefunded =>
      isCancelled &&
      payments.isNotEmpty &&
      payments.every((p) => p.status == 'REFUNDED' || p.status == 'REJECTED') &&
      payments.any((p) => p.status == 'REFUNDED');

  OrderDispute? get activeDispute {
    if (disputes.isEmpty) return null;
    try {
      return disputes.firstWhere((d) => !d.isResolved);
    } catch (_) {
      return null;
    }
  }

  bool get hasActiveDispute => activeDispute != null;

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
    this.storeName,
    this.rejectionReason,
    this.cancellationReason,
    this.cancellationNotes,
    this.cancelledAt,
    this.cancellationResolutionConfirmed = false,
    this.cancellationResolvedAt,
    this.cancellationResolutionStatus,
    this.installments = const [],
    this.isPartialPayment = false,
    this.isFullyPaid = false,
    this.totalPaidAmount = 0.0,
    this.remainingBalance = 0.0,
    this.monthlyDueDay,
    this.nextDueDate,
    this.installmentIntervalValue,
    this.installmentIntervalUnit,
    this.disputes = const [],
    this.preOrderStatus,
    this.settlementDeadline,
    this.slotBookings = const [],
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
      storeName: json['storeName'] ?? json['store']?['name'],
      rejectionReason: json['rejectionReason'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      cancellationNotes: json['cancellationNotes'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancellationResolutionConfirmed: json['cancellationResolutionConfirmed'] == true,
      cancellationResolvedAt: json['cancellationResolvedAt'] != null
          ? DateTime.tryParse(json['cancellationResolvedAt'].toString())
          : null,
      cancellationResolutionStatus: json['cancellationResolutionStatus'] as String?,
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
      disputes: (json['disputes'] as List<dynamic>?)
              ?.map((e) => OrderDisputeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preOrderStatus: json['preOrderStatus'] as String?,
      settlementDeadline: json['settlementDeadline'] != null
          ? DateTime.tryParse(json['settlementDeadline'].toString())
          : null,
      slotBookings: (json['slotBookings'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
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
