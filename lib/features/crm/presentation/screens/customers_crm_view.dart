import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import '../../domain/entities/crm_entities.dart';
import '../providers/crm_providers.dart';
import '../widgets/create_targeted_offer_sheet.dart';
import '../widgets/crm_action_helpers.dart';
import '../widgets/crm_guides_catalog.dart';
import '../widgets/crm_tutorial_carousel.dart';
import '../widgets/customer_crm_bento_card.dart';

class CustomersCrmView extends ConsumerStatefulWidget {
  final bool isActive;

  const CustomersCrmView({
    super.key,
    this.isActive = true,
  });

  @override
  ConsumerState<CustomersCrmView> createState() => _CustomersCrmViewState();
}

class _CustomersCrmViewState extends ConsumerState<CustomersCrmView> {
  final TextEditingController _searchController = TextEditingController();
  bool _onboardingInFlight = false;
  bool _onboardingCompletedThisMount = false;

  static const String _legacyOnboardingKey = 'crm_onboarding_seen_v1';

  String _scopedOnboardingKey(String userId) {
    final clean = userId.trim();
    return clean.isNotEmpty
        ? '$_legacyOnboardingKey:$clean'
        : _legacyOnboardingKey;
  }

  @override
  void initState() {
    super.initState();
    _scheduleOnboardingCheck();
  }

  @override
  void didUpdateWidget(covariant CustomersCrmView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleOnboardingCheck();
    }
  }

  void _scheduleOnboardingCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
    });
  }

  Future<void> _maybeShowOnboarding() async {
    if (!mounted ||
        !widget.isActive ||
        _onboardingInFlight ||
        _onboardingCompletedThisMount) {
      return;
    }
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    if (user == null || !user.canAccessCrm) return;

    _onboardingInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final scopedKey = _scopedOnboardingKey(user.id);
      final alreadySeen = (prefs.getBool(scopedKey) ?? false) ||
          (prefs.getBool(_legacyOnboardingKey) ?? false);
      if (alreadySeen) {
        _onboardingCompletedThisMount = true;
        return;
      }
      if (!mounted || !widget.isActive) return;

      _onboardingCompletedThisMount = true;
      await CrmTutorialBottomSheet.show(context);
      await prefs.setBool(scopedKey, true);
    } finally {
      _onboardingInFlight = false;
    }
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(crmSearchQueryProvider.notifier).state = '';
    ref.read(crmSelectedSegmentProvider.notifier).state = null;
    ref.read(crmSelectedStoreIdProvider.notifier).state = null;
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(crmSummaryProvider);
    ref.invalidate(crmCustomersProvider);
    await Future.wait([
      ref.read(crmSummaryProvider.future).catchError((_) => null),
      ref.read(crmCustomersProvider.future).catchError((_) => <CrmCustomer>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    final companyId = user?.company?.id ?? '';
    final canManageCrm = user?.canManageCrm ?? false;

    if (user == null || !user.canAccessCrm) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No posees permiso CRM para ver este módulo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(crmSummaryProvider);
    final customersAsync = ref.watch(crmCustomersProvider);
    final selectedStoreId = ref.watch(crmSelectedStoreIdProvider);
    final selectedSegment = ref.watch(crmSelectedSegmentProvider);
    final searchQuery = ref.watch(crmSearchQueryProvider);
    final sortBy = ref.watch(crmSortByProvider);
    final hasActiveFilters = searchQuery.trim().isNotEmpty ||
        selectedSegment != null ||
        selectedStoreId != null;

    return Scaffold(
      backgroundColor: TuLojitaBrandColors.canvas,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: TuLojitaBrandColors.indigo50,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: TuLojitaBrandColors.indigo600,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mini CRM 360°',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: TuLojitaBrandColors.inkPrimary,
                                ),
                              ),
                              Text(
                                'Directorio consolidado, favoritos y ofertas relámpago',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: TuLojitaBrandColors.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          key: const ValueKey('crm_header_guide_btn'),
                          onTap: () => CrmTutorialBottomSheet.show(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Tooltip(
                            message: 'Abrir guía interactiva del CRM',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: TuLojitaBrandColors.indigo50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: TuLojitaBrandColors.indigo100,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.help_outline_rounded,
                                    size: 15,
                                    color: TuLojitaBrandColors.indigo700,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Guía',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: TuLojitaBrandColors.indigo700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Actualizar CRM',
                          onPressed: _refreshAll,
                          constraints: const BoxConstraints.tightFor(
                            width: 38,
                            height: 38,
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    if (!canManageCrm) ...[
                      const SizedBox(height: 10),
                      const _CrmReadOnlyBanner(),
                    ],
                    const SizedBox(height: 12),
                    summaryAsync.when(
                      loading: () => const _CrmKpiLoadingStrip(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (summary) {
                        if (summary == null) return const SizedBox.shrink();
                        final String? effectiveStoreId =
                            summary.authorizedStores.length == 1
                                ? summary.authorizedStores.first.id
                                : (selectedStoreId != null &&
                                        summary.authorizedStores.any(
                                          (s) => s.id == selectedStoreId,
                                        )
                                    ? selectedStoreId
                                    : null);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (summary.authorizedStores.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TuLojitaBrandColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: TuLojitaBrandColors.borderMuted,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: effectiveStoreId,
                                      isExpanded: true,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                      items: [
                                        if (summary.authorizedStores.length > 1)
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              'Todas las sucursales autorizadas',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ...summary.authorizedStores.map(
                                          (st) => DropdownMenuItem<String?>(
                                            value: st.id,
                                            child: Text(
                                              st.displayName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        ref
                                            .read(
                                              crmSelectedStoreIdProvider
                                                  .notifier,
                                            )
                                            .state = val;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            _CrmKpiCarousel(summary: summary),
                            const SizedBox(height: 12),
                            _CrmSegmentChipsRow(
                              summary: summary,
                              selectedSegment: selectedSegment,
                              onSelect: (seg) {
                                ref
                                    .read(crmSelectedSegmentProvider.notifier)
                                    .state = seg;
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(1.0);
                        final stackControls =
                            constraints.maxWidth < 340 || textScale >= 1.2;
                        final searchField = TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            ref.read(crmSearchQueryProvider.notifier).state =
                                val;
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar nombre, CI, tel, correo o tag...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(crmSearchQueryProvider.notifier)
                                          .state = '';
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: TuLojitaBrandColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: TuLojitaBrandColors.borderMuted,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: TuLojitaBrandColors.borderMuted,
                              ),
                            ),
                          ),
                        );
                        final sortDropdown = Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: TuLojitaBrandColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: TuLojitaBrandColors.borderMuted,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: sortBy,
                              isExpanded: stackControls,
                              icon: const Icon(Icons.sort_rounded, size: 18),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: TuLojitaBrandColors.inkPrimary,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'ltv', child: Text('LTV')),
                                DropdownMenuItem(
                                  value: 'ordersCount',
                                  child: Text('Pedidos'),
                                ),
                                DropdownMenuItem(
                                  value: 'lastOrderAt',
                                  child: Text('Reciente'),
                                ),
                                DropdownMenuItem(
                                  value: 'debt',
                                  child: Text('Deuda'),
                                ),
                                DropdownMenuItem(
                                  value: 'favoritesCount',
                                  child: Text('Favoritos'),
                                ),
                                DropdownMenuItem(
                                  value: 'rating',
                                  child: Text('Rating'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(crmSortByProvider.notifier).state =
                                      val;
                                }
                              },
                            ),
                          ),
                        );

                        if (stackControls) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: 8),
                              sortDropdown,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 8),
                            sortDropdown,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            customersAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: TuLojitaBrandColors.danger,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error cargando clientes CRM: $err',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _refreshAll,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _CrmEmptyStateCard(
                      hasActiveFilters: hasActiveFilters,
                      onClearFilters: _clearFilters,
                      onOpenGuide: () => CrmTutorialBottomSheet.show(context),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return CustomerCrmBentoCard(
                        customer: customer,
                        canManageCrm: canManageCrm,
                        onOpenDetail: () => context.push(
                          '/dashboard/crm/customer/${customer.customerId}',
                        ),
                        onWhatsApp: () => openWhatsAppTemplateSheet(
                          context,
                          customer,
                          onMarkContacted: canManageCrm && companyId.isNotEmpty
                              ? () => ref
                                  .read(crmRepositoryProvider)
                                  .updateCustomerProfile(
                                    companyId,
                                    customer.customerId,
                                    markContactedNow: true,
                                  )
                              : null,
                        ),
                        onSendOffer: canManageCrm &&
                                customer.topFavoriteItems.isNotEmpty &&
                                companyId.isNotEmpty
                            ? () async {
                                final favs = customer.topFavoriteItems;
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  showDragHandle: true,
                                  builder: (_) => CreateTargetedOfferSheet(
                                    companyId: companyId,
                                    customer: customer,
                                    favoriteItems: favs,
                                  ),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CrmKpiCarousel extends StatelessWidget {
  final CrmSummary summary;

  const _CrmKpiCarousel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KpiBentoTile(
              icon: Icons.groups_rounded,
              color: TuLojitaBrandColors.indigo600,
              bgColor: TuLojitaBrandColors.indigo50,
              title: 'Total Clientes',
              valueWidget: Text(
                '${summary.totalCustomers}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              subtitle:
                  '${summary.vipCount} VIP · ${summary.atRiskCount} en riesgo',
            ),
            const SizedBox(width: 10),
            _KpiBentoTile(
              icon: Icons.monetization_on_outlined,
              color: TuLojitaBrandColors.positive,
              bgColor: TuLojitaBrandColors.positiveBg,
              title: 'LTV Total (Valor Cliente)',
              headerTrailing: const CrmGuideButton(
                key: ValueKey('crm_ltv_guide_btn'),
                guide: CrmGuidesCatalog.ltvMetric,
                label: 'Qué es',
                compact: true,
              ),
              valueWidget: DualPriceText(
                amountInUsd: summary.totalLtvUsd,
                usdStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
                bsStyle: const TextStyle(
                  fontSize: 11,
                  color: TuLojitaBrandColors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: 'Compras válidas acumuladas',
            ),
            const SizedBox(width: 10),
            _KpiBentoTile(
              icon: Icons.account_balance_wallet_outlined,
              color: TuLojitaBrandColors.danger,
              bgColor: TuLojitaBrandColors.dangerBg,
              title: 'Cartera Pendiente',
              valueWidget: DualPriceText(
                amountInUsd: summary.totalPendingDebtUsd,
                usdStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.danger,
                ),
                bsStyle: const TextStyle(
                  fontSize: 11,
                  color: TuLojitaBrandColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: '${summary.withDebtCount} con saldo',
            ),
            const SizedBox(width: 10),
            _KpiBentoTile(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFDB2777),
              bgColor: const Color(0xFFFCE7F3),
              title: 'Favoritos en Radar',
              valueWidget: Text(
                '${summary.totalFavoritesCount}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              subtitle: '${summary.activeTargetedOffersCount} ofertas activas',
            ),
            const SizedBox(width: 10),
            _KpiBentoTile(
              icon: Icons.event_note_outlined,
              color: TuLojitaBrandColors.amber700,
              bgColor: TuLojitaBrandColors.amber100,
              title: 'Seguimientos',
              valueWidget: Text(
                '${summary.pendingFollowUpsCount}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              subtitle: '${summary.overdueFollowUpsCount} vencidos',
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiBentoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final Widget valueWidget;
  final String subtitle;
  final Widget? headerTrailing;

  const _KpiBentoTile({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.valueWidget,
    required this.subtitle,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 164, maxWidth: 214),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TuLojitaBrandColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TuLojitaBrandColors.borderMuted),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ),
                if (headerTrailing != null) ...[
                  const SizedBox(width: 6),
                  headerTrailing!,
                ],
              ],
            ),
            const SizedBox(height: 8),
            valueWidget,
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: TuLojitaBrandColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrmSegmentChipsRow extends StatelessWidget {
  final CrmSummary summary;
  final String? selectedSegment;
  final ValueChanged<String?> onSelect;

  const _CrmSegmentChipsRow({
    required this.summary,
    required this.selectedSegment,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({String? key, String label})>[
      (key: null, label: 'Todos (${summary.totalCustomers})'),
      (key: 'VIP', label: 'VIP (${summary.vipCount})'),
      (key: 'FREQUENT', label: 'Frecuentes (${summary.frequentCount})'),
      (key: 'NEW', label: 'Nuevos (${summary.newCount})'),
      (key: 'AT_RISK', label: 'En Riesgo (${summary.atRiskCount})'),
      (key: 'WITH_DEBT', label: 'Con Deuda (${summary.withDebtCount})'),
      (key: 'WISHLIST', label: 'Con Favoritos'),
      (key: 'BLOCKED', label: 'Bloqueados (${summary.blockedCount})'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Segmentos RFM',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkSecondary,
                ),
              ),
            ),
            SizedBox(width: 8),
            CrmGuideButton(
              key: ValueKey('crm_rfm_guide_btn'),
              guide: CrmGuidesCatalog.rfmSegments,
              label: 'Qué son',
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var idx = 0; idx < items.length; idx++) ...[
                if (idx > 0) const SizedBox(width: 8),
                Builder(
                  builder: (_) {
                    final item = items[idx];
                    final selected = selectedSegment == item.key;
                    return ChoiceChip(
                      label: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? TuLojitaBrandColors.indigo700
                              : TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                      selected: selected,
                      selectedColor: TuLojitaBrandColors.indigo100,
                      backgroundColor: TuLojitaBrandColors.surface,
                      onSelected: (_) => onSelect(item.key),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CrmReadOnlyBanner extends StatelessWidget {
  const _CrmReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.indigo50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TuLojitaBrandColors.indigo100),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 18,
            color: TuLojitaBrandColors.indigo700,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo consulta: puedes ver contactos y métricas de tus sucursales. Para editar notas, etiquetas, recordatorios o enviar ofertas se requiere permiso crm:manage.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: TuLojitaBrandColors.indigo700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrmEmptyStateCard extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onOpenGuide;

  const _CrmEmptyStateCard({
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    if (hasActiveFilters) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TuLojitaBrandColors.borderMuted),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: TuLojitaBrandColors.indigo50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.filter_alt_off_outlined,
                  size: 30,
                  color: TuLojitaBrandColors.indigo600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin resultados para estos filtros',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No encontramos clientes que coincidan con la búsqueda, el segmento o la sucursal seleccionada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: TuLojitaBrandColors.inkSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TuLojitaBrandColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TuLojitaBrandColors.borderMuted),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TuLojitaBrandColors.indigo50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_outlined,
                    color: TuLojitaBrandColors.indigo600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aún no tienes clientes en el CRM',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: TuLojitaBrandColors.inkPrimary,
                        ),
                      ),
                      Text(
                        'Así se irá poblando tu directorio automáticamente:',
                        style: TextStyle(
                          fontSize: 12,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _OnboardingStepTile(
              number: '1',
              title: 'Recibe pedidos o reservas',
              subtitle:
                  'Cada compra o cita en tus sucursales registra al cliente con su historial.',
            ),
            const SizedBox(height: 8),
            const _OnboardingStepTile(
              number: '2',
              title: 'Captura prospectos desde favoritos',
              subtitle:
                  'Quienes guarden tus productos en favoritos aparecerán listos para contactarse.',
            ),
            const SizedBox(height: 8),
            const _OnboardingStepTile(
              number: '3',
              title: 'Haz seguimiento y envía ofertas',
              subtitle:
                  'Usa WhatsApp, notas internas y ofertas relámpago con enlace directo.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenGuide,
                style: FilledButton.styleFrom(
                  backgroundColor: TuLojitaBrandColors.indigo600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Ver guía del CRM'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _OnboardingStepTile({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: TuLojitaBrandColors.indigo50,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: TuLojitaBrandColors.indigo700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TuLojitaBrandColors.inkPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: TuLojitaBrandColors.inkSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrmKpiLoadingStrip extends StatelessWidget {
  const _CrmKpiLoadingStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => Container(
          width: 168,
          decoration: BoxDecoration(
            color: TuLojitaBrandColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TuLojitaBrandColors.borderMuted),
          ),
        ),
      ),
    );
  }
}
