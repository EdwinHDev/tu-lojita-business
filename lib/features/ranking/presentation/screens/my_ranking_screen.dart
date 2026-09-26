import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ranking_providers.dart';
import '../widgets/division_emblem_widget.dart';
import '../widgets/daily_missions_card.dart';
import '../../domain/entities/ranking_models.dart';
import '../widgets/ranking_shimmer_skeleton.dart';
import 'package:tu_lojita_business/core/utils/achievement_image_helper.dart';

class MyRankingScreen extends ConsumerStatefulWidget {
  final String storeId;

  const MyRankingScreen({super.key, required this.storeId});

  @override
  ConsumerState<MyRankingScreen> createState() => _MyRankingScreenState();
}

class _MyRankingScreenState extends ConsumerState<MyRankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedShowcaseIds = {};
  bool _showcaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(storeRankingProvider(widget.storeId));
    ref.invalidate(storeEventsProvider(widget.storeId));
    ref.invalidate(storeAchievementsProvider(widget.storeId));
    ref.invalidate(dailyMissionsProvider(widget.storeId));
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(storeRankingProvider(widget.storeId));
    final eventsAsync = ref.watch(storeEventsProvider(widget.storeId));
    final achievementsAsync =
        ref.watch(storeAchievementsProvider(widget.storeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Rango & Progreso Comercial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF4F46E5),
        child: rankingAsync.when(
          data: (ranking) {
            if (!_showcaseInitialized && ranking.showcase.isNotEmpty) {
              _selectedShowcaseIds.addAll(ranking.showcase.map((a) => a.id));
              _showcaseInitialized = true;
            }

            return Column(
              children: [
                // Top Ranking Summary Card
                _buildHeaderCard(ranking),

                // Tabs: Misiones & Historial vs Logros & Vitrina
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: const Color(0xFF4F46E5),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Misiones & PR'),
                      Tab(text: 'Logros & Vitrina'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Daily Missions & PR History
                      _buildEventsTab(eventsAsync, ranking),

                      // Tab 2: Achievements and Showcase
                      _buildAchievementsTab(achievementsAsync),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo cargar la información del rango',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(StoreRankingData ranking) {
    final title = ranking.divisionTitle.isNotEmpty
        ? ranking.divisionTitle
        : DivisionEmblemWidget.getTitle(ranking.division);
    final nextThreshold = ranking.nextTierThreshold ?? 3400;
    final progress = (nextThreshold > 0)
        ? (ranking.currentPR / nextThreshold).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              // Large 3D Division Emblem
              DivisionEmblemWidget(
                division: ranking.division,
                size: 80,
                customUrl: ranking.divisionEmblemUrl,
              ),

              const SizedBox(width: 16),

              // Division & PR stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ranking.inCalibration)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: const Text(
                              'Calibración',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ranking.currentPR} PR Acumulados',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ranking.position > 0
                          ? 'Posición en la clasificación: #${ranking.position}'
                          : 'Posición no calculada',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar to next tier
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 6),

          // Milestone hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (ranking.nextDivisionTitle != null)
                Text(
                  'A ${ranking.pointsToNextTier} PR de ${ranking.nextDivisionTitle}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                )
              else
                const Text(
                  '¡Rango Máximo Alcanzado!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Retention Tags: Streak, Shield, Danger
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (ranking.consecutiveSalesDays > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDBA74)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Racha de ${ranking.consecutiveSalesDays} días (${ranking.streakMultiplier}x PR)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
              if (ranking.isShieldActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Escudo de Rango Activo (48h)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              if (ranking.inDangerZone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 14, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        'Zona de Peligro: Concreta ventas hoy',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (ranking.flaggedForReview) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ranking.flagReason ??
                          'Tu cuenta está en revisión preventiva por el sistema.',
                      style: const TextStyle(color: Colors.red, fontSize: 11),
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

  Widget _buildEventsTab(
    AsyncValue<List<RankingEventItem>> eventsAsync,
    StoreRankingData ranking,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Missions Section at top of Tab
        DailyMissionsCard(storeId: widget.storeId),
        const SizedBox(height: 20),

        const Text(
          'Historial Reciente de Puntos de Rango (PR)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No hay eventos registrados en los últimos 30 días.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ev = events[index];
                final isPositive = ev.lpDelta > 0;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: isPositive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getEventTitle(ev.eventType),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (ev.reason != null && ev.reason!.isNotEmpty)
                              Text(
                                ev.reason!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            Text(
                              '${ev.createdAt.day}/${ev.createdAt.month}/${ev.createdAt.year}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isPositive
                                ? '+${ev.lpDelta} PR'
                                : '${ev.lpDelta} PR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isPositive
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            'Total: ${ev.lpAfter} PR',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              const Center(child: Text('Error al cargar historial')),
        ),
      ],
    );
  }

  String _getEventTitle(String raw) {
    switch (raw.toUpperCase()) {
      case 'ORDER_COMPLETED':
        return 'Venta Completada';
      case 'REVIEW_5_STAR':
        return 'Reseña de 5 Estrellas';
      case 'REVIEW_4_STAR':
        return 'Reseña de 4 Estrellas';
      case 'REVIEW_REPLY':
        return 'Respuesta a Cliente';
      case 'PROFILE_COMPLETE':
        return 'Perfil Completado';
      case 'STREAK_10_ORDERS':
        return 'Bono de Racha de Ventas';
      case 'MONTHLY_NO_DISPUTES':
        return 'Mes Impecable sin Disputas';
      case 'ORDER_CANCELLED_BY_SELLER':
        return 'Pedido Cancelado por Tienda';
      case 'REVIEW_1_2_STAR':
        return 'Reseña Negativa';
      case 'DISPUTE_OPENED':
        return 'Disputa Iniciada';
      case 'DISPUTE_LOST':
        return 'Disputa Perdida';
      case 'INACTIVITY_WEEKLY':
        return 'Penalización por Inactividad';
      case 'MANUAL_ADJUSTMENT':
        return 'Ajuste de Rango';
      default:
        return raw;
    }
  }

  Widget _buildAchievementsTab(
      AsyncValue<List<AchievementItem>> achievementsAsync) {
    return achievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(
            child: Text(
              'No hay logros disponibles en este momento.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Showcase Section
              _buildShowcaseManager(achievements),

              const SizedBox(height: 24),

              // All Achievements Grid
              const Text(
                'Todos los Logros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  return _buildAchievementCard(ach);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          const Center(child: Text('Error al cargar logros')),
    );
  }

  Widget _buildShowcaseManager(List<AchievementItem> achievements) {
    final unlockedAchievements =
        achievements.where((a) => a.isUnlocked).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vitrina de la Tienda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Selecciona hasta 5 logros para mostrar a tus clientes (${_selectedShowcaseIds.length}/5)',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              TextButton(
                onPressed: _selectedShowcaseIds.isNotEmpty ? _saveShowcase : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (unlockedAchievements.isEmpty)
            const Text(
              'Aún no has desbloqueado logros para tu vitrina.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlockedAchievements.map((ach) {
                final isSelected = _selectedShowcaseIds.contains(ach.id);
                return FilterChip(
                  label: Text(ach.title.isNotEmpty ? ach.title : ach.code),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        if (_selectedShowcaseIds.length < 5) {
                          _selectedShowcaseIds.add(ach.id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Solo puedes seleccionar un máximo de 5 logros para la vitrina.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        _selectedShowcaseIds.remove(ach.id);
                      }
                    });
                  },
                  selectedColor:
                      const Color(0xFF4F46E5).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF4F46E5),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF334155),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _saveShowcase() async {
    final success = await ref
        .read(showcaseNotifierProvider.notifier)
        .updateShowcase(widget.storeId, _selectedShowcaseIds.toList());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Vitrina actualizada exitosamente'
                : 'Error al actualizar la vitrina',
          ),
          backgroundColor:
              success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _buildAchievementCard(AchievementItem ach) {
    final isUnlocked = ach.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge Icon with lock overlay if locked
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildAchievementBadge(ach, isUnlocked),
                if (!isUnlocked)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            ach.title.isNotEmpty ? ach.title : ach.code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isUnlocked
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Description
          Expanded(
            child: Text(
              ach.description,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // LP Bonus & Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${ach.lpBonus} PR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isUnlocked
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(AchievementItem ach, bool isUnlocked) {
    final finalUrl = resolveAchievementBadgeUrl(ach.badgeUrl, achievementName: ach.title);

    return Image.network(
      finalUrl,
      width: 64,
      height: 64,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const RankingShimmerSkeleton(
          width: 64,
          height: 64,
          shape: BoxShape.circle,
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isUnlocked
              ? const Color(0xFFFEF3C7)
              : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.military_tech_rounded,
          color: isUnlocked
              ? const Color(0xFFD97706)
              : const Color(0xFF94A3B8),
          size: 32,
        ),
      ),
    );
  }
}
