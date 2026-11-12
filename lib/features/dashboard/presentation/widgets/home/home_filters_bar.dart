import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:tu_lojita_business/core/providers/exchange_rate_provider.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/utils/price_formatter.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/home/home_image_resolver.dart';

class HomeFiltersBar extends ConsumerWidget {
  final String selectedPeriod;
  final String selectedStoreId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final List<Store> stores;
  final bool canSelectAllBranches;
  final ValueChanged<String> onPeriodSelected;
  final ValueChanged<String> onStoreSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;

  const HomeFiltersBar({
    super.key,
    required this.selectedPeriod,
    required this.selectedStoreId,
    required this.customStartDate,
    required this.customEndDate,
    required this.stores,
    this.canSelectAllBranches = true,
    required this.onPeriodSelected,
    required this.onStoreSelected,
    required this.onCustomRangeSelected,
  });

  static const _periodOptions = <({String key, String label, dynamic icon})>[
    (key: 'today', label: 'Hoy', icon: HugeIcons.strokeRoundedClock01),
    (key: 'week', label: 'Esta Semana', icon: HugeIcons.strokeRoundedCalendar03),
    (key: 'month', label: 'Este Mes', icon: HugeIcons.strokeRoundedCalendar01),
    (key: 'six_months', label: '6 Meses', icon: HugeIcons.strokeRoundedAnalytics01),
    (key: 'year', label: 'Este Año', icon: HugeIcons.strokeRoundedChartLineData02),
  ];

  String get _selectedStoreLabel {
    final multipleBranches = stores.length > 1;
    if (selectedStoreId == 'all') {
      if (!canSelectAllBranches && stores.isNotEmpty) {
        final first = stores.first;
        return first.shouldShowBranch ? first.combinedDisplayName : first.name;
      }
      return multipleBranches ? 'Todas las sedes' : 'Consolidado';
    }

    final store = stores.where((s) => s.id == selectedStoreId).firstOrNull;
    if (store != null) {
      return store.shouldShowBranch ? store.combinedDisplayName : store.name;
    }
    return multipleBranches ? 'Sucursal' : 'Mi Tienda';
  }

  String get _selectedPeriodLabel {
    if (selectedPeriod == 'custom' &&
        customStartDate != null &&
        customEndDate != null) {
      final f = DateFormat('dd MMM', 'es');
      return '${f.format(customStartDate!)} - ${f.format(customEndDate!)}';
    }
    for (final opt in _periodOptions) {
      if (opt.key == selectedPeriod) return opt.label;
    }
    return 'Este Mes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(exchangeRateProvider).asData?.value;
    final showBcvPill = config != null && PriceFormatter.isDualEnabled(config);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterDropdownPill(
          icon: HugeIcons.strokeRoundedStore01,
          label: _selectedStoreLabel,
          isHighlighted: false,
          onTap: () => _showStoreSelectorModal(context),
        ),
        _FilterDropdownPill(
          icon: HugeIcons.strokeRoundedCalendar03,
          label: _selectedPeriodLabel,
          isHighlighted: true,
          onTap: () => _showPeriodSelectorModal(context),
        ),
        if (showBcvPill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: TuLojitaBrandColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TuLojitaBrandColors.borderMuted),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedDollarCircle,
                  color: TuLojitaBrandColors.indigo600,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Tasa BCV: ${PriceFormatter.formatRateValue(config.rate, symbol: config.symbol)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: TuLojitaBrandColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _openCustomRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: customStartDate ?? now.subtract(const Duration(days: 15)),
      end: customEndDate ?? now,
    );

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TuLojitaBrandColors.indigo600,
              onPrimary: Colors.white,
              onSurface: TuLojitaBrandColors.inkPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      onCustomRangeSelected(result.start, result.end);
    }
  }

  void _showPeriodSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TuLojitaBrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Seleccionar Período',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._periodOptions.map((opt) {
                  final isSelected = selectedPeriod == opt.key;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? TuLojitaBrandColors.indigo50
                          : TuLojitaBrandColors.canvas,
                      child: HugeIcon(
                        icon: opt.icon,
                        color: isSelected
                            ? TuLojitaBrandColors.indigo600
                            : TuLojitaBrandColors.inkSecondary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: TuLojitaBrandColors.indigo600,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onPeriodSelected(opt.key);
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: selectedPeriod == 'custom'
                        ? TuLojitaBrandColors.indigo50
                        : TuLojitaBrandColors.canvas,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendarAdd01,
                      color: selectedPeriod == 'custom'
                          ? TuLojitaBrandColors.indigo600
                          : TuLojitaBrandColors.inkSecondary,
                      size: 18,
                    ),
                  ),
                  title: const Text(
                    'Rango personalizado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: TuLojitaBrandColors.inkPrimary,
                    ),
                  ),
                  subtitle: (selectedPeriod == 'custom' &&
                          customStartDate != null &&
                          customEndDate != null)
                      ? Text(_selectedPeriodLabel)
                      : const Text('Elegir fecha inicial y final'),
                  trailing: selectedPeriod == 'custom'
                      ? const Icon(
                          Icons.check_circle,
                          color: TuLojitaBrandColors.indigo600,
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          color: TuLojitaBrandColors.inkSecondary,
                          size: 16,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openCustomRangePicker(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStoreSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TuLojitaBrandColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final multipleBranches = stores.length > 1;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      multipleBranches ? 'Filtrar por Sucursal' : 'Seleccionar Tienda',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TuLojitaBrandColors.inkPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canSelectAllBranches) ...[
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: TuLojitaBrandColors.indigo50,
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedStore01,
                                color: TuLojitaBrandColors.indigo600,
                              ),
                            ),
                            title: Text(
                              multipleBranches ? 'Todas las sucursales' : 'Mi Tienda',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              multipleBranches
                                  ? 'Consolidado de toda la empresa'
                                  : 'Resumen general',
                            ),
                            trailing: selectedStoreId == 'all'
                                ? const Icon(
                                    Icons.check_circle,
                                    color: TuLojitaBrandColors.indigo600,
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              onStoreSelected('all');
                              Navigator.pop(ctx);
                            },
                          ),
                          const Divider(),
                        ],
                        ...stores.map((store) {
                          final isSelected = selectedStoreId == store.id;
                          final branchSubtitle =
                              store.shouldShowBranch ? store.branchLabel : null;
                          final logoUrl = resolveDashboardImageUrl(store.logo);

                          return ListTile(
                            leading: ClipOval(
                              child: Container(
                                width: 40,
                                height: 40,
                                color: TuLojitaBrandColors.canvas,
                                child: logoUrl.isNotEmpty
                                    ? Image.network(
                                        logoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: HugeIcon(
                                            icon: HugeIcons.strokeRoundedStore01,
                                            color: TuLojitaBrandColors.inkSecondary,
                                            size: 18,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedStore01,
                                          color: TuLojitaBrandColors.inkSecondary,
                                          size: 18,
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              store.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle:
                                branchSubtitle != null ? Text(branchSubtitle) : null,
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: TuLojitaBrandColors.indigo600,
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              onStoreSelected(store.id);
                              Navigator.pop(ctx);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterDropdownPill extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _FilterDropdownPill({
    required this.icon,
    required this.label,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isHighlighted ? TuLojitaBrandColors.indigo50 : TuLojitaBrandColors.surface;
    final borderColor = isHighlighted
        ? TuLojitaBrandColors.indigo100
        : TuLojitaBrandColors.borderMuted;
    final textColor = isHighlighted
        ? TuLojitaBrandColors.indigo600
        : TuLojitaBrandColors.inkPrimary;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: TuLojitaBrandColors.indigo600,
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                color: isHighlighted
                    ? TuLojitaBrandColors.indigo600
                    : TuLojitaBrandColors.inkSecondary,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
