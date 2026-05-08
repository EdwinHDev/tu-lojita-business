import 'bank.dart';

enum PaymentMethodType {
  PAGO_MOVIL,
  TRANSFER,
  BINANCE,
  ZELLE,
  OTHER;

  String get displayName {
    switch (this) {
      case PaymentMethodType.PAGO_MOVIL:
        return 'Pago Móvil';
      case PaymentMethodType.TRANSFER:
        return 'Transferencia Bancaria';
      case PaymentMethodType.BINANCE:
        return 'Binance Pay';
      case PaymentMethodType.ZELLE:
        return 'Zelle';
      case PaymentMethodType.OTHER:
        return 'Otro';
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
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentMethodType.OTHER,
      ),
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
      'type': type.name,
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
