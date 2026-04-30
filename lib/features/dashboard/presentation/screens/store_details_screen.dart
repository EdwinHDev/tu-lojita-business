import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/envs.dart';
import '../../domain/entities/store.dart';
import '../providers/store_details_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

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
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
        },
        color: const Color(0xFF4F46E5),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Banner + Info Card + Floating Logo
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildBanner(coverUrl, logoUrl),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 150, 16, 12),
                    child: _buildInfoCard(store),
                  ),
                  _buildFloatingLogo(logoUrl),
                ],
              ),
            ),

            // Business Insights (Embedded Section)
            if (state.dashboard != null)
              SliverToBoxAdapter(child: _buildInsightsSection(state)),

            // Spacer for better layout after removal
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showManagementMenu(context),
        backgroundColor: const Color(0xFF4F46E5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedSettings01,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
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
                  context.push(
                    '/dashboard/stores/${widget.storeId}/categories',
                  );
                },
              ),
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
                title: const Text(
                  'Gestionar Artículos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  context.pop();
                  context.push('/dashboard/stores/${widget.storeId}/items');
                },
              ),
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
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner(String coverUrl, String logoUrl) {
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
                  Colors.black.withValues(alpha: 0.4),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInfoCard(Store? store) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      child: Column(
        children: [
          Text(
            store?.branchName ?? store?.name ?? 'Cargando...',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '0.0 km',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: Colors.grey)),
              ),
              const Text(
                'Min. \$30.00',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
                SizedBox(width: 4),
                Text(
                  '4.9',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '(120 evaluaciones)',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLogo(String logoUrl) {
    return Positioned(
      top: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF3F4F6),
            backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
            child: logoUrl.isEmpty
                ? const Icon(Icons.store, size: 40, color: Colors.grey)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSection(StoreDetailsData state) {
    final dashboard = state.dashboard;
    if (dashboard == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Ventas',
              '\$${dashboard.stats.salesToday.toStringAsFixed(2)}',
            ),
            _buildStatItem('Clientes', '${dashboard.stats.totalCustomers}'),
            _buildStatItem('Productos', '${dashboard.stats.totalItems}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F46E5),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

}
