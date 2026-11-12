import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

class HomeHeaderBanner extends ConsumerWidget {
  final String userName;
  final String companyLogoUrl;
  final bool isCollaborator;
  final String? collaboratorRole;
  final String? activeScopeLabel;

  const HomeHeaderBanner({
    super.key,
    required this.userName,
    required this.companyLogoUrl,
    this.isCollaborator = false,
    this.collaboratorRole,
    this.activeScopeLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final subtitle = isCollaborator
        ? (collaboratorRole != null
            ? 'Rol: $collaboratorRole • Panel Operativo'
            : 'Panel Operativo en Sucursales')
        : (activeScopeLabel != null && activeScopeLabel!.isNotEmpty
            ? activeScopeLabel!
            : 'Rendimiento en tiempo real');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hola, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: TuLojitaBrandColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (companyLogoUrl.isNotEmpty) ...[
          ClipOval(
            child: Image.network(
              companyLogoUrl,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 38,
                height: 38,
                color: TuLojitaBrandColors.indigo50,
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedStore01,
                  color: TuLojitaBrandColors.indigo600,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: TuLojitaBrandColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go('/dashboard/notifications'),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TuLojitaBrandColors.borderMuted,
                    width: 1,
                  ),
                ),
                child: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: TuLojitaBrandColors.danger,
                  offset: const Offset(2, -4),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: TuLojitaBrandColors.indigo600,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
