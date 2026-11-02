import '../../domain/entities/notification.dart';

class NotificationModel extends AppNotification {
  NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.type,
    super.targetId,
    super.storeId,
    super.channelType,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      targetId: json['targetId'],
      storeId: json['storeId'],
      channelType: json['channelType'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'targetId': targetId,
      'storeId': storeId,
      'channelType': channelType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
