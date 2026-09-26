import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/envs.dart';
import '../providers/ranking_providers.dart';
import '../../domain/entities/ranking_models.dart';
import 'ranking_shimmer_skeleton.dart';

class DailyMissionsCard extends ConsumerWidget {
  final String storeId;

  const DailyMissionsCard({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(dailyMissionsProvider(storeId));

    return missionsAsync.when(
      data: (missions) {
        if (missions.isEmpty) return const SizedBox.shrink();

        final completedCount = missions.where((m) => m.isCompleted).length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Misiones Diarias del Comerciante',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 11,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Se reinician a las 00:00',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: completedCount == missions.length
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount/${missions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: completedCount == missions.length
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Missions List
              ...missions.map((mission) => _buildMissionItem(context, ref, mission)),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMissionItem(
    BuildContext context,
    WidgetRef ref,
    DailyMissionItem mission,
  ) {
    final isDone = mission.isCompleted;
    final isClaimed = mission.isClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimed
            ? const Color(0xFFF8FAFC)
            : isDone
                ? const Color(0xFFF0FDF4)
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isClaimed
              ? const Color(0xFFE2E8F0)
              : isDone
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFE2E8F0),
          width: isDone && !isClaimed ? 1.5 : 1,
        ),
        boxShadow: isDone && !isClaimed
            ? [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 3D Gamified Mission Badge
          _buildMissionEmblem(mission, isDone, isClaimed),
          const SizedBox(width: 12),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isClaimed
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    decoration:
                        isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isClaimed
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action / Reward Button
          if (isDone && !isClaimed)
            ElevatedButton(
              onPressed: () async {
                final success = await ref
                    .read(missionClaimNotifierProvider.notifier)
                    .claimMission(storeId, mission.code);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '¡Misión completada! +${mission.prReward} PR sumados 🎉',
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                '+${mission.prReward} PR',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isClaimed
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isClaimed ? 'Reclamado' : '+${mission.prReward} PR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isClaimed
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFB45309),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissionEmblem(
    DailyMissionItem mission,
    bool isDone,
    bool isClaimed,
  ) {
    final serverBaseUrl = Envs.apiBaseUrl.replaceAll('/api/v1', '');
    final placeholderSlug = _getMissionPlaceholderSlug(mission.code);
    final placeholderUrl =
        '$serverBaseUrl/assets/ranking/achievements/$placeholderSlug.png';

    // Normalize custom/payload badgeUrl if present
    String? normalizedBadgeUrl;
    if (mission.badgeUrl != null && mission.badgeUrl!.trim().isNotEmpty) {
      final trimmed = mission.badgeUrl!.trim();
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        normalizedBadgeUrl = trimmed;
      } else if (trimmed.startsWith('/')) {
        normalizedBadgeUrl = '$serverBaseUrl$trimmed';
      } else {
        normalizedBadgeUrl = '$serverBaseUrl/$trimmed';
      }
    }

    final targetUrl = normalizedBadgeUrl ?? placeholderUrl;

    Widget imageWidget = Image.network(
      targetUrl,
      width: 44,
      height: 44,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const RankingShimmerSkeleton(
          width: 44,
          height: 44,
          shape: BoxShape.circle,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // If custom URL failed, attempt default server placeholder
        if (targetUrl != placeholderUrl) {
          return Image.network(
            placeholderUrl,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const RankingShimmerSkeleton(
                width: 44,
                height: 44,
                shape: BoxShape.circle,
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackIcon(isDone, isClaimed),
          );
        }
        return _buildFallbackIcon(isDone, isClaimed);
      },
    );

    if (isClaimed) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: 0.45,
            child: imageWidget,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      );
    }

    if (isDone) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          imageWidget,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFFEAB308),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      );
    }

    return imageWidget;
  }

  Widget _buildFallbackIcon(bool isDone, bool isClaimed) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isClaimed
            ? const Color(0xFFF1F5F9)
            : isDone
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFEEF2FF),
      ),
      child: Icon(
        isClaimed
            ? Icons.check_circle_rounded
            : isDone
                ? Icons.card_giftcard_rounded
                : Icons.military_tech_rounded,
        size: 24,
        color: isClaimed
            ? const Color(0xFF94A3B8)
            : isDone
                ? const Color(0xFF16A34A)
                : const Color(0xFF4F46E5),
      ),
    );
  }

  static String _getMissionPlaceholderSlug(String code) {
    switch (code.toUpperCase()) {
      case 'VENTA_DEL_DIA':
        return 'first_step';
      case 'EXCELENCIA_5_ESTRELLAS':
        return 'five_stars';
      case 'VOLUMEN_COMERCIAL':
        return 'star_seller';
      default:
        return 'star_seller';
    }
  }
}
