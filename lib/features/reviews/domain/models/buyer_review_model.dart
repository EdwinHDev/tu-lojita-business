class BuyerReviewModel {
  final String id;
  final String orderId;
  final String authorId;
  final String targetUserId;
  final int rating;
  final String? comment;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  BuyerReviewModel({
    required this.id,
    required this.orderId,
    required this.authorId,
    required this.targetUserId,
    required this.rating,
    this.comment,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canEdit => DateTime.now().difference(createdAt).inDays < 3;

  factory BuyerReviewModel.fromJson(Map<String, dynamic> json) {
    return BuyerReviewModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      authorId: json['authorId'] ?? '',
      targetUserId: json['targetUserId'] ?? '',
      rating: json['rating'] is num
          ? (json['rating'] as num).toInt()
          : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment'],
      isVisible: json['isVisible'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'authorId': authorId,
      'targetUserId': targetUserId,
      'rating': rating,
      'comment': comment,
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
