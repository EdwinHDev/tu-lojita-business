class OrderReviewModel {
  final String id;
  final String orderId;
  final String authorId;
  final int rating;
  final String? comment;
  final List<String> imageUrls;
  final String? vendorReply;
  final DateTime? vendorRepliedAt;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorName;
  final String? authorAvatar;

  OrderReviewModel({
    required this.id,
    required this.orderId,
    required this.authorId,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    this.vendorReply,
    this.vendorRepliedAt,
    this.isVisible = true,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
  });

  bool get hasVendorReply => vendorReply != null && vendorReply!.trim().isNotEmpty;

  factory OrderReviewModel.fromJson(Map<String, dynamic> json) {
    String? authorName;
    String? authorAvatar;

    if (json['author'] != null && json['author'] is Map) {
      final a = json['author'];
      final first = a['firstName'] ?? '';
      final last = a['lastName'] ?? '';
      authorName = '$first $last'.trim();
      authorAvatar = a['avatarUrl'];
    }

    return OrderReviewModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      authorId: json['authorId'] ?? '',
      rating: json['rating'] is num
          ? (json['rating'] as num).toInt()
          : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment'],
      imageUrls: json['imageUrls'] != null && json['imageUrls'] is List
          ? List<String>.from((json['imageUrls'] as List).map((e) => e.toString()))
          : const [],
      vendorReply: json['vendorReply'],
      vendorRepliedAt: json['vendorRepliedAt'] != null
          ? DateTime.tryParse(json['vendorRepliedAt'].toString())
          : null,
      isVisible: json['isVisible'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorName: authorName,
      authorAvatar: authorAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'authorId': authorId,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'vendorReply': vendorReply,
      'vendorRepliedAt': vendorRepliedAt?.toIso8601String(),
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
