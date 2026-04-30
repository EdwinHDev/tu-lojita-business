enum PropertyType {
  text,
  list,
  color,
  colorList,
  number,
  boolean,
  dropdown,
}

class PropertyTemplate {
  final String id;
  final String name;
  final PropertyType type;
  final bool isRequired;
  final Map<String, dynamic>? config;

  PropertyTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.isRequired,
    this.config,
  });

  factory PropertyTemplate.fromJson(Map<String, dynamic> json) {
    return PropertyTemplate(
      id: json['id'],
      name: json['name'],
      type: _parseType(json['type']),
      isRequired: json['isRequired'] ?? false,
      config: json['config'],
    );
  }

  static PropertyType _parseType(String type) {
    switch (type) {
      case 'LIST': return PropertyType.list;
      case 'COLOR': return PropertyType.color;
      case 'COLOR_LIST': return PropertyType.colorList;
      case 'NUMBER': return PropertyType.number;
      case 'BOOLEAN': return PropertyType.boolean;
      case 'DROPDOWN': return PropertyType.dropdown;
      default: return PropertyType.text;
    }
  }
}
