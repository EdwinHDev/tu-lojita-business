class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final String? storeId;
  final String? channelType;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.storeId,
    this.channelType,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? targetId,
    String? storeId,
    String? channelType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      storeId: storeId ?? this.storeId,
      channelType: channelType ?? this.channelType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
