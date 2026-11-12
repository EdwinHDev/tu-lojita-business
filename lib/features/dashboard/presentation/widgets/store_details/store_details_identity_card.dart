import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import '../home/home_image_resolver.dart';

/// Borderless Bento identity card for a single store branch.
class StoreDetailsIdentityCard extends StatelessWidget {
  final Store store;
  final int? dashboardTotalItems;

  const StoreDetailsIdentityCard({
    super.key,
    required this.store,
    this.dashboardTotalItems,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = store.status.toUpperCase();
    final isSuspended = normalizedStatus == 'SUSPENDED';
    final isInactive = normalizedStatus == 'INACTIVE';
    final isActive = !isSuspended && !isInactive;
    final shouldShowBranch = store.shouldShowBranch;
    final subcategoryName = store.subcategory?.name.trim();
    final allowsInstallments = store.allowPartialPayments;
    final maxInstallments = store.maxInstallments;
    final productsCount = store.productsCount > 0
        ? store.productsCount
        : (dashboardTotalItems ?? 0);
    final logoUrl = resolveDashboardImageUrl(store.logo);
    final phone = store.phone.trim();
    final address = store.address?.trim() ?? '';
    final hasContactInfo = phone.isNotEmpty || address.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Borderless square-rounded brand logo
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 56,
                  height: 56,
                  color: TuLojitaBrandColors.indigo50,
                  child: logoUrl.isNotEmpty
                      ? Image.network(
                          logoUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedStore01,
                              color: TuLojitaBrandColors.indigo600,
                              size: 26,
                            ),
                          ),
                        )
                      : const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedStore01,
                            color: TuLojitaBrandColors.indigo600,
                            size: 26,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shouldShowBranch ? store.branchLabel : store.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.inkPrimary,
                        letterSpacing: -0.4,
                        height: 1.15,
                      ),
                    ),
                    if (shouldShowBranch) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tienda: ${store.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: TuLojitaBrandColors.indigo600,
                        ),
                      ),
                    ],
                    if (subcategoryName != null && subcategoryName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedTag01,
                            color: TuLojitaBrandColors.inkSecondary,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              subcategoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
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
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _IdentityChip(
                icon: isActive
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : isSuspended
                        ? Icons.block_rounded
                        : Icons.pause_circle_rounded,
                isMaterialIcon: !isActive,
                label: isActive
                    ? 'Activa'
                    : isSuspended
                        ? 'Suspendida'
                        : 'Desactivada',
                textColor: isActive
                    ? TuLojitaBrandColors.positive
                    : isSuspended
                        ? TuLojitaBrandColors.danger
                        : TuLojitaBrandColors.amber800,
                bgColor: isActive
                    ? TuLojitaBrandColors.positiveBg
                    : isSuspended
                        ? TuLojitaBrandColors.dangerBg
                        : TuLojitaBrandColors.amber100,
                borderColor: isActive
                    ? const Color(0xFFA7F3D0)
                    : isSuspended
                        ? const Color(0xFFFECACA)
                        : TuLojitaBrandColors.amber400,
              ),
              _IdentityChip(
                icon: allowsInstallments
                    ? HugeIcons.strokeRoundedCreditCard
                    : HugeIcons.strokeRoundedMoney01,
                label: allowsInstallments
                    ? 'En cuotas ($maxInstallments)'
                    : 'Solo Contado',
                textColor: allowsInstallments
                    ? TuLojitaBrandColors.indigo700
                    : TuLojitaBrandColors.inkSecondary,
                bgColor: allowsInstallments
                    ? TuLojitaBrandColors.indigo50
                    : TuLojitaBrandColors.canvas,
                borderColor: allowsInstallments
                    ? TuLojitaBrandColors.indigo100
                    : TuLojitaBrandColors.borderMuted,
              ),
              _IdentityChip(
                icon: HugeIcons.strokeRoundedPackage,
                label:
                    '$productsCount ${productsCount == 1 ? 'Producto' : 'Productos'}',
                textColor: TuLojitaBrandColors.indigo700,
                bgColor: TuLojitaBrandColors.indigo50,
                borderColor: TuLojitaBrandColors.indigo100,
              ),
            ],
          ),
          if (hasContactInfo) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: TuLojitaBrandColors.borderSubtle),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (phone.isNotEmpty)
                  _CompactContactItem(
                    icon: HugeIcons.strokeRoundedCall02,
                    text: phone,
                  ),
                if (address.isNotEmpty)
                  _CompactContactItem(
                    icon: HugeIcons.strokeRoundedLocation01,
                    text: address,
                  ),
              ],
            ),
          ],
          if (isInactive) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.amber50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TuLojitaBrandColors.amber400,
                  width: 1,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: TuLojitaBrandColors.amber800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta tienda está desactivada. Ni la tienda ni sus artículos son visibles para los clientes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: TuLojitaBrandColors.amber800,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactContactItem extends StatelessWidget {
  final dynamic icon;
  final String text;

  const _CompactContactItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          color: TuLojitaBrandColors.inkSecondary,
          size: 13,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: TuLojitaBrandColors.inkSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityChip extends StatelessWidget {
  final dynamic icon;
  final bool isMaterialIcon;
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  const _IdentityChip({
    required this.icon,
    this.isMaterialIcon = false,
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMaterialIcon)
            Icon(icon as IconData, color: textColor, size: 14)
          else
            HugeIcon(icon: icon, color: textColor, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
