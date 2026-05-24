import 'order_item.dart';

class Payment {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? reference;
  final String? receiptImage;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.reference,
    this.receiptImage,
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
      case 'ZELLE':
        return 'Zelle';
      case 'CASH':
        return 'Efectivo';
      default:
        return paymentMethod;
    }
  }
}

class Order {
  final String id;
  final String status;
  final double totalAmount;
  final double finalAmount;
  final double balance;
  final DateTime createdAt;
  final List<OrderItem> orderItems;
  final Map<String, dynamic>? user;
  final List<Payment> payments;
  final String? storeId;
  final String? rejectionReason;
  final List<Installment> installments;

  Order({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.finalAmount,
    required this.balance,
    required this.createdAt,
    required this.orderItems,
    this.user,
    this.payments = const [],
    this.storeId,
    this.rejectionReason,
    this.installments = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      status: json['status'] ?? 'PENDING',
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
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
    );
  }
}

class Installment {
  final String id;
  final double amount;
  final DateTime dueDate;
  final String status;
  final Order? order;

  Installment({
    required this.id,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.order,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      order: json['order'] != null ? Order.fromJson(json['order']) : null,
    );
  }
}
