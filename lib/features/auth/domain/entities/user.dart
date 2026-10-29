import 'package:tu_lojita_business/features/company_onboarding/domain/entities/company.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String role;
  final bool hasCompany;
  final Company? company;
  final String? identification;
  final String? phone;
  final bool isActive;
  final DateTime? accountSuspendedUntil;
  final String? accountSuspensionReason;
  final String? googleId;
  final bool isCollaborator;
  final String? accessId;
  final String? collaboratorRole;
  final List<String> permissions;
  final List<String> allowedBranchIds;
  final bool hasFullBranchAccess;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.hasCompany = false,
    this.avatarUrl,
    this.company,
    this.identification,
    this.phone,
    this.isActive = true,
    this.accountSuspendedUntil,
    this.accountSuspensionReason,
    this.googleId,
    this.isCollaborator = false,
    this.accessId,
    this.collaboratorRole,
    this.permissions = const [],
    this.allowedBranchIds = const [],
    this.hasFullBranchAccess = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isCredentialUser => googleId == null || googleId!.trim().isEmpty;

  bool hasPermission(String permission) {
    if (!isCollaborator) return true;
    return permissions.contains(permission);
  }

  bool canAccessBranch(String storeId) {
    if (!isCollaborator) return true;
    if (hasFullBranchAccess) return true;
    return allowedBranchIds.contains(storeId);
  }

  // --- Granular Permission Getters ---
  bool get canViewFinancialMetrics =>
      hasPermission('metrics:view_financial');

  bool get canViewSalesHistory =>
      hasPermission('metrics:view_sales_history') ||
      canViewFinancialMetrics;

  bool get canManageStock =>
      hasPermission('inventory:manage_stock') ||
      hasPermission('inventory:edit');

  bool get canChangePrices =>
      hasPermission('inventory:change_price') ||
      hasPermission('inventory:edit');

  bool get canEditProducts => hasPermission('inventory:edit');

  bool get canViewOrders => hasPermission('orders:view');

  bool get canProcessOrders => hasPermission('orders:process');

  bool get canCancelOrders => hasPermission('orders:cancel');

  bool get canChatWithCustomer => hasPermission('orders:chat');

  bool get canViewSensitiveCustomerData =>
      hasPermission('orders:view_customer_data');

  bool get canViewInstallments =>
      hasPermission('installments:view') ||
      hasPermission('installments:approve_payment');

  bool get canApproveInstallments =>
      hasPermission('installments:approve_payment');

  bool get canViewDisputes =>
      hasPermission('disputes:view') ||
      hasPermission('disputes:respond') ||
      hasPermission('disputes:resolve');

  bool get canResolveDisputes =>
      hasPermission('disputes:resolve') ||
      hasPermission('disputes:respond');

  bool get canManageBranches => hasPermission('branches:manage');

  bool get canManageTeam =>
      hasPermission('collaborators:manage') ||
      hasPermission('roles:manage') ||
      hasPermission('team:manage');

  bool get isAccountSuspended {
    if (!isActive) return true;
    if (accountSuspendedUntil != null) {
      return accountSuspendedUntil!.isAfter(DateTime.now());
    }
    return false;
  }

  User copyWith({
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
    return User(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'role': role,
      'hasCompany': hasCompany,
      'company': company?.toJson(),
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
}
