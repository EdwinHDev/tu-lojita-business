import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/category.dart';
import 'package:tu_lojita_business/features/categories/domain/entities/subcategory.dart';
import 'package:tu_lojita_business/features/categories/presentation/providers/category_providers.dart';

class CategorySelectionBottomSheet extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String? initialSubcategoryId;

  const CategorySelectionBottomSheet({
    super.key,
    this.initialCategoryId,
    this.initialSubcategoryId,
  });

  @override
  ConsumerState<CategorySelectionBottomSheet> createState() =>
      _CategorySelectionBottomSheetState();
}

class _CategorySelectionBottomSheetState
    extends ConsumerState<CategorySelectionBottomSheet> {
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Categories Pagination State
  final ScrollController _catScrollController = ScrollController();
  List<Category> _categories = [];
  int _catPage = 1;
  bool _catHasMore = true;
  bool _catLoading = false;
  bool _catLoadingMore = false;
  String? _catError;

  // Subcategories Pagination State
  final ScrollController _subScrollController = ScrollController();
  List<Subcategory> _subcategories = [];
  int _subPage = 1;
  bool _subHasMore = true;
  bool _subLoading = false;
  bool _subLoadingMore = false;
  String? _subError;

  @override
  void initState() {
    super.initState();
    _catScrollController.addListener(_onCatScroll);
    _subScrollController.addListener(_onSubScroll);
    _fetchCategories(isRefresh: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _catScrollController.removeListener(_onCatScroll);
    _catScrollController.dispose();
    _subScrollController.removeListener(_onSubScroll);
    _subScrollController.dispose();
    super.dispose();
  }

  void _onCatScroll() {
    if (_catScrollController.hasClients &&
        _catScrollController.position.pixels >=
            _catScrollController.position.maxScrollExtent - 200) {
      _fetchCategories(isRefresh: false);
    }
  }

  void _onSubScroll() {
    if (_subScrollController.hasClients &&
        _subScrollController.position.pixels >=
            _subScrollController.position.maxScrollExtent - 200) {
      _fetchSubcategories(isRefresh: false);
    }
  }

  Future<void> _fetchCategories({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _catPage = 1;
        _catHasMore = true;
        _catLoading = true;
        _catError = null;
      });
    } else {
      if (_catLoading || _catLoadingMore || !_catHasMore) return;
      setState(() {
        _catLoadingMore = true;
      });
    }

    try {
      final repository = ref.read(categoryRepositoryProvider);
      final searchVal = _searchController.text.trim();
      final results = await repository.getCategories(
        search: searchVal.isEmpty ? null : searchVal,
        page: _catPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _categories = results;
            _catLoading = false;
          } else {
            _categories.addAll(results);
            _catLoadingMore = false;
          }
          if (results.length < 20) {
            _catHasMore = false;
          } else {
            _catPage++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _catLoading = false;
          _catLoadingMore = false;
          _catError = 'Error al cargar categorías: $e';
        });
      }
    }
  }

  Future<void> _fetchSubcategories({bool isRefresh = false}) async {
    if (_selectedCategory == null) return;

    if (isRefresh) {
      setState(() {
        _subPage = 1;
        _subHasMore = true;
        _subLoading = true;
        _subError = null;
      });
    } else {
      if (_subLoading || _subLoadingMore || !_subHasMore) return;
      setState(() {
        _subLoadingMore = true;
      });
    }

    try {
      final repository = ref.read(subcategoryRepositoryProvider);
      final searchVal = _searchController.text.trim();
      final results = await repository.getSubcategories(
        _selectedCategory!.id,
        search: searchVal.isEmpty ? null : searchVal,
        page: _subPage,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _subcategories = results;
            _subLoading = false;
          } else {
            _subcategories.addAll(results);
            _subLoadingMore = false;
          }
          if (results.length < 20) {
            _subHasMore = false;
          } else {
            _subPage++;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subLoading = false;
          _subLoadingMore = false;
          _subError = 'Error al cargar subcategorías: $e';
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_selectedCategory == null) {
        _fetchCategories(isRefresh: true);
      } else {
        _fetchSubcategories(isRefresh: true);
      }
    });
  }

  void _selectCategory(Category category) {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategory = category;
      _subcategories = [];
    });
    _fetchSubcategories(isRefresh: true);
  }

  void _backToCategories() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategory = null;
      _subcategories = [];
    });
    _fetchCategories(isRefresh: true);
  }

  Widget _buildAgeBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔞', style: TextStyle(fontSize: 10)),
          SizedBox(width: 3),
          Text(
            '+18',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer({
    required String? imageUrl,
    required dynamic fallbackIcon,
  }) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final fullUrl = hasImage
        ? (imageUrl.startsWith('http')
            ? imageUrl
            : '${Envs.apiBaseUrlImages}$imageUrl')
        : null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: fullUrl != null
          ? Image.network(
              fullUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.indigo.withValues(alpha: 0.06),
                child: Center(
                  child: HugeIcon(
                    icon: fallbackIcon,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            )
          : Container(
              color: Colors.indigo.withValues(alpha: 0.06),
              child: Center(
                child: HugeIcon(
                  icon: fallbackIcon,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_selectedCategory != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _backToCategories,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedCategory == null
                                  ? 'Selecciona una Categoría'
                                  : _selectedCategory!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge +18 en encabezado cuando se navega dentro de una categoría de adultos
                          if (_selectedCategory != null &&
                              _selectedCategory!.isAgeRestricted)
                            _buildAgeBadge(),
                        ],
                      ),
                      Text(
                        _selectedCategory == null
                            ? 'Define el rubro principal de tu empresa'
                            : 'Elige la subcategoría específica',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Buscador en servidor
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: _selectedCategory == null
                    ? 'Buscar categoría por nombre...'
                    : 'Buscar subcategoría por nombre...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          if (_selectedCategory == null) {
                            _fetchCategories(isRefresh: true);
                          } else {
                            _fetchSubcategories(isRefresh: true);
                          }
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // List View (Categorías o Subcategorías)
          Expanded(
            child: _selectedCategory == null
                ? _buildCategoriesList()
                : _buildSubcategoriesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_catLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_catError != null && _categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 8),
              Text(_catError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _fetchCategories(isRefresh: true),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron categorías',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      controller: _catScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length + (_catLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _categories.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final cat = _categories[index];
        final isSelected = cat.id == widget.initialCategoryId;

        return ListTile(
          onTap: () => _selectCategory(cat),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.indigo : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          tileColor:
              isSelected ? Colors.indigo.withValues(alpha: 0.05) : null,
          leading: _buildImageContainer(
            imageUrl: cat.image,
            fallbackIcon: HugeIcons.strokeRoundedStore01,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.indigo : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cat.isAgeRestricted) _buildAgeBadge(),
            ],
          ),
          subtitle: cat.description.isNotEmpty
              ? Text(
                  cat.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildSubcategoriesList() {
    if (_subLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subError != null && _subcategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 36),
              const SizedBox(height: 8),
              Text(_subError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _fetchSubcategories(isRefresh: true),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_subcategories.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron subcategorías para esta categoría',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      controller: _subScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _subcategories.length + (_subLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _subcategories.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final sub = _subcategories[index];
        final isSelected = sub.id == widget.initialSubcategoryId;

        return ListTile(
          onTap: () {
            Navigator.pop(context, {
              'categoryId': _selectedCategory!.id,
              'categoryName': _selectedCategory!.name,
              'categoryImageUrl': _selectedCategory!.image,
              'subcategoryId': sub.id,
              'subcategoryName': sub.name,
              'subcategoryImageUrl': sub.imageUrl,
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.indigo : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          tileColor:
              isSelected ? Colors.indigo.withValues(alpha: 0.05) : null,
          leading: _buildImageContainer(
            imageUrl: sub.imageUrl,
            fallbackIcon: HugeIcons.strokeRoundedTag01,
          ),
          title: Text(
            sub.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.indigo : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: sub.description.isNotEmpty
              ? Text(
                  sub.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                )
              : null,
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.indigo)
              : const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        );
      },
    );
  }
}
