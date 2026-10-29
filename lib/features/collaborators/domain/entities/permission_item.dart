class PermissionItem {
  final String key;
  final String module;
  final String name;
  final String description;

  String get title => name;

  const PermissionItem({
    required this.key,
    required this.module,
    required this.name,
    required this.description,
  });

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    return PermissionItem(
      key: json['key'] as String? ?? '',
      module: json['module'] as String? ?? 'General',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'module': module,
      'name': name,
      'description': description,
    };
  }
}
