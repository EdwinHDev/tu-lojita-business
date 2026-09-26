import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ranking_providers.dart';
import 'division_emblem_widget.dart';

class StoreRankHeaderCard extends ConsumerWidget {
  final String storeId;

  const StoreRankHeaderCard({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(storeRankingProvider(storeId));

    return rankingAsync.when(
      data: (ranking) {
        final title = ranking.divisionTitle.isNotEmpty
            ? ranking.divisionTitle
            : DivisionEmblemWidget.getTitle(ranking.division);
        final nextThreshold = ranking.nextTierThreshold ?? 3400;
        final progress = (nextThreshold > 0)
            ? (ranking.currentPR / nextThreshold).clamp(0.0, 1.0)
            : 1.0;

        return InkWell(
          onTap: () => context.push('/dashboard/stores/$storeId/ranking'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1B4B), // Deep indigo
                  const Color(0xFF312E81),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 3D Emblem with subtle glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: DivisionEmblemWidget(
                        division: ranking.division,
                        size: 54,
                        customUrl: ranking.divisionEmblemUrl,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Tier Title & PR Points
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'RANGO',
                                style: TextStyle(
                                  color: Colors.amber.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              if (ranking.consecutiveSalesDays > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade800
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.shade400,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🔥',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${ranking.consecutiveSalesDays}d (${ranking.streakMultiplier}x)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ranking.currentPR} PR Acumulados',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // PR Progress Bar towards Next Tier
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF59E0B), // Vibrant Amber
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Next milestone text / Badges (Shield, Danger)
                Row(
                  children: [
                    if (ranking.inDangerZone) ...[
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        '¡Zona de Peligro! Vende hoy',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else if (ranking.isShieldActive) ...[
                      const Icon(Icons.shield_outlined,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        'Escudo de Rango activo (48h)',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (ranking.nextDivisionTitle != null) ...[
                      Text(
                        'A ${ranking.pointsToNextTier} PR de ${ranking.nextDivisionTitle}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '¡Rango Máximo Alcanzado!',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Ver detalles',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
