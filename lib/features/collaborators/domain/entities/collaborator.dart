class CollaboratorStore {
  final String id;
  final String name;
  final String? branchName;

  const CollaboratorStore({
    required this.id,
    required this.name,
    this.branchName,
  });

  String get displayName => (branchName != null && branchName!.isNotEmpty)
      ? '$name - $branchName'
      : name;

  factory CollaboratorStore.fromJson(Map<String, dynamic> json) {
    return CollaboratorStore(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      branchName: json['branchName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'branchName': branchName,
    };
  }
}

class Collaborator {
  final String id;
  final String accessId;
  final String firstName;
  final String lastName;
  final String? identification;
  final String? phone;
  final bool isActive;
  final bool hasFullBranchAccess;
  final String roleId;
  final String roleName;
  final List<String> permissions;
  final List<CollaboratorStore> stores;
  final String? initialPassword;

  const Collaborator({
    required this.id,
    required this.accessId,
    required this.firstName,
    required this.lastName,
    this.identification,
    this.phone,
    this.isActive = true,
    this.hasFullBranchAccess = false,
    required this.roleId,
    required this.roleName,
    this.permissions = const [],
    this.stores = const [],
    this.initialPassword,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    String rId = '';
    String rName = 'Sin rol';
    List<String> perms = [];

    if (json['role'] is Map) {
      final rMap = json['role'] as Map<String, dynamic>;
      rId = rMap['id'] as String? ?? '';
      rName = rMap['name'] as String? ?? 'Sin rol';
      if (rMap['permissions'] is List) {
        perms = (rMap['permissions'] as List).map((p) {
          if (p is Map && p['permission'] != null) {
            return p['permission'].toString();
          }
          return p.toString();
        }).toList();
      }
    } else if (json['roleId'] != null) {
      rId = json['roleId'].toString();
    }

    if (json['permissions'] is List && perms.isEmpty) {
      perms = (json['permissions'] as List).map((p) => p.toString()).toList();
    }

    List<CollaboratorStore> parsedStores = [];
    if (json['stores'] is List) {
      parsedStores = (json['stores'] as List)
          .map((s) => CollaboratorStore.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return Collaborator(
      id: json['id'] as String? ?? '',
      accessId: json['accessId'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      identification: json['identification'] as String?,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      hasFullBranchAccess: json['hasFullBranchAccess'] as bool? ?? false,
      roleId: rId,
      roleName: rName,
      permissions: perms,
      stores: parsedStores,
      initialPassword: json['initialPassword'] as String?,
    );
  }

  Collaborator copyWith({
    String? id,
    String? accessId,
    String? firstName,
    String? lastName,
    String? identification,
    String? phone,
    bool? isActive,
    bool? hasFullBranchAccess,
    String? roleId,
    String? roleName,
    List<String>? permissions,
    List<CollaboratorStore>? stores,
    String? initialPassword,
  }) {
    return Collaborator(
      id: id ?? this.id,
      accessId: accessId ?? this.accessId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      identification: identification ?? this.identification,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      hasFullBranchAccess: hasFullBranchAccess ?? this.hasFullBranchAccess,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
      stores: stores ?? this.stores,
      initialPassword: initialPassword ?? this.initialPassword,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accessId': accessId,
      'firstName': firstName,
      'lastName': lastName,
      'identification': identification,
      'phone': phone,
      'isActive': isActive,
      'hasFullBranchAccess': hasFullBranchAccess,
      'roleId': roleId,
      'roleName': roleName,
      'permissions': permissions,
      'stores': stores.map((s) => s.toJson()).toList(),
      'initialPassword': initialPassword,
    };
  }
}

class PaginatedCollaborators {
  final List<Collaborator> items;
  final int total;
  final bool hasMore;
  final int limit;
  final int offset;

  const PaginatedCollaborators({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.limit,
    required this.offset,
  });

  factory PaginatedCollaborators.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .map((item) => Collaborator.fromJson(item as Map<String, dynamic>))
          .toList();
      return PaginatedCollaborators(
        items: items,
        total: items.length,
        hasMore: false,
        limit: items.length,
        offset: 0,
      );
    }
    final map = json as Map<String, dynamic>;
    final list = map['items'] as List? ?? [];
    final items = list
        .map((item) => Collaborator.fromJson(item as Map<String, dynamic>))
        .toList();
    final total = map['total'] as int? ?? items.length;
    final limit = map['limit'] as int? ?? 10;
    final offset = map['offset'] as int? ?? 0;
    final hasMore = map['hasMore'] as bool? ?? (offset + items.length < total);

    return PaginatedCollaborators(
      items: items,
      total: total,
      hasMore: hasMore,
      limit: limit,
      offset: offset,
    );
  }
}

