import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';

/// A widget that renders [child] if the current authenticated user has the specified [permission],
/// or if the user is the company owner (non-collaborator).
/// Otherwise, renders [fallback] or [SizedBox.shrink].
class PermissionGate extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is Authenticated) {
      if (authState.user.hasPermission(permission)) {
        return child;
      }
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// A widget that renders [child] only if the user is authorized to access [storeId].
class BranchGate extends ConsumerWidget {
  final String storeId;
  final Widget child;
  final Widget? fallback;

  const BranchGate({
    super.key,
    required this.storeId,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is Authenticated) {
      if (authState.user.canAccessBranch(storeId)) {
        return child;
      }
    }

    return fallback ?? const SizedBox.shrink();
  }
}
