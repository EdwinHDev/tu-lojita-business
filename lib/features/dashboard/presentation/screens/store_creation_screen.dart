import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/categories/presentation/providers/category_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_creation_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';

class StoreCreationScreen extends ConsumerStatefulWidget {
  const StoreCreationScreen({super.key});

  @override
  ConsumerState<StoreCreationScreen> createState() => _StoreCreationScreenState();
}

class _StoreCreationScreenState extends ConsumerState<StoreCreationScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepTapped(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(storeCreationProvider.notifier).setStep(step);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeCreationProvider);
    final notifier = ref.read(storeCreationProvider.notifier);

    // Listen for errors
    ref.listen(storeCreationProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => notifier.clearError(),
            ),
          ),
        );
        // We don't clear it here automatically because the SnackBar has an action,
        // but it's good practice to clear it so it doesn't trigger again on rebuild if not careful.
        // Actually, Riverpod's listen only triggers on change, so it's fine.
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nueva Sucursal'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const _StoreCreationHeader(),
          _StepIndicator(
            currentStep: state.currentStep,
            onStepTapped: _onStepTapped,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Identity(state: state, notifier: notifier),
                _Step2Operations(state: state, notifier: notifier),
                _Step3Categorization(state: state, notifier: notifier),
              ],
            ),
          ),
          _BottomActions(
            state: state,
            onNext: () {
              if (state.currentStep < 2) {
                _onStepTapped(state.currentStep + 1);
              } else {
                _submitForm(context, ref);
              }
            },
            onBack: () {
              if (state.currentStep > 0) {
                _onStepTapped(state.currentStep - 1);
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitForm(BuildContext context, WidgetRef ref) async {
    final state = ref.read(storeCreationProvider);
    final notifier = ref.read(storeCreationProvider.notifier);
    
    notifier.setLoading(true);
    
    try {
      final success = await ref.read(storesProvider.notifier).createStore(
        branchName: state.branchName,
        phone: state.phone,
        description: state.description,
        subCategoryId: state.subCategoryId!,
        address: state.type == StoreType.physical ? {
          'street': state.street,
          'city': state.city,
          'state': state.addressState,
          'country': 'Venezuela',
          'zipCode': '1010',
        } : null,
      );

      if (success) {
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sucursal creada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = ref.read(storesProvider).errorMessage;
        notifier.setError(error ?? 'No se pudo crear la tienda. Verifica los datos.');
      }
    } catch (e) {
      notifier.setError(e.toString());
    } finally {
      notifier.setLoading(false);
    }
  }
}
class _StoreCreationHeader extends ConsumerWidget {
  const _StoreCreationHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final company = authState.user.company;
    if (company == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage('${Envs.apiBaseUrlImages}${company.logo}'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'RIF: ${company.rif}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'HEREDADO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumInputDecoration {
  static InputDecoration get({
    required String label,
    required String hint,
    required dynamic icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: HugeIcon(icon: icon, color: Colors.indigo, size: 22),
      ),
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.indigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTapped;

  const _StepIndicator({
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Row(
        children: [
          _buildStep(0, 'Identidad', currentStep >= 0),
          _buildDivider(currentStep >= 1),
          _buildStep(1, 'Operación', currentStep >= 1),
          _buildDivider(currentStep >= 2),
          _buildStep(2, 'Categoría', currentStep >= 2),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isActive ? Colors.indigo : Colors.grey.shade200,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.indigo : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.indigo : Colors.grey.shade200,
    );
  }
}

class _Step1Identity extends StatelessWidget {
  final StoreCreationState state;
  final StoreCreationNotifier notifier;

  const _Step1Identity({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '¿Cómo se identifica esta sucursal?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Ingresa el nombre distintivo y los datos de contacto.'),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: state.branchName,
          onChanged: notifier.updateBranchName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: PremiumInputDecoration.get(
            label: 'Nombre de la Sucursal',
            hint: 'Ej: Sambil Chacao, Las Mercedes...',
            icon: HugeIcons.strokeRoundedStore01,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          initialValue: state.phone,
          onChanged: notifier.updatePhone,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: PremiumInputDecoration.get(
            label: 'Teléfono de contacto',
            hint: 'Ej: +58 412 1234567',
            icon: HugeIcons.strokeRoundedSmartPhone01,
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          initialValue: state.description,
          onChanged: notifier.updateDescription,
          maxLines: 4,
          style: const TextStyle(height: 1.5),
          decoration: PremiumInputDecoration.get(
            label: 'Descripción de la sucursal',
            hint: 'Cuéntanos un poco sobre esta sede...',
            icon: HugeIcons.strokeRoundedNote01,
          ),
        ),
      ],
    );
  }
}

class _Step2Operations extends StatelessWidget {
  final StoreCreationState state;
  final StoreCreationNotifier notifier;

  const _Step2Operations({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Tipo de Operación',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Define cómo operará esta sucursal.'),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _TypeCard(
                title: 'Física',
                description: 'Venta presencial en sede',
                icon: HugeIcons.strokeRoundedStore01,
                isSelected: state.type == StoreType.physical,
                onTap: () => notifier.updateType(StoreType.physical),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TypeCard(
                title: 'Virtual',
                description: 'Solo entregas a domicilio',
                icon: HugeIcons.strokeRoundedGlobal,
                isSelected: state.type == StoreType.virtual,
                onTap: () => notifier.updateType(StoreType.virtual),
              ),
            ),
          ],
        ),
        if (state.type == StoreType.physical) ...[
          const SizedBox(height: 40),
          Text(
            'Ubicación Física',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: state.street,
            onChanged: notifier.updateStreet,
            decoration: PremiumInputDecoration.get(
              label: 'Calle / Avenida / Edificio',
              hint: 'Ej: Av. Principal de las Mercedes...',
              icon: HugeIcons.strokeRoundedLocation01,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: state.city,
                  onChanged: notifier.updateCity,
                  decoration: PremiumInputDecoration.get(
                    label: 'Ciudad',
                    hint: 'Ej: Caracas',
                    icon: HugeIcons.strokeRoundedCity01,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: state.addressState,
                  onChanged: notifier.updateState,
                  decoration: PremiumInputDecoration.get(
                    label: 'Estado',
                    hint: 'Ej: Miranda',
                    icon: HugeIcons.strokeRoundedLocation01,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Step3Categorization extends ConsumerWidget {
  final StoreCreationState state;
  final StoreCreationNotifier notifier;

  const _Step3Categorization({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectingSubcategory = state.categoryId != null;

    final categoriesState = ref.watch(paginatedCategoriesProvider);
    final categoryName = categoriesState.maybeWhen(
      data: (list) {
        final cat = list.where((c) => c.id == state.categoryId).firstOrNull;
        return cat?.name ?? 'Categoría';
      },
      orElse: () => 'Categoría',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            isSelectingSubcategory ? 'Elegir Subcategoría' : 'Categorización',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            isSelectingSubcategory 
              ? 'Específica qué tipo de productos o servicios ofrecerás.'
              : 'Clasifica tu sucursal para que los usuarios la encuentren fácilmente.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        if (isSelectingSubcategory)
          _Breadcrumb(
            onBack: () => notifier.clearCategory(),
            categoryName: categoryName,
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TextFormField(
            onChanged: notifier.updateSearchQuery,
            decoration: PremiumInputDecoration.get(
              label: 'Buscar...',
              hint: 'Escribe para filtrar...',
              icon: HugeIcons.strokeRoundedSearch01,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Consumer(
              key: ValueKey(isSelectingSubcategory),
              builder: (context, ref, _) {
                if (!isSelectingSubcategory) {
                final categoriesState = ref.watch(paginatedCategoriesProvider);
                
                // Update search if query changed
                ref.listen(storeCreationProvider.select((s) => s.searchQuery), (prev, next) {
                  ref.read(paginatedCategoriesProvider.notifier).updateSearch(next);
                });

                return categoriesState.when(
                  data: (categories) => _CategoryGrid(
                    items: categories,
                    onItemTap: (id) => notifier.updateCategory(id),
                    isSelected: (id) => state.categoryId == id,
                    onLoadMore: () => ref.read(paginatedCategoriesProvider.notifier).fetchNextPage(),
                    isLoadingMore: categoriesState.isLoading,
                    isSubcategory: false,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              } else {
                final subcategoriesState = ref.watch(paginatedSubcategoriesProvider);

                // Update search if query changed
                ref.listen(storeCreationProvider.select((s) => s.searchQuery), (prev, next) {
                  ref.read(paginatedSubcategoriesProvider.notifier).updateSearch(next);
                });

                return subcategoriesState.when(
                  data: (subcategories) => _CategoryGrid(
                    items: subcategories,
                    onItemTap: (id) => notifier.updateSubCategory(id),
                    isSelected: (id) => state.subCategoryId == id,
                    onLoadMore: () => ref.read(paginatedSubcategoriesProvider.notifier).fetchNextPage(),
                    isLoadingMore: subcategoriesState.isLoading,
                    isSubcategory: true,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                );
              }
            },
          ),
        ),
      ),
    ],
    );
  }
}

class _CategoryGrid extends StatefulWidget {
  final List<dynamic> items;
  final Function(String) onItemTap;
  final bool Function(String) isSelected;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool isSubcategory;

  const _CategoryGrid({
    required this.items,
    required this.onItemTap,
    required this.isSelected,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.isSubcategory,
  });

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No se encontraron resultados', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.items.length + (widget.isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return const _CategoryCardPlaceholder();
        }

        final item = widget.items[index];
        return _CategoryCard(
          title: item.name,
          imageUrl: widget.isSubcategory ? item.imageUrl : item.image,
          isSelected: widget.isSelected(item.id),
          onTap: () => widget.onItemTap(item.id),
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Colors.indigo.withValues(alpha: 0.05) : Colors.white,
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.indigo.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HugeIcon(
                  icon: icon,
                  color: isSelected ? Colors.indigo : Colors.grey.shade400,
                  size: 24,
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.indigo, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.indigo : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.indigo : Colors.grey.shade200,
              width: 2,
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: isSelected ? Colors.indigo.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade50,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          '${Envs.apiBaseUrlImages}$imageUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(Icons.category_outlined, color: Colors.grey.shade300, size: 32),
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.indigo,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isSelected ? Colors.indigo : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCardPlaceholder extends StatelessWidget {
  const _CategoryCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final VoidCallback onBack;
  final String categoryName;

  const _Breadcrumb({required this.onBack, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 16, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Text(
                      'Categorías',
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final StoreCreationState state;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BottomActions({
    required this.state,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    bool isNextEnabled = false;
    if (state.currentStep == 0) isNextEnabled = state.branchName.isNotEmpty && state.phone.isNotEmpty;
    if (state.currentStep == 1) isNextEnabled = state.type == StoreType.virtual || (state.street.isNotEmpty && state.city.isNotEmpty);
    if (state.currentStep == 2) isNextEnabled = state.subCategoryId != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (isNextEnabled && !state.isLoading) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: state.isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(state.currentStep == 2 ? 'Crear Sucursal' : 'Siguiente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
