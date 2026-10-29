class CompanyRole {
  final String id;
  final String name;
  final String? description;
  final bool isSystemDefault;
  final List<String> permissions;
  final int collaboratorsCount;

  bool get isDefault => isSystemDefault;

  const CompanyRole({
    required this.id,
    required this.name,
    this.description,
    this.isSystemDefault = false,
    this.permissions = const [],
    this.collaboratorsCount = 0,
  });

  factory CompanyRole.fromJson(Map<String, dynamic> json) {
    List<String> perms = [];
    if (json['permissions'] is List) {
      perms = (json['permissions'] as List).map((p) {
        if (p is Map && p['permission'] != null) {
          return p['permission'].toString();
        }
        return p.toString();
      }).toList();
    }

    int collabCount = 0;
    if (json['collaborators'] is List) {
      collabCount = (json['collaborators'] as List).length;
    } else if (json['collaboratorsCount'] is int) {
      collabCount = json['collaboratorsCount'] as int;
    }

    return CompanyRole(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isSystemDefault: json['isSystemDefault'] as bool? ?? false,
      permissions: perms,
      collaboratorsCount: collabCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isSystemDefault': isSystemDefault,
      'permissions': permissions,
    };
  }
}
