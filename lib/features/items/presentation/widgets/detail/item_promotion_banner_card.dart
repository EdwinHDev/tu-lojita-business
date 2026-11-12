import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_promotion_provider.dart';

/// Live featured showcase promotion status card, hidden when the user lacks
/// `inventory:edit` permission.
class ItemPromotionBannerCard extends ConsumerWidget {
  final Item item;
  final bool canEditProducts;
  final VoidCallback onPromote;

  const ItemPromotionBannerCard({
    super.key,
    required this.item,
    required this.canEditProducts,
    required this.onPromote,
  });

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canEditProducts) return const SizedBox.shrink();

    final promoAsync = ref.watch(itemPromotionByItemProvider(item.id));
    final promoInfo = promoAsync.asData?.value;

    final bool isActive =
        (promoInfo?.hasActivePromotion ?? false) || item.isFeatured;
    final Map<String, dynamic>? pending = promoInfo?.pendingPromotion;

    if (isActive) {
      final expiresLabel = _formatDate(promoInfo?.activePromotion?['expiresAt']);
      return InkWell(
        onTap: onPromote,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.amber50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TuLojitaBrandColors.amber400),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.amber100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: TuLojitaBrandColors.amber700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promoción Activa en el Home',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.amber800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiresLabel != null
                          ? 'Vigente hasta el $expiresLabel en la vitrina principal.'
                          : 'Este artículo está destacado actualmente en la vitrina.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TuLojitaBrandColors.amber700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TuLojitaBrandColors.amber700,
              ),
            ],
          ),
        ),
      );
    }

    if (pending != null) {
      final days = pending['durationDays'];
      return InkWell(
        onTap: onPromote,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.indigo50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TuLojitaBrandColors.indigo100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: TuLojitaBrandColors.indigo600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solicitud en revisión',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.indigo700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days != null
                          ? 'Estamos verificando tu pago para destacarlo ($days días).'
                          : 'Estamos verificando tu comprobante de promoción.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TuLojitaBrandColors.indigo600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TuLojitaBrandColors.indigo600,
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onPromote,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFFFFBEB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TuLojitaBrandColors.indigo100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.amber100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: TuLojitaBrandColors.amber700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promocionar en el Home',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: TuLojitaBrandColors.inkPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Destaca este artículo en la vitrina principal y multiplica visitas.',
                    style: TextStyle(
                      fontSize: 12,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: TuLojitaBrandColors.indigo600,
            ),
          ],
        ),
      ),
    );
  }
}
