import 'package:tu_lojita_business/features/company_onboarding/data/models/company_model.dart';
import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.role,
    super.hasCompany = false,
    super.avatarUrl,
    super.company,
    super.identification,
    super.phone,
    super.isActive = true,
    super.accountSuspendedUntil,
    super.accountSuspensionReason,
    super.googleId,
    super.isCollaborator = false,
    super.accessId,
    super.collaboratorRole,
    super.permissions = const [],
    super.allowedBranchIds = const [],
    super.hasFullBranchAccess = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If the response wraps under 'collaborator', extract that nested map
    final Map<String, dynamic> source = json['collaborator'] is Map
        ? Map<String, dynamic>.from(json['collaborator'] as Map)
        : (json['user'] is Map
            ? Map<String, dynamic>.from(json['user'] as Map)
            : json);

    final isCollab = source['isCollaborator'] == true ||
        source['actorType'] == 'COLLABORATOR' ||
        json['collaborator'] != null;

    final permissionsRaw = source['permissions'];
    final List<String> permissionsList = permissionsRaw is List
        ? permissionsRaw.map((e) => e.toString()).toList()
        : const [];

    final allowedBranchesRaw = source['allowedBranchIds'];
    final List<String> allowedBranchIdsList = allowedBranchesRaw is List
        ? allowedBranchesRaw.map((e) => e.toString()).toList()
        : const [];

    String? roleName;
    if (source['collaboratorRole'] != null) {
      roleName = source['collaboratorRole']?.toString();
    } else if (source['role'] is Map) {
      roleName = (source['role'] as Map)['name']?.toString();
    } else if (source['role'] is String) {
      roleName = source['role'] as String;
    }

    final accessIdStr = source['accessId']?.toString();
    final emailStr = source['email']?.toString() ??
        (accessIdStr != null && accessIdStr.isNotEmpty
            ? '$accessIdStr@collaborator.local'
            : '');

    return UserModel(
      id: source['id']?.toString() ?? '',
      email: emailStr,
      firstName: source['firstName']?.toString() ?? '',
      lastName: source['lastName']?.toString() ?? '',
      role: isCollab ? 'COMPANY' : (source['role']?.toString() ?? 'USER'),
      hasCompany: source['hasCompany'] as bool? ?? (source['company'] != null),
      avatarUrl: source['avatarUrl'] as String?,
      company: source['company'] != null && source['company'] is Map
          ? CompanyModel.fromJson(Map<String, dynamic>.from(source['company']))
          : null,
      identification: source['identification'] as String?,
      phone: source['phone'] as String?,
      isActive: source['isActive'] is bool ? source['isActive'] as bool : true,
      accountSuspendedUntil: source['accountSuspendedUntil'] != null
          ? DateTime.tryParse(source['accountSuspendedUntil'].toString())
          : null,
      accountSuspensionReason: source['accountSuspensionReason'] as String?,
      googleId: source['googleId'] as String?,
      isCollaborator: isCollab,
      accessId: accessIdStr,
      collaboratorRole: roleName,
      permissions: permissionsList,
      allowedBranchIds: allowedBranchIdsList,
      hasFullBranchAccess: source['hasFullBranchAccess'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'hasCompany': hasCompany,
      'avatarUrl': avatarUrl,
      'company': company != null ? (company as CompanyModel).toJson() : null,
      'identification': identification,
      'phone': phone,
      'isActive': isActive,
      'accountSuspendedUntil': accountSuspendedUntil?.toIso8601String(),
      'accountSuspensionReason': accountSuspensionReason,
      'googleId': googleId,
      'isCollaborator': isCollaborator,
      'accessId': accessId,
      'collaboratorRole': collaboratorRole,
      'permissions': permissions,
      'allowedBranchIds': allowedBranchIds,
      'hasFullBranchAccess': hasFullBranchAccess,
    };
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? role,
    bool? hasCompany,
    Company? company,
    String? identification,
    String? phone,
    bool? isActive,
    DateTime? accountSuspendedUntil,
    String? accountSuspensionReason,
    String? googleId,
    bool? isCollaborator,
    String? accessId,
    String? collaboratorRole,
    List<String>? permissions,
    List<String>? allowedBranchIds,
    bool? hasFullBranchAccess,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      hasCompany: hasCompany ?? this.hasCompany,
      company: company ?? this.company,
      identification: identification ?? this.identification,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      accountSuspendedUntil: accountSuspendedUntil ?? this.accountSuspendedUntil,
      accountSuspensionReason: accountSuspensionReason ?? this.accountSuspensionReason,
      googleId: googleId ?? this.googleId,
      isCollaborator: isCollaborator ?? this.isCollaborator,
      accessId: accessId ?? this.accessId,
      collaboratorRole: collaboratorRole ?? this.collaboratorRole,
      permissions: permissions ?? this.permissions,
      allowedBranchIds: allowedBranchIds ?? this.allowedBranchIds,
      hasFullBranchAccess: hasFullBranchAccess ?? this.hasFullBranchAccess,
    );
  }
}
