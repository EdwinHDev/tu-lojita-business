import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/models/exchange_rate_config.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_image_resolver.dart';

/// Pure standalone-safe single-tap Bento store scorecard.
///
/// Formats dual currency via pure [PriceFormatter] utilities without requiring
/// `ProviderScope` so both full Views and bare `MaterialApp` widget tests work.
class StoreListTile extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;
  final ExchangeRateConfig? exchangeConfig;
  final int unreadDisputesCount;
  final bool canViewFinancials;

  const StoreListTile({
    super.key,
    required this.store,
    required this.onTap,
    this.exchangeConfig,
    this.unreadDisputesCount = 0,
    this.canViewFinancials = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDeleting = store.isScheduledForDeletion;
    final isInactive = store.status.toUpperCase() == 'INACTIVE' && !isDeleting;
    final logoUrl = resolveDashboardImageUrl(store.logo);

    final String chipLabel;
    final Color chipBgColor;
    final Color chipTextColor;

    if (isDeleting) {
      chipLabel = 'Eliminación en ${store.remainingGraceDays}d';
      chipBgColor = TuLojitaBrandColors.dangerBg;
      chipTextColor = TuLojitaBrandColors.danger;
    } else if (isInactive) {
      chipLabel = 'Desactivada';
      chipBgColor = TuLojitaBrandColors.amber100;
      chipTextColor = TuLojitaBrandColors.amber800;
    } else {
      chipLabel = 'Activa';
      chipBgColor = TuLojitaBrandColors.positiveBg;
      chipTextColor = TuLojitaBrandColors.positive;
    }

    final urgencyBadges = <Widget>[
      if (store.pendingOrdersCount > 0)
        _VisualUrgencyPill(
          icon: HugeIcons.strokeRoundedPackage,
          label: store.pendingOrdersCount == 1
              ? '1 ped. pend.'
              : '${store.pendingOrdersCount} ped. pend.',
          isCritical: false,
        ),
      if (unreadDisputesCount > 0)
        _VisualUrgencyPill(
          icon: HugeIcons.strokeRoundedAlertCircle,
          label: unreadDisputesCount == 1
              ? '1 reclamo'
              : '$unreadDisputesCount reclamos',
          isCritical: true,
        ),
      if (canViewFinancials && store.commissionDebt > 0)
        _VisualUrgencyPill(
          icon: HugeIcons.strokeRoundedInvoice01,
          label:
              'Comisión: ${PriceFormatter.formatDualInline(store.commissionDebt, exchangeConfig)}',
          isCritical: false,
        ),
      if (canViewFinancials && store.pendingCommissionReportsCount > 0)
        _VisualUrgencyPill(
          icon: HugeIcons.strokeRoundedInvoice01,
          label: store.pendingCommissionReportsCount == 1
              ? '1 pago rev.'
              : '${store.pendingCommissionReportsCount} pagos rev.',
          isCritical: false,
        ),
      if (store.inDangerZone)
        const _VisualUrgencyPill(
          icon: HugeIcons.strokeRoundedAlert02,
          label: 'En riesgo',
          isCritical: true,
        ),
    ];

    final footerParts = <String>[
      if (store.rankingDivisionTitle != null &&
          store.rankingDivisionTitle!.trim().isNotEmpty)
        store.currentPR > 0
            ? '${store.rankingDivisionTitle!.trim()} (${store.currentPR} PR)'
            : store.rankingDivisionTitle!.trim(),
      if (store.consecutiveSalesDays > 0) '${store.consecutiveSalesDays}d racha',
      if (store.aiEnabled) 'Estudio IA',
    ];
    final footerText = footerParts.isEmpty ? null : footerParts.join(' · ');
    final salesLines =
        PriceFormatter.formatDualLines(store.salesToday, exchangeConfig);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDeleting
                    ? const Color(0xFFFECACA)
                    : TuLojitaBrandColors.borderSubtle,
                width: isDeleting ? 1.6 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDeleting
                      ? const Color(0xFFEF4444).withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean borderless store logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: TuLojitaBrandColors.indigo50,
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedStore01,
                                    color: TuLojitaBrandColors.indigo600,
                                    size: 22,
                                  ),
                                ),
                              )
                            : const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedStore01,
                                  color: TuLojitaBrandColors.indigo600,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  store.shouldShowBranch
                                      ? store.branchLabel
                                      : store.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    letterSpacing: -0.3,
                                    color: TuLojitaBrandColors.inkPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                color: TuLojitaBrandColors.inkSecondary,
                                size: 17,
                              ),
                            ],
                          ),
                          if (store.shouldShowBranch) ...[
                            const SizedBox(height: 1),
                            Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TuLojitaBrandColors.indigo600,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (store.address != null &&
                              store.address!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              store.address!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TuLojitaBrandColors.inkSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _StatusChip(
                                label: chipLabel,
                                bgColor: chipBgColor,
                                textColor: chipTextColor,
                              ),
                              Text(
                                '${store.productsCount} productos',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: TuLojitaBrandColors.inkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (canViewFinancials) ...[
                  const SizedBox(height: 11),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Ventas hoy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: TuLojitaBrandColors.inkSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                salesLines[0],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: TuLojitaBrandColors.indigo600,
                                ),
                              ),
                              if (salesLines.length > 1)
                                Text(
                                  salesLines[1],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: TuLojitaBrandColors.inkSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (urgencyBadges.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: urgencyBadges,
                  ),
                ],

                if (footerText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 1,
                    color: TuLojitaBrandColors.borderSubtle,
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAward01,
                        color: TuLojitaBrandColors.amber700,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          footerText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: TuLojitaBrandColors.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _StatusChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualUrgencyPill extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isCritical;

  const _VisualUrgencyPill({
    required this.icon,
    required this.label,
    required this.isCritical,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isCritical
        ? TuLojitaBrandColors.dangerBg
        : TuLojitaBrandColors.amber50;
    final border = isCritical
        ? const Color(0xFFFECACA)
        : TuLojitaBrandColors.amber100;
    final fg = isCritical
        ? TuLojitaBrandColors.danger
        : TuLojitaBrandColors.amber800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: fg, size: 12),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
