import 'package:tu_lojita_business/features/auth/domain/entities/user.dart';
import 'package:tu_lojita_business/features/auth/data/models/user_model.dart';

class ChatMessage {
  final String id;
  final String orderId;
  final User sender;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final bool isDelivered;
  final bool hasError;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.sender,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
    this.isDelivered = false,
    this.hasError = false,
  });

  ChatMessage copyWith({
    String? id,
    String? orderId,
    User? sender,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    bool? isRead,
    bool? isDelivered,
    bool? hasError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      hasError: hasError ?? this.hasError,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String orderId = '';
    if (json['orderId'] != null) {
      orderId = json['orderId'];
    } else if (json['order'] != null && json['order'] is Map) {
      orderId = json['order']['id'] ?? '';
    }

    return ChatMessage(
      id: json['id'] ?? '',
      orderId: orderId,
      sender: json['sender'] != null
          ? UserModel.fromJson(Map<String, dynamic>.from(json['sender']))
          : const User(id: '', email: '', firstName: '', lastName: '', role: 'USER'),
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      hasError: json['hasError'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'sender': sender.toJson(),
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'hasError': hasError,
    };
  }
}
