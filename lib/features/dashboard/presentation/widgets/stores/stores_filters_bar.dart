import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';

enum StoresFilterOption {
  all,
  needsAttention,
  active,
  inactiveOrDeletion,
}

/// Filters [stores] cleanly by operational [filter], optional local [query],
/// per-store unread disputes, and caller financial permissions.
List<Store> applyStoresFilter({
  required List<Store> stores,
  required StoresFilterOption filter,
  required String query,
  required Map<String, int> unreadDisputesByStore,
  required bool canViewFinancials,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return stores.where((store) {
    final matchesFilter = switch (filter) {
      StoresFilterOption.all => true,
      StoresFilterOption.needsAttention => store.needsOperationalAttention(
          unreadDisputesCount: unreadDisputesByStore[store.id] ?? 0,
          canViewFinancials: canViewFinancials,
        ),
      StoresFilterOption.active => store.isOperationalActive,
      StoresFilterOption.inactiveOrDeletion => !store.isOperationalActive,
    };
    if (!matchesFilter) return false;

    if (normalizedQuery.isEmpty) return true;
    final haystack = [
      store.name,
      store.branchName ?? '',
      store.address ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(normalizedQuery);
  }).toList();
}

/// Multi-store filter chip strip (shown for `>= 2` stores) and compact local
/// search bar (shown for `>= 4` stores).
class StoresFiltersBar extends StatelessWidget {
  final List<Store> stores;
  final Map<String, int> unreadDisputesByStore;
  final bool canViewFinancials;
  final StoresFilterOption selectedFilter;
  final ValueChanged<StoresFilterOption> onFilterSelected;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const StoresFiltersBar({
    super.key,
    required this.stores,
    required this.unreadDisputesByStore,
    required this.canViewFinancials,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.length < 2) {
      return const SizedBox.shrink();
    }

    final attentionCount = stores
        .where(
          (s) => s.needsOperationalAttention(
            unreadDisputesCount: unreadDisputesByStore[s.id] ?? 0,
            canViewFinancials: canViewFinancials,
          ),
        )
        .length;
    final activeCount = stores.where((s) => s.isOperationalActive).length;
    final inactiveCount = stores.length - activeCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChipPill(
                label: 'Todas (${stores.length})',
                selected: selectedFilter == StoresFilterOption.all,
                onTap: () => onFilterSelected(StoresFilterOption.all),
              ),
              const SizedBox(width: 8),
              _FilterChipPill(
                label: 'Con atención ($attentionCount)',
                selected: selectedFilter == StoresFilterOption.needsAttention,
                useAmberHighlight: attentionCount > 0,
                onTap: () =>
                    onFilterSelected(StoresFilterOption.needsAttention),
              ),
              const SizedBox(width: 8),
              _FilterChipPill(
                label: 'Activas ($activeCount)',
                selected: selectedFilter == StoresFilterOption.active,
                onTap: () => onFilterSelected(StoresFilterOption.active),
              ),
              const SizedBox(width: 8),
              _FilterChipPill(
                label: 'Inactivas / Baja ($inactiveCount)',
                selected:
                    selectedFilter == StoresFilterOption.inactiveOrDeletion,
                onTap: () =>
                    onFilterSelected(StoresFilterOption.inactiveOrDeletion),
              ),
            ],
          ),
        ),
        if (stores.length >= 4) ...[
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 13.5,
              color: TuLojitaBrandColors.inkPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar sede, sucursal o dirección...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: TuLojitaBrandColors.inkSecondary,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: TuLojitaBrandColors.inkSecondary,
                  size: 18,
                ),
              ),
              suffixIcon: searchQuery.trim().isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: TuLojitaBrandColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: TuLojitaBrandColors.borderMuted),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: TuLojitaBrandColors.borderMuted),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: TuLojitaBrandColors.indigo600,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool useAmberHighlight;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.selected,
    this.useAmberHighlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;

    if (selected) {
      bg = useAmberHighlight
          ? TuLojitaBrandColors.amber400
          : TuLojitaBrandColors.indigo600;
      border = bg;
      fg = useAmberHighlight ? TuLojitaBrandColors.inkPrimary : Colors.white;
    } else if (useAmberHighlight) {
      bg = TuLojitaBrandColors.amber50;
      border = TuLojitaBrandColors.amber400;
      fg = TuLojitaBrandColors.amber800;
    } else {
      bg = TuLojitaBrandColors.surface;
      border = TuLojitaBrandColors.borderMuted;
      fg = TuLojitaBrandColors.inkSecondary;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
