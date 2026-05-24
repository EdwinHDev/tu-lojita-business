import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/store_details_notifier.dart';
import '../providers/store_category_provider.dart';
import '../providers/dashboard_providers.dart';
import '../../domain/entities/store_category.dart';
import 'create_category_screen.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  final String storeId;
  const CategoryListScreen({super.key, required this.storeId});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Pagination and Local State
  List<StoreCategory> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  int _total = 0;
  String _query = '';
  bool _isSearchingLocal = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNextPage(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchNextPage();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearchingLocal = true;
    });
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _query = value;
        });
        _fetchNextPage(isRefresh: true).then((_) {
          if (mounted) {
            setState(() {
              _isSearchingLocal = false;
            });
          }
        });
      }
    });
  }

  Future<void> _fetchNextPage({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _categories = [];
        _hasMore = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final repository = ref.read(storeCategoryRepositoryProvider);
      final response = await repository.getCategoriesPaginated(
        storeId: widget.storeId,
        limit: 50,
        offset: _offset,
        q: _query.isNotEmpty ? _query : null,
      );

      if (mounted) {
        final nextOffset = _offset + response.categories.length;
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _categories = isRefresh
              ? response.categories
              : [..._categories, ...response.categories];
          _offset = nextOffset;
          _total = response.total;
          _hasMore = nextOffset < response.total;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isSearchingLocal = false;
        });
        NotificationService.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _total > 0 ? 'Gestionar Categorías ($_total)' : 'Gestionar Categorías',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF111827)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Buscar categorías...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                    suffixIcon: _isSearchingLocal
                        ? const UnconstrainedBox(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade100),
            ],
          ),
        ),
      ),
      body: _isLoading && _categories.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : _categories.isEmpty
              ? RefreshIndicator(
                  color: const Color(0xFF4F46E5),
                  onRefresh: () async {
                    await _fetchNextPage(isRefresh: true);
                  },
                  child: _buildEmptyState(context, _query.isNotEmpty),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF4F46E5),
                        onRefresh: () async {
                          await _fetchNextPage(isRefresh: true);
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _categories.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == _categories.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                                ),
                              );
                            }
                            final category = _categories[index];
                            return _buildCategoryCard(context, ref, category);
                          },
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await context.push('/dashboard/stores/${widget.storeId}/categories/new');
                              if (result == true && context.mounted) {
                                NotificationService.showSuccess(context, 'Categoría creada exitosamente');
                                ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
                                _fetchNextPage(isRefresh: true);
                              }
                            },
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedAdd01,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Nueva Categoría',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasQuery) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedTag01,
                color: Color(0xFF4F46E5),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasQuery ? 'No se encontraron resultados' : 'No hay categorías aún',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Prueba con una búsqueda diferente para encontrar lo que necesitas.'
                  : 'Crea tu primera categoría para organizar tus productos y mejorar la experiencia de compra.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4, fontSize: 14),
            ),
            if (!hasQuery) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await context.push('/dashboard/stores/${widget.storeId}/categories/new');
                  if (result == true && context.mounted) {
                    NotificationService.showSuccess(context, 'Categoría creada exitosamente');
                    ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
                    _fetchNextPage(isRefresh: true);
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Crear Categoría', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, dynamic category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCategoryActions(context, category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTag01,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (category.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category.description,
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                onPressed: () => _showCategoryActions(context, category),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryActions(BuildContext context, dynamic category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5), size: 20),
                  ),
                  title: const Text(
                    'Editar categoría',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editCategory(category);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
                  ),
                  title: Text(
                    'Eliminar categoría',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.red.shade600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteCategory(category);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCategory(dynamic category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCategoryScreen(
          storeId: widget.storeId,
          categoryToEdit: category,
        ),
      ),
    );
    if (result == true && mounted) {
      NotificationService.showSuccess(context, 'Categoría actualizada exitosamente');
      ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
      _fetchNextPage(isRefresh: true);
    }
  }

  Future<void> _confirmDeleteCategory(dynamic category) async {
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirmar Eliminación',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Eliminar Categoría?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Estás seguro de eliminar "${category.name}"? Se eliminará la configuración de plantillas de propiedades para la misma.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
      },
    );

    if (confirm == true && mounted) {
      final success = await ref.read(storeCategoryProvider.notifier).deleteCategory(category.id);
      if (success && mounted) {
        NotificationService.showSuccess(context, 'Categoría eliminada exitosamente');
        ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
        _fetchNextPage(isRefresh: true);
      } else if (mounted) {
        final error = ref.read(storeCategoryProvider).errorMessage;
        if (error != null) {
          NotificationService.showError(context, error);
        }
      }
    }
  }
}

