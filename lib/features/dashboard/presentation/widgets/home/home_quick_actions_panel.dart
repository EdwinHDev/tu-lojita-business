import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';

/// Early horizontal Bento strip (`Accesos de Empresa`) exposing strictly
/// company-wide and account-level destinations filtered by user permissions.
class HomeQuickActionsPanel extends ConsumerWidget {
  final List<Store> stores;
  final String selectedStoreId;

  const HomeQuickActionsPanel({
    super.key,
    required this.stores,
    required this.selectedStoreId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final isCollaborator = user?.isCollaborator ?? false;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.35);

    final actions = <_BentoShortcutData>[
      // 1. Tiendas (hub explícito de sucursales)
      _BentoShortcutData(
        label: 'Tiendas',
        icon: HugeIcons.strokeRoundedStore01,
        useAmberAccent: false,
        onTap: () => ref.read(dashboardIndexProvider.notifier).state = 1,
      ),
    ];

    // 2. Nueva Sede
    if (!isCollaborator || (user != null && user.canManageBranches)) {
      actions.add(
        _BentoShortcutData(
          label: 'Nueva Sede',
          icon: HugeIcons.strokeRoundedAdd01,
          useAmberAccent: false,
          onTap: () => context.go('/dashboard/stores/create'),
        ),
      );
    }

    // 3. Equipo
    if (!isCollaborator ||
        (user != null &&
            (user.canManageTeam ||
                user.hasPermission('collaborators:view') ||
                user.hasPermission('team:view') ||
                user.hasPermission('roles:manage')))) {
      actions.add(
        _BentoShortcutData(
          label: 'Equipo',
          icon: HugeIcons.strokeRoundedUserGroup,
          useAmberAccent: false,
          onTap: () => context.push('/dashboard/settings/team'),
        ),
      );
    }

    // 4. Actividad (solo dueño de empresa)
    if (!isCollaborator) {
      actions.add(
        _BentoShortcutData(
          label: 'Actividad',
          icon: HugeIcons.strokeRoundedTime04,
          useAmberAccent: false,
          onTap: () => context.push('/dashboard/settings/activity-log'),
        ),
      );
    }

    // 5. Alertas (inbox consolidado)
    actions.add(
      _BentoShortcutData(
        label: 'Alertas',
        icon: HugeIcons.strokeRoundedNotification01,
        useAmberAccent: true,
        onTap: () => context.go('/dashboard/notifications'),
      ),
    );

    // 6. Mi Empresa (identidad corporativa)
    if (!isCollaborator ||
        (user != null && user.hasPermission('settings:manage'))) {
      actions.add(
        _BentoShortcutData(
          label: 'Mi Empresa',
          icon: HugeIcons.strokeRoundedSettings03,
          useAmberAccent: false,
          onTap: () => context.push('/dashboard/settings/company'),
        ),
      );
    }

    final double stripHeight = (94.0 * textScale).clamp(92.0, 132.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos de Empresa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: TuLojitaBrandColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: stripHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _BentoShortcutCard(
              data: actions[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _BentoShortcutData {
  final String label;
  final dynamic icon;
  final bool useAmberAccent;
  final VoidCallback onTap;

  const _BentoShortcutData({
    required this.label,
    required this.icon,
    required this.useAmberAccent,
    required this.onTap,
  });
}

class _BentoShortcutCard extends StatelessWidget {
  final _BentoShortcutData data;

  const _BentoShortcutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bgTint = data.useAmberAccent
        ? TuLojitaBrandColors.amber50
        : TuLojitaBrandColors.indigo50;
    final iconColor = data.useAmberAccent
        ? TuLojitaBrandColors.amber700
        : TuLojitaBrandColors.indigo600;

    return Material(
      color: TuLojitaBrandColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TuLojitaBrandColors.borderSubtle,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: data.icon,
                  color: iconColor,
                  size: 19,
                ),
              ),
              const SizedBox(height: 7),
              Flexible(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
