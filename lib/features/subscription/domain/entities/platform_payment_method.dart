class PlatformPaymentMethod {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> accountDetails;
  final String? qrImageUrl;
  final String? instructions;
  final bool isActive;

  const PlatformPaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.accountDetails,
    this.qrImageUrl,
    this.instructions,
    this.isActive = true,
  });

  factory PlatformPaymentMethod.fromJson(Map<String, dynamic> json) {
    return PlatformPaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      accountDetails: (json['accountDetails'] as Map<String, dynamic>?) ?? {},
      qrImageUrl: json['qrImageUrl'],
      instructions: json['instructions'],
      isActive: json['isActive'] ?? true,
    );
  }
}
