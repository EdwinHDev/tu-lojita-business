import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';
import 'package:tu_lojita_business/features/items/presentation/providers/item_list_notifier.dart';
import 'dart:async';

class ItemListScreen extends ConsumerStatefulWidget {
  final String storeId;
  const ItemListScreen({super.key, required this.storeId});

  @override
  ConsumerState<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends ConsumerState<ItemListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
      ref.read(storeDetailsProvider.notifier).loadData(widget.storeId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(itemListProvider.notifier).loadNextPage(widget.storeId);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(itemListProvider.notifier).setSearchQuery(widget.storeId, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeData = ref.watch(storeDetailsProvider).forStore(widget.storeId);
    final listState = ref.watch(itemListProvider).forStore(widget.storeId);
    final items = listState.items;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Gestionar Artículos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(storeData),
          Expanded(
            child: listState.isLoading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => ref.read(itemListProvider.notifier).loadInitial(widget.storeId),
                    child: items.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: items.length + (listState.isLoadMoreLoading ? 1 : 0),
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index == items.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                              return _buildItemCard(items[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push(
            '/dashboard/stores/${widget.storeId}/items/new',
          );
          if (result == true && mounted) {
            ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
          }
        },
        backgroundColor: const Color(0xFF4F46E5),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildSearchAndFilters(StoreDetailsData storeData) {
    final listState = ref.watch(itemListProvider).forStore(widget.storeId);
    final notifier = ref.read(itemListProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Row 1: Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Todas',
                  isSelected: listState.selectedCategoryId == null,
                  onSelected: (_) => notifier.setCategory(widget.storeId, null),
                ),
                ...storeData.categories.map((cat) => _buildFilterChip(
                      label: cat.name,
                      isSelected: listState.selectedCategoryId == cat.id,
                      onSelected: (_) => notifier.setCategory(widget.storeId, cat.id),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Sort and Meta-Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Recientes',
                  isSelected: listState.sortBy == 'createdAt' && listState.order == 'DESC',
                  onSelected: (_) => notifier.setSort(widget.storeId, 'createdAt', 'DESC'),
                ),
                _buildFilterChip(
                  label: 'Precio: ↓',
                  isSelected: listState.sortBy == 'price' && listState.order == 'ASC',
                  onSelected: (_) => notifier.setSort(widget.storeId, 'price', 'ASC'),
                ),
                _buildFilterChip(
                  label: 'Precio: ↑',
                  isSelected: listState.sortBy == 'price' && listState.order == 'DESC',
                  onSelected: (_) => notifier.setSort(widget.storeId, 'price', 'DESC'),
                ),
                _buildFilterChip(
                  label: 'Solo Stock',
                  isSelected: listState.onlyInStock,
                  onSelected: (val) => notifier.setOnlyInStock(widget.storeId, val),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    notifier.resetFilters(widget.storeId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Limpiar',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedPackage01,
              color: Colors.grey,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay artículos aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comienza agregando tu primer producto o servicio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }

  Widget _buildItemCard(Item item) {
    final imageUrl = _resolveImageUrl(item.mainImage);
    return GestureDetector(
      onTap: () => context.push('/dashboard/stores/${widget.storeId}/items/detail', extra: item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? const Icon(Icons.image, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.itemType == ItemType.product ? 'Producto' : 'Servicio',
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${item.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    ),
  );
}
}
