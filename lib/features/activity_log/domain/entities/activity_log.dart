class ActivityLogStore {
  final String id;
  final String name;
  final String? branchName;

  const ActivityLogStore({
    required this.id,
    required this.name,
    this.branchName,
  });

  String get displayName => (branchName != null && branchName!.isNotEmpty)
      ? '$name - $branchName'
      : name;

  factory ActivityLogStore.fromJson(Map<String, dynamic> json) {
    return ActivityLogStore(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      branchName: json['branchName'] as String?,
    );
  }
}

class ActivityLog {
  final String id;
  final String companyId;
  final String? storeId;
  final ActivityLogStore? store;
  final String actorType; // 'OWNER' or 'COLLABORATOR'
  final String actorId;
  final String actorName;
  final String actorRoleName;
  final String module; // 'INVENTORY', 'ORDERS', 'INSTALLMENTS', 'TEAM', 'STORE', etc.
  final String action;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.companyId,
    this.storeId,
    this.store,
    required this.actorType,
    required this.actorId,
    required this.actorName,
    required this.actorRoleName,
    required this.module,
    required this.action,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  bool get isCollaborator => actorType == 'COLLABORATOR';

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      storeId: json['storeId'] as String?,
      store: json['store'] != null
          ? ActivityLogStore.fromJson(json['store'] as Map<String, dynamic>)
          : null,
      actorType: json['actorType'] as String? ?? 'OWNER',
      actorId: json['actorId'] as String? ?? '',
      actorName: json['actorName'] as String? ?? 'Usuario',
      actorRoleName: json['actorRoleName'] as String? ?? 'Administrador',
      module: json['module'] as String? ?? 'STORE',
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class PaginatedActivityLogs {
  final List<ActivityLog> items;
  final int total;
  final bool hasMore;
  final int limit;
  final int offset;

  const PaginatedActivityLogs({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.limit,
    required this.offset,
  });

  factory PaginatedActivityLogs.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List<dynamic>? ?? [];
    return PaginatedActivityLogs(
      items: rawList
          .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }
}

