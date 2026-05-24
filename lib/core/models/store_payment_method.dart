import 'bank.dart';

enum PaymentMethodType {
  pagoMovil,
  transfer,
  binance;

  String get displayName {
    switch (this) {
      case PaymentMethodType.pagoMovil:
        return 'Pago Móvil';
      case PaymentMethodType.transfer:
        return 'Transferencia Bancaria';
      case PaymentMethodType.binance:
        return 'Binance Pay';
    }
  }

  String toJsonValue() {
    switch (this) {
      case PaymentMethodType.pagoMovil:
        return 'PAGO_MOVIL';
      case PaymentMethodType.transfer:
        return 'TRANSFER';
      case PaymentMethodType.binance:
        return 'BINANCE';
    }
  }

  static PaymentMethodType fromJsonValue(String? value) {
    switch (value) {
      case 'PAGO_MOVIL':
        return PaymentMethodType.pagoMovil;
      case 'TRANSFER':
        return PaymentMethodType.transfer;
      case 'BINANCE':
        return PaymentMethodType.binance;
      default:
        return PaymentMethodType.pagoMovil;
    }
  }
}

class StorePaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String title;
  final String? accountHolder;
  final String? idNumber;
  final String? accountNumber;
  final String? phoneNumber;
  final String? email;
  final String? walletAddress;
  final String? instructions;
  final bool isActive;
  final Bank? bank;

  StorePaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    this.accountHolder,
    this.idNumber,
    this.accountNumber,
    this.phoneNumber,
    this.email,
    this.walletAddress,
    this.instructions,
    this.isActive = true,
    this.bank,
  });

  factory StorePaymentMethod.fromJson(Map<String, dynamic> json) {
    return StorePaymentMethod(
      id: json['id'],
      type: PaymentMethodType.fromJsonValue(json['type']),
      title: json['title'],
      accountHolder: json['accountHolder'],
      idNumber: json['idNumber'],
      accountNumber: json['accountNumber'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      walletAddress: json['walletAddress'],
      instructions: json['instructions'],
      isActive: json['isActive'] ?? true,
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJsonValue(),
      'title': title,
      'accountHolder': accountHolder,
      'idNumber': idNumber,
      'accountNumber': accountNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'walletAddress': walletAddress,
      'instructions': instructions,
      'isActive': isActive,
      'bank': bank?.toJson(),
    };
  }
}
