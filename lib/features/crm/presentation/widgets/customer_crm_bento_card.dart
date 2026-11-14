import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import '../../domain/entities/crm_entities.dart';
import 'crm_action_helpers.dart';

class CustomerCrmBentoCard extends ConsumerWidget {
  final CrmCustomer customer;
  final bool canManageCrm;
  final VoidCallback onOpenDetail;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onSendOffer;

  const CustomerCrmBentoCard({
    super.key,
    required this.customer,
    required this.canManageCrm,
    required this.onOpenDetail,
    this.onWhatsApp,
    this.onSendOffer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segMeta = crmSegmentMeta(customer.segment);
    final initials = customer.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final resolvedAvatarUrl = resolveCrmImageUrl(customer.avatarUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final isCompact = constraints.maxWidth < 340 || textScale >= 1.2;

            final segmentBadge = Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: segMeta.bgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(segMeta.icon, size: 12, color: segMeta.color),
                  const SizedBox(width: 4),
                  Text(
                    segMeta.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: segMeta.color,
                    ),
                  ),
                ],
              ),
            );

            final ltvMetric = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LTV Total',
                  style: TextStyle(
                    fontSize: 11,
                    color: TuLojitaBrandColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                DualPriceText(
                  amountInUsd: customer.ltvUsd,
                  usdStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                  bsStyle: const TextStyle(
                    fontSize: 10.5,
                    color: TuLojitaBrandColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );

            final ordersMetric = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pedidos',
                  style: TextStyle(
                    fontSize: 11,
                    color: TuLojitaBrandColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${customer.ordersCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ],
            );

            final rightMetric = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.pendingDebtUsd > 0 ? 'Deuda' : 'Favoritos',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TuLojitaBrandColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (customer.pendingDebtUsd > 0)
                  DualPriceText(
                    amountInUsd: customer.pendingDebtUsd,
                    usdStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TuLojitaBrandColors.danger,
                    ),
                    bsStyle: const TextStyle(
                      fontSize: 10.5,
                      color: TuLojitaBrandColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: customer.favoritesCount > 0
                            ? const Color(0xFFDB2777)
                            : TuLojitaBrandColors.inkSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${customer.favoritesCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            );

            final whatsappPill = customer.phone.isNotEmpty
                ? _ActionPill(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: TuLojitaBrandColors.positive,
                    bg: TuLojitaBrandColors.positiveBg,
                    onTap: onWhatsApp ??
                        () => openWhatsAppTemplateSheet(context, customer),
                  )
                : null;

            final secondaryPrimaryPill =
                canManageCrm && customer.topFavoriteItems.isNotEmpty
                    ? _ActionPill(
                        icon: Icons.local_offer_outlined,
                        label: 'Oferta (${customer.favoritesCount})',
                        color: TuLojitaBrandColors.amber800,
                        bg: TuLojitaBrandColors.amber100,
                        onTap: onSendOffer ?? onOpenDetail,
                      )
                    : _ActionPill(
                        icon: Icons.chevron_right_rounded,
                        label: 'Ficha',
                        color: TuLojitaBrandColors.indigo700,
                        bg: TuLojitaBrandColors.indigo50,
                        onTap: onOpenDetail,
                      );

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: customer.hasOverdueFollowUp
                      ? TuLojitaBrandColors.danger.withValues(alpha: 0.45)
                      : TuLojitaBrandColors.borderMuted,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: TuLojitaBrandColors.indigo50,
                        backgroundImage: resolvedAvatarUrl != null
                            ? NetworkImage(resolvedAvatarUrl)
                            : null,
                        onBackgroundImageError:
                            resolvedAvatarUrl != null ? (_, _) {} : null,
                        child: resolvedAvatarUrl == null
                            ? Text(
                                initials.isEmpty ? 'CL' : initials,
                                style: const TextStyle(
                                  color: TuLojitaBrandColors.indigo700,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCompact) ...[
                              Text(
                                customer.fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: TuLojitaBrandColors.inkPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              segmentBadge,
                            ] else
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      customer.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: TuLojitaBrandColors.inkPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  segmentBadge,
                                ],
                              ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 8,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (customer.identification.isNotEmpty)
                                  Text(
                                    customer.identification,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TuLojitaBrandColors.inkSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (customer.phone.isNotEmpty)
                                  Text(
                                    customer.phone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TuLojitaBrandColors.inkSecondary,
                                    ),
                                  ),
                                if (customer.totalBuyerReviews > 0 ||
                                    customer.averageBuyerRating > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: TuLojitaBrandColors.amber500,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        customer.averageBuyerRating
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: TuLojitaBrandColors.inkPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (customer.primaryAddress != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${customer.primaryAddress!.title}: ${customer.primaryAddress!.fullAddress}',
                            maxLines: isCompact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (customer.affiliatedStores.isNotEmpty ||
                      customer.tags.isNotEmpty ||
                      customer.hasOverdueFollowUp) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...customer.affiliatedStores.take(3).map(
                              (st) => _SmallChip(
                                icon: Icons.storefront_outlined,
                                label: st.displayName,
                                color: st.isBlocked
                                    ? TuLojitaBrandColors.danger
                                    : TuLojitaBrandColors.indigo700,
                                bg: st.isBlocked
                                    ? TuLojitaBrandColors.dangerBg
                                    : TuLojitaBrandColors.indigo50,
                              ),
                            ),
                        if (customer.hasOverdueFollowUp)
                          const _SmallChip(
                            icon: Icons.notifications_active_outlined,
                            label: 'Seguimiento vencido',
                            color: TuLojitaBrandColors.danger,
                            bg: TuLojitaBrandColors.dangerBg,
                          ),
                        ...customer.tags.take(3).map(
                              (tag) => _SmallChip(
                                icon: Icons.label_outline,
                                label: tag,
                                color: TuLojitaBrandColors.inkPrimary,
                                bg: TuLojitaBrandColors.borderSubtle,
                              ),
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TuLojitaBrandColors.canvas,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: TuLojitaBrandColors.borderSubtle),
                    ),
                    child: isCompact
                        ? Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: ((constraints.maxWidth - 64) / 2)
                                      .clamp(92.0, 220.0),
                                ),
                                child: ltvMetric,
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: ((constraints.maxWidth - 64) / 2)
                                      .clamp(80.0, 180.0),
                                ),
                                child: ordersMetric,
                              ),
                              rightMetric,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(flex: 3, child: ltvMetric),
                              Expanded(flex: 2, child: ordersMetric),
                              Expanded(flex: 3, child: rightMetric),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (isCompact)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ?whatsappPill,
                        secondaryPrimaryPill,
                        if (customer.phone.isNotEmpty)
                          _IconSquareBtn(
                            icon: Icons.call_outlined,
                            tooltip: 'Llamar',
                            onTap: () =>
                                callCustomerPhone(context, customer.phone),
                          ),
                        if (customer.primaryAddress != null)
                          _IconSquareBtn(
                            icon: Icons.map_outlined,
                            tooltip: 'Mapa GPS',
                            onTap: () => openCustomerLocationMap(
                              context,
                              customer.primaryAddress!,
                            ),
                          ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        if (whatsappPill != null) Expanded(child: whatsappPill),
                        if (customer.phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _IconSquareBtn(
                            icon: Icons.call_outlined,
                            tooltip: 'Llamar',
                            onTap: () =>
                                callCustomerPhone(context, customer.phone),
                          ),
                        ],
                        if (customer.primaryAddress != null) ...[
                          if (customer.phone.isNotEmpty)
                            const SizedBox(width: 8),
                          _IconSquareBtn(
                            icon: Icons.map_outlined,
                            tooltip: 'Mapa GPS',
                            onTap: () => openCustomerLocationMap(
                              context,
                              customer.primaryAddress!,
                            ),
                          ),
                        ],
                        if (customer.phone.isNotEmpty ||
                            customer.primaryAddress != null)
                          const SizedBox(width: 8),
                        Expanded(child: secondaryPrimaryPill),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const _SmallChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSquareBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconSquareBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.canvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TuLojitaBrandColors.borderMuted),
          ),
          child: Icon(
            icon,
            size: 17,
            color: TuLojitaBrandColors.inkPrimary,
          ),
        ),
      ),
    );
  }
}
