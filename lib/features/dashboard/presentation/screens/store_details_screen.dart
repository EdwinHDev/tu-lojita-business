import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/envs.dart';
import '../../../../core/widgets/shimmer_widget.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/store_dashboard.dart';
import '../providers/store_details_notifier.dart';
import '../providers/notifications_provider.dart';
import '../widgets/store_details_skeletons.dart';
import '../../../ranking/presentation/widgets/store_rank_header_card.dart';
import '../../../ranking/presentation/widgets/daily_missions_card.dart';
import '../../../ranking/presentation/widgets/store_rank_avatar.dart';
import '../../../ranking/presentation/providers/ranking_providers.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import 'settings/blocked_customers_screen.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  String _resolveImageUrl(String? path, {int? width, int? height}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    final baseUrl = '${Envs.apiBaseUrlImages}/$cleanPath';
    final params = <String>[];
    if (width != null) params.add('w=$width');
    if (height != null) params.add('h=$height');

    return params.isEmpty ? baseUrl : '$baseUrl?${params.join('&')}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeDetailsProvider).forStore(widget.storeId);
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final canViewFinancials = user?.canViewFinancialMetrics ?? true;
    final canViewSales = user?.canViewSalesHistory ?? true;

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.store == null && !state.isLoading) {
        ref.read(storeDetailsProvider.notifier).loadData(widget.storeId);
      }
    });

    final store = state.store;
    final logoUrl = _resolveImageUrl(store?.logo, width: 200, height: 200);
    final coverUrl = _resolveImageUrl(store?.coverImage, width: 1200, height: 400);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
              },
              color: const Color(0xFF4F46E5),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // Banner + Info Card + Floating Logo
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildBanner(coverUrl, logoUrl, isLoading: store == null),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 140, 16, 12),
                          child: store == null
                              ? const StoreHeaderCardSkeleton()
                              : _buildInfoCard(store, state),
                        ),
                        _buildFloatingLogo(logoUrl, isLoading: store == null),
                      ],
                    ),
                  ),

                  // Business Insights (KPI Metrics Section)
                  if (canViewFinancials)
                    SliverToBoxAdapter(
                      child: state.dashboard != null
                          ? _buildInsightsSection(state)
                          : const StoreMetricsSkeleton(),
                    ),

                  // Store Ranking Progression & Daily Missions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StoreRankHeaderCard(storeId: widget.storeId),
                          const SizedBox(height: 12),
                          DailyMissionsCard(storeId: widget.storeId),
                        ],
                      ),
                    ),
                  ),

                  // Operational Quick Actions Hub
                  SliverToBoxAdapter(child: _buildQuickActionsGrid(context, ref)),

                  // Live Recent Sales Activity
                  if (canViewSales)
                    SliverToBoxAdapter(
                      child: state.dashboard != null
                          ? _buildRecentSalesSection(state)
                          : const StoreRecentSalesSkeleton(),
                    ),

                  // Bottom clearance spacer
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
            ),

            // Botón Atrás Flotante
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(String coverUrl, String logoUrl, {bool isLoading = false}) {
    if (isLoading) {
      return const ShimmerWidget(
        width: double.infinity,
        height: 180,
        borderRadius: BorderRadius.zero,
      );
    }
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        image: coverUrl.isNotEmpty || logoUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(coverUrl.isNotEmpty ? coverUrl : logoUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.35),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildFloatingLogo(String logoUrl, {bool isLoading = false}) {
    final rankingAsync = ref.watch(storeRankingProvider(widget.storeId));
    final division = rankingAsync.value?.division ?? 'PUESTO_AMBULANTE';
    final frameUrl = rankingAsync.value?.divisionFrameUrl;

    if (isLoading) {
      return const Positioned(
        top: 80,
        left: 0,
        right: 0,
        child: Center(
          child: ShimmerWidget.circular(size: 96),
        ),
      );
    }

    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: Center(
        child: StoreRankAvatar(
          logoUrl: logoUrl,
          division: division,
          divisionFrameUrl: frameUrl,
          size: 110,
        ),
      ),
    );
  }

  Widget _buildInfoCard(Store store, StoreDetailsData state) {
    final isActive = store.status.toUpperCase() == 'ACTIVE';
    final shouldShowBranch = store.shouldShowBranch;
    final subcategoryName = store.subcategory?.name;
    final allowsInstallments = store.allowPartialPayments;
    final maxInstallments = store.maxInstallments;
    final productsCount = store.productsCount > 0
        ? store.productsCount
        : (state.dashboard?.stats.totalItems ?? 0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
      child: Column(
        children: [
          // 1. Nombre de Tienda o Sucursal
          Text(
            shouldShowBranch ? store.branchLabel : store.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          if (shouldShowBranch) ...[
            const SizedBox(height: 3),
            Text(
              'Tienda: ${store.name}',
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // 2. Subcategoría / Rubro de la Tienda
          if (subcategoryName != null && subcategoryName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedTag01,
                    color: Color(0xFF475569),
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    subcategoryName,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 3. Fila de Indicadores Operativos de Alto Valor para la Tienda
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Régimen de Financiación
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: allowsInstallments ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: allowsInstallments ? const Color(0xFFE9D5FF) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: allowsInstallments
                          ? HugeIcons.strokeRoundedCreditCard
                          : HugeIcons.strokeRoundedMoney01,
                      color: allowsInstallments ? const Color(0xFF7E22CE) : const Color(0xFF64748B),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      allowsInstallments
                          ? 'En cuotas ($maxInstallments cuotas)'
                          : 'Solo Contado',
                      style: TextStyle(
                        color: allowsInstallments ? const Color(0xFF6B21A8) : const Color(0xFF475569),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Catálogo Activo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedPackage,
                      color: Color(0xFF2563EB),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$productsCount ${productsCount == 1 ? 'Producto' : 'Productos'}',
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Estado de Tienda (Operativa / En Pausa)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? 'Operativa' : 'Pausada',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // 4. Acciones Rápidas (IconButtons de Compartir Tienda y Gestionar)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'Compartir enlace público',
                  child: InkWell(
                    onTap: () {
                      final storeId = store.id;
                      final publicUrl = 'https://tulojita.com/tienda/$storeId';
                      Clipboard.setData(ClipboardData(text: publicUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('Enlace público de tu tienda copiado')),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E7FF), width: 1.2),
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedShare01,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'Gestionar y Configurar Tienda',
                  child: InkWell(
                    onTap: () => _showManagementMenu(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedSettings01,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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

  Widget _buildInsightsSection(StoreDetailsData state) {
    final dashboard = state.dashboard;
    if (dashboard == null) return const SizedBox.shrink();

    final formattedSales = _currencyFormat.format(dashboard.stats.salesToday);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Métricas Clave',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Hoy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Ventas de hoy',
                  value: formattedSales,
                  icon: HugeIcons.strokeRoundedDollarCircle,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  label: 'Clientes',
                  value: '${dashboard.stats.totalCustomers}',
                  icon: HugeIcons.strokeRoundedUserMultiple,
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  label: 'Artículos',
                  value: '${dashboard.stats.totalItems}',
                  icon: HugeIcons.strokeRoundedShoppingBag01,
                  color: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF5F3FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required dynamic icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: HugeIcon(
              icon: icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, WidgetRef ref) {
    final unreadDisputes = ref.watch(unreadBusinessDisputeOrderIdsProvider);
    final hasDisputes = unreadDisputes.isNotEmpty;
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    final actions = <_QuickActionItem>[];

    // 1. Órdenes
    if (user == null || !user.isCollaborator || user.canViewOrders || user.canProcessOrders) {
      actions.add(_QuickActionItem(
        title: 'Órdenes',
        subtitle: 'Gestión y despacho',
        icon: HugeIcons.strokeRoundedShoppingBag01,
        color: const Color(0xFF4F46E5),
        bgColor: const Color(0xFFEEF2FF),
        badgeText: (hasDisputes && (user == null || !user.isCollaborator || user.canViewDisputes)) ? 'Reclamos' : null,
        badgeColor: const Color(0xFFEF4444),
        onTap: () => context.push('/dashboard/stores/${widget.storeId}/orders'),
      ));
    }

    // 2. Cuotas y Deudas
    if (user == null || !user.isCollaborator || user.canViewInstallments) {
      actions.add(_QuickActionItem(
        title: 'Cuotas y Deudas',
        subtitle: 'Cuentas por cobrar',
        icon: HugeIcons.strokeRoundedInvoice01,
        color: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
        onTap: () => context.push('/dashboard/stores/${widget.storeId}/installments'),
      ));
    }

    // 3. Artículos
    if (user == null || !user.isCollaborator || user.canManageStock || user.canChangePrices || user.canEditProducts) {
      actions.add(_QuickActionItem(
        title: 'Artículos',
        subtitle: user != null && user.isCollaborator && !user.canChangePrices
            ? 'Ajuste de inventario'
            : 'Inventario y precios',
        icon: HugeIcons.strokeRoundedTag01,
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
        onTap: () => context.push('/dashboard/stores/${widget.storeId}/items'),
      ));
    }

    // 4. Categorías
    if (user == null || !user.isCollaborator || user.canEditProducts || user.canManageBranches) {
      actions.add(_QuickActionItem(
        title: 'Categorías',
        subtitle: 'Organizar catálogo',
        icon: HugeIcons.strokeRoundedFolder01,
        color: const Color(0xFF0EA5E9),
        bgColor: const Color(0xFFF0F9FF),
        onTap: () => context.push('/dashboard/stores/${widget.storeId}/categories'),
      ));
    }

    // 5. Mi Ranking (accesible por todos los miembros del equipo)
    actions.add(_QuickActionItem(
      title: 'Mi Ranking',
      subtitle: 'Logros y misiones',
      icon: null,
      iconWidget: const Icon(Icons.emoji_events_outlined, color: Color(0xFFF59E0B), size: 20),
      color: const Color(0xFFF59E0B),
      bgColor: const Color(0xFFFFFBEB),
      onTap: () => context.push('/dashboard/stores/${widget.storeId}/ranking'),
    ));

    // 6. Configuración
    if (user == null || !user.isCollaborator || user.canManageBranches) {
      actions.add(_QuickActionItem(
        title: 'Configuración',
        subtitle: 'Horarios y ajustes',
        icon: HugeIcons.strokeRoundedSettings03,
        color: const Color(0xFF64748B),
        bgColor: const Color(0xFFF8FAFC),
        onTap: () => context.push('/dashboard/stores/${widget.storeId}/settings'),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Gestión Operativa',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Acceso directo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildQuickActionCard(action);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickActionItem action) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: action.color.withValues(alpha: 0.1),
        highlightColor: action.color.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: action.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: action.iconWidget ??
                        HugeIcon(
                          icon: action.icon!,
                          color: action.color,
                          size: 18,
                        ),
                  ),
                  const Spacer(),
                  if (action.badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: action.badgeColor?.withValues(alpha: 0.12) ?? const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: action.badgeColor?.withValues(alpha: 0.3) ?? const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Text(
                        action.badgeText!,
                        style: TextStyle(
                          color: action.badgeColor ?? const Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSalesSection(StoreDetailsData state) {
    final recentSales = state.dashboard?.recentSales ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Ventas Recientes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/dashboard/stores/${widget.storeId}/orders'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ver todas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (recentSales.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedInvoice01,
                      color: Color(0xFF94A3B8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sin ventas recientes hoy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Las ventas que se procesen en esta sucursal aparecerán aquí en vivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSales.length > 5 ? 5 : recentSales.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sale = recentSales[index];
                return _buildRecentSaleTile(sale);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSaleTile(StoreRecentSale sale) {
    final statusUpper = sale.status.toUpperCase();
    final isApproved = statusUpper == 'APPROVED' ||
        statusUpper == 'COMPLETED' ||
        statusUpper == 'PAID' ||
        statusUpper == 'FULLY_PAID';
    final isPartiallyPaid = statusUpper == 'PARTIALLY_PAID';
    final isCancelled = statusUpper == 'CANCELLED';

    final cleanOrderId = sale.orderId.replaceAll('#', '').trim();
    final rawOrderId = cleanOrderId.isNotEmpty ? cleanOrderId : sale.id;
    final shortOrderId = rawOrderId.length >= 8
        ? rawOrderId.substring(0, 8).toUpperCase()
        : rawOrderId.toUpperCase();
    final formattedAmount = _currencyFormat.format(sale.amount);

    final String statusLabel;
    final Color statusTextColor;
    final Color statusBgColor;

    if (isApproved) {
      statusLabel = 'Pagada';
      statusTextColor = const Color(0xFF047857);
      statusBgColor = const Color(0xFFECFDF5);
    } else if (isPartiallyPaid) {
      statusLabel = 'En Cuotas';
      statusTextColor = const Color(0xFF1D4ED8);
      statusBgColor = const Color(0xFFEFF6FF);
    } else if (isCancelled) {
      statusLabel = 'Cancelada';
      statusTextColor = const Color(0xFFB91C1C);
      statusBgColor = const Color(0xFFFEF2F2);
    } else {
      statusLabel = 'Pendiente';
      statusTextColor = const Color(0xFFB45309);
      statusBgColor = const Color(0xFFFEF3C7);
    }

    final productImageUrl = _resolveImageUrl(sale.itemImageUrl, width: 100, height: 100);
    final itemDisplayName = sale.itemTitle?.trim().isNotEmpty == true
        ? sale.itemTitle!.trim()
        : 'Orden #$shortOrderId';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          final targetOrderId = rawOrderId.isNotEmpty ? rawOrderId : sale.id;
          if (targetOrderId.isNotEmpty) {
            context.push('/dashboard/orders/$targetOrderId');
          } else {
            context.push('/dashboard/stores/${widget.storeId}/orders');
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFF8FAFC),
                  child: productImageUrl.isNotEmpty
                      ? Image.network(
                          productImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: HugeIcon(
                              icon: isApproved
                                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                                  : HugeIcons.strokeRoundedClock01,
                              color: isApproved
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6),
                              size: 20,
                            ),
                          ),
                        )
                      : Center(
                          child: HugeIcon(
                            icon: isApproved
                                ? HugeIcons.strokeRoundedCheckmarkCircle02
                                : HugeIcons.strokeRoundedClock01,
                            color: isApproved
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6),
                            size: 20,
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
                      itemDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '#$shortOrderId',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          ' · ${sale.time.isNotEmpty ? sale.time : 'Hoy'}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+$formattedAmount',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManagementMenu(BuildContext context) {
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;

    final canOrders = user == null || !user.isCollaborator || user.canViewOrders || user.canProcessOrders;
    final canInstallments = user == null || !user.isCollaborator || user.canViewInstallments;
    final canProducts = user == null || !user.isCollaborator || user.canManageStock || user.canChangePrices || user.canEditProducts;
    final canCategories = user == null || !user.isCollaborator || user.canEditProducts || user.canManageBranches;
    final canSettings = user == null || !user.isCollaborator || user.canManageBranches;
    final canBlocked = user == null || !user.isCollaborator || user.canManageBranches || user.canViewOrders;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gestión de Tienda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (canOrders)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedShoppingBag01,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Gestionar Órdenes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: (ref.read(unreadBusinessDisputeOrderIdsProvider).isNotEmpty &&
                            (user == null || !user.isCollaborator || user.canViewDisputes))
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Reclamos',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                    onTap: () {
                      context.pop();
                      context.push('/dashboard/stores/${widget.storeId}/orders');
                    },
                  ),
                if (canInstallments)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedInvoice01,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Cuotas y Deudas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      context.pop();
                      context.push('/dashboard/stores/${widget.storeId}/installments');
                    },
                  ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Mi Ranking & Logros',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    context.pop();
                    context.push('/dashboard/stores/${widget.storeId}/ranking');
                  },
                ),
                if (canBlocked)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedUserBlock01,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Clientes Bloqueados',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      context.pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlockedCustomersScreen(storeId: widget.storeId),
                        ),
                      );
                    },
                  ),
                if (canCategories)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTag01,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Gestionar Categorías',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      context.pop();
                      context.push('/dashboard/stores/${widget.storeId}/categories');
                    },
                  ),
                if (canProducts)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      user != null && user.isCollaborator && !user.canChangePrices
                          ? 'Ajustar Inventario'
                          : 'Gestionar Artículos',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      context.pop();
                      context.push('/dashboard/stores/${widget.storeId}/items');
                    },
                  ),
                if (canSettings)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSettings03,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Configurar Tienda',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      context.pop();
                      context.push('/dashboard/stores/${widget.storeId}/settings');
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionItem {
  final String title;
  final String subtitle;
  final dynamic icon;
  final Widget? iconWidget;
  final Color color;
  final Color bgColor;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    this.icon,
    this.iconWidget,
    required this.color,
    required this.bgColor,
    this.badgeText,
    this.badgeColor,
    required this.onTap,
  });
}
