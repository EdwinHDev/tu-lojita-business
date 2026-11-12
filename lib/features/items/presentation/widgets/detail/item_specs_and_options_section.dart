import 'package:flutter/material.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'item_detail_helpers.dart';

/// Modular Bento cards for description, technical specifications, and
/// customization option groups with dual-currency (`USD + ~ Bs.`) surcharges.
class ItemSpecsAndOptionsSection extends StatelessWidget {
  final Item item;

  const ItemSpecsAndOptionsSection({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final rawProps = item.attributes?['properties'];
    final props = rawProps is List
        ? rawProps
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['key'] != null && '${e['value'] ?? ''}'.isNotEmpty)
            .toList()
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.description_outlined,
          title: 'Descripción del Artículo',
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: itemBentoCardDecoration(),
          child: Text(
            item.description.trim().isNotEmpty
                ? item.description.trim()
                : 'Sin descripción registrada.',
            style: const TextStyle(
              fontSize: 14,
              color: TuLojitaBrandColors.inkSecondary,
              height: 1.5,
            ),
          ),
        ),
        if (props.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionTitle(
            icon: Icons.tune_outlined,
            title: 'Especificaciones Técnicas',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: itemBentoCardDecoration(),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: props
                  .map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: TuLojitaBrandColors.canvas,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: TuLojitaBrandColors.borderMuted),
                      ),
                      child: Text(
                        '${p['key']}: ${p['value']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TuLojitaBrandColors.inkPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (item.customizationGroups.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SectionTitle(
            icon: Icons.playlist_add_check_rounded,
            title: 'Grupos de Personalización',
          ),
          const SizedBox(height: 8),
          for (final group in item.customizationGroups) ...[
            _CustomizationGroupCard(group: group),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: TuLojitaBrandColors.indigo600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: TuLojitaBrandColors.inkPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomizationGroupCard extends StatelessWidget {
  final CustomizationGroup group;

  const _CustomizationGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final isRequired = group.minSelect > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: itemBentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isRequired
                          ? TuLojitaBrandColors.amber50
                          : TuLojitaBrandColors.borderSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isRequired
                            ? TuLojitaBrandColors.amber400
                            : TuLojitaBrandColors.borderMuted,
                      ),
                    ),
                    child: Text(
                      isRequired ? 'Obligatorio' : 'Opcional',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isRequired
                            ? TuLojitaBrandColors.amber800
                            : TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Máx. ${group.maxSelect}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (group.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: TuLojitaBrandColors.borderSubtle),
            const SizedBox(height: 8),
            for (final opt in group.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: TuLojitaBrandColors.indigo500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        opt.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TuLojitaBrandColors.inkPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (opt.price > 0)
                      Flexible(
                        child: DualPriceText(
                          amountInUsd: opt.price,
                          prefix: '+',
                          crossAxisAlignment: CrossAxisAlignment.end,
                          useScaleDown: true,
                          usdStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TuLojitaBrandColors.indigo600,
                          ),
                          bsStyle: const TextStyle(
                            fontSize: 11,
                            color: TuLojitaBrandColors.inkSecondary,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Incluido',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TuLojitaBrandColors.positive,
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
