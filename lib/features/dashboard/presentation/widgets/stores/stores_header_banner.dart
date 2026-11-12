import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

/// Integrated Bento header for the `Tiendas` tab replacing the legacy
/// `"Dashboard"` shell `AppBar` and floating action button.
class StoresHeaderBanner extends ConsumerWidget {
  final int storeCount;
  final bool canManageBranches;
  final VoidCallback onCreateStore;

  const StoresHeaderBanner({
    super.key,
    required this.storeCount,
    required this.canManageBranches,
    required this.onCreateStore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final config = ref.watch(exchangeRateProvider).asData?.value;
    final showBcvPill = config != null && PriceFormatter.isDualEnabled(config);

    final title = storeCount == 1 ? 'Mi Tienda' : 'Mis Tiendas';
    final subtitle = storeCount == 0
        ? 'Sin sucursales asignadas'
        : (storeCount == 1
            ? '1 sucursal autorizada'
            : '$storeCount sucursales autorizadas');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
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
            const SizedBox(width: 8),
            if (canManageBranches) ...[
              Material(
                color: TuLojitaBrandColors.indigo600,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onCreateStore,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Text(
                      '+ Nueva',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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
        ),
        if (showBcvPill) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TuLojitaBrandColors.borderMuted),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedDollarCircle,
                  color: TuLojitaBrandColors.indigo600,
                  size: 13,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tasa BCV: ${PriceFormatter.formatRateValue(config.rate, symbol: config.symbol)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
