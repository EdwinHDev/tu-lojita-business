import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/entities/item.dart';
import '../../../../core/config/envs.dart';
import '../providers/item_list_notifier.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String storeId;
  final Item item;

  const ItemDetailScreen({super.key, required this.storeId, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Descripción'),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  if (item.attributes != null && item.attributes!['properties'] != null) ...[
                    _buildSectionTitle('Especificaciones y Propiedades'),
                    const SizedBox(height: 16),
                    _buildPropertiesGrid(List<Map<String, dynamic>>.from(item.attributes!['properties'])),
                  ],
                  if (item.customizationGroups.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Personalizaciones y Opciones'),
                    const SizedBox(height: 16),
                    ...item.customizationGroups.map((group) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (group.minSelect > 0 || group.maxSelect > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${group.minSelect > 0 ? "Mín: ${group.minSelect}" : ""} ${group.maxSelect > 0 ? "Máx: ${group.maxSelect}" : ""}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...group.options.map((opt) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      opt.name,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                                    ),
                                    Text(
                                      opt.price > 0 ? '+\$${opt.price.toStringAsFixed(2)}' : 'Incluido',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: opt.price > 0 ? const Color(0xFF4F46E5) : const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final imageUrl = _resolveImageUrl(item.mainImage);
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, fit: BoxFit.cover)
            else
              Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.image, size: 64, color: Colors.grey)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await context.push('/dashboard/stores/$storeId/items/new', extra: item);
              if (result == true && context.mounted) {
                ref.read(itemListProvider.notifier).loadInitial(storeId);
                context.pop();
              }
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar artículo'),
                  content: const Text('¿Estás seguro de que deseas eliminar este artículo? Esta acción no se puede deshacer.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                try {
                  await ref.read(itemListProvider.notifier).deleteItem(storeId, item.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artículo eliminado exitosamente'), backgroundColor: Colors.green));
                    context.pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red));
                  }
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.itemType == ItemType.product ? 'PRODUCTO' : 'SERVICIO',
                style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
            if (item.isFeatured) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 10, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text('DESTACADO', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: item.discountPrice != null ? const Color(0xFF64748B) : const Color(0xFF4F46E5),
                decoration: item.discountPrice != null ? TextDecoration.lineThrough : null,
              ),
            ),
            if (item.discountPrice != null) ...[
              const SizedBox(width: 12),
              Text(
                '\$${item.discountPrice!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
    );
  }

  Widget _buildPropertiesGrid(List<Map<String, dynamic>> properties) {
    return Column(
      children: properties.map((prop) => _buildPropertyItem(prop)).toList(),
    );
  }

  Widget _buildPropertyItem(Map<String, dynamic> prop) {
    final key = prop['key'] as String;
    final type = prop['type'] as String;
    final value = prop['value'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _buildPropertyValue(type, value),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyValue(String type, dynamic value) {
    if (value == null) return const Text('N/A');

    switch (type) {
      case 'LIST':
        final list = List<String>.from(value);
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: list.map((e) => _buildBadge(e)).toList(),
        );
      case 'COLOR_LIST':
        final list = List<String>.from(value);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list.map((e) => _buildColorCircle(e)).toList(),
        );
      case 'BOOLEAN':
        return HugeIcon(
          icon: value == true ? HugeIcons.strokeRoundedTick01 : HugeIcons.strokeRoundedCancel01,
          color: value == true ? Colors.green : Colors.red,
          size: 20,
        );
      default:
        return Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B)));
    }
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
    );
  }

  Widget _buildColorCircle(String hex) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: _parseHexColor(hex),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath';
  }
}
