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
  final List<String> _selectedShowcaseIds = [];
  bool _showcaseInitialized = false;
  bool _isSavingShowcase = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rankingAsync = ref.read(storeRankingProvider(widget.storeId));
      rankingAsync.whenData((ranking) {
        if (!_showcaseInitialized && mounted) {
          setState(() {
            _selectedShowcaseIds.clear();
            if (ranking.showcase.isNotEmpty) {
              _selectedShowcaseIds.addAll(ranking.showcase.map((a) => a.id));
            }
            _showcaseInitialized = true;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _showcaseInitialized = false;
    ref.invalidate(storeRankingProvider(widget.storeId));
    ref.invalidate(storeEventsProvider(widget.storeId));
    ref.invalidate(storeAchievementsProvider(widget.storeId));
    ref.invalidate(dailyMissionsProvider(widget.storeId));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<StoreRankingData>>(
      storeRankingProvider(widget.storeId),
      (prev, next) {
        next.whenData((ranking) {
          if (!_showcaseInitialized && mounted) {
            setState(() {
              _selectedShowcaseIds.clear();
              if (ranking.showcase.isNotEmpty) {
                _selectedShowcaseIds.addAll(ranking.showcase.map((a) => a.id));
              }
              _showcaseInitialized = true;
            });
          }
        });
      },
    );

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
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
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
                      Flexible(
                        child: Text(
                          'Racha de ${ranking.consecutiveSalesDays} días (${ranking.streakMultiplier}x PR)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC2410C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      Flexible(
                        child: Text(
                          'Escudo de Rango Activo (48h)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      Flexible(
                        child: Text(
                          'Zona de Peligro: Concreta ventas hoy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  childAspectRatio: 0.85,
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
    final achievementMap = {for (var a in achievements) a.id: a};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, counter & Save button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vitrina de la Tienda',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Exhibe hasta 5 insignias (${_selectedShowcaseIds.length}/5)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSavingShowcase ? null : _saveShowcase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isSavingShowcase
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Visual 5-Slot Trophy Case
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'ESTANTE PÚBLICO',
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedShowcaseIds.length} de 5',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final bool isOccupied = index < _selectedShowcaseIds.length;
                    final String? achId =
                        isOccupied ? _selectedShowcaseIds[index] : null;
                    final AchievementItem? ach =
                        achId != null ? achievementMap[achId] : null;

                    return _buildShowcaseSlot(
                      slotIndex: index + 1,
                      achievement: ach,
                      onRemove: (isOccupied && ach != null)
                          ? () {
                              setState(() {
                                _selectedShowcaseIds.removeAt(index);
                              });
                            }
                          : null,
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selector de logros desbloqueados
          if (unlockedAchievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.amber.shade700, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Aún no has desbloqueado insignias. Completa ventas o misiones para desbloquear y exhibir tus logros.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'Toca una insignia para añadirla o quitarla de tu vitrina:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlockedAchievements.map((ach) {
                final isSelected = _selectedShowcaseIds.contains(ach.id);
                final slotPos = isSelected
                    ? _selectedShowcaseIds.indexOf(ach.id) + 1
                    : null;

                return FilterChip(
                  avatar: SizedBox(
                    width: 22,
                    height: 22,
                    child: _buildAchievementBadge(ach, true, size: 20),
                  ),
                  label: Text(
                    isSelected
                        ? '#$slotPos ${ach.title.isNotEmpty ? ach.title : ach.code}'
                        : (ach.title.isNotEmpty ? ach.title : ach.code),
                  ),
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
                                  'La vitrina tiene un máximo de 5 insignias. Quita una para agregar otra.'),
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
        ],
      ),
    );
  }

  Widget _buildShowcaseSlot({
    required int slotIndex,
    AchievementItem? achievement,
    VoidCallback? onRemove,
  }) {
    final bool isOccupied = achievement != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isOccupied
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOccupied
                      ? Colors.amber.shade300
                      : Colors.white.withValues(alpha: 0.2),
                  width: isOccupied ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: isOccupied
                    ? _buildAchievementBadge(achievement, true, size: 40)
                    : Text(
                        '#$slotIndex',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
              ),
            ),
            if (isOccupied && onRemove != null)
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 54,
          child: Text(
            isOccupied
                ? (achievement.title.isNotEmpty ? achievement.title : achievement.code)
                : 'Vacío',
            style: TextStyle(
              color: isOccupied
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: isOccupied ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _saveShowcase() async {
    setState(() {
      _isSavingShowcase = true;
    });

    try {
      final success = await ref
          .read(showcaseNotifierProvider.notifier)
          .updateShowcase(widget.storeId, _selectedShowcaseIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '¡Vitrina actualizada exitosamente!'
                  : 'Error al actualizar la vitrina',
            ),
            backgroundColor:
                success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingShowcase = false;
        });
      }
    }
  }

  Widget _buildAchievementCard(AchievementItem ach) {
    final isUnlocked = ach.isUnlocked;
    final inShowcase = _selectedShowcaseIds.contains(ach.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? (inShowcase
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFFE2E8F0))
              : const Color(0xFFE2E8F0),
          width: inShowcase ? 1.5 : 1.0,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge Icon with lock overlay if locked
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildAchievementBadge(ach, isUnlocked, size: 46),
                if (!isUnlocked)
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Title
          Text(
            ach.title.isNotEmpty ? ach.title : ach.code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
              color: isUnlocked
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Description (bounded height to prevent unconstrained flex in shrink-wrapped grid)
          SizedBox(
            height: 26,
            child: Text(
              ach.description,
              style: TextStyle(
                fontSize: 9.5,
                color: isUnlocked
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // LP Bonus & Showcase status (Wrap to prevent horizontal overflow on narrow cards)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${ach.lpBonus} PR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (isUnlocked)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (inShowcase) {
                        _selectedShowcaseIds.remove(ach.id);
                      } else {
                        if (_selectedShowcaseIds.length < 5) {
                          _selectedShowcaseIds.add(ach.id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Máximo 5 insignias en la vitrina. Quita una para agregar esta.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: inShowcase
                          ? const Color(0xFFEEF2FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: inShowcase
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      inShowcase ? '★ Vitrina' : '+ Exhibir',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: inShowcase
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(AchievementItem ach, bool isUnlocked, {double size = 64}) {
    final finalUrl = resolveAchievementBadgeUrl(ach.badgeUrl, achievementName: ach.title);

    return Image.network(
      finalUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return RankingShimmerSkeleton(
          width: size,
          height: size,
          shape: BoxShape.circle,
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: size,
        height: size,
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
          size: size * 0.5,
        ),
      ),
    );
  }
}
