import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/config/envs.dart';
import '../../domain/entities/store.dart';

class StoreListTile extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreListTile({
    super.key,
    required this.store,
    required this.onTap,
  });

  String _resolveLogoUrl(String logo) {
    if (logo.isEmpty) return '';
    if (logo.startsWith('http')) return logo;
    // Remove leading slash if present to avoid double slashes
    final path = logo.startsWith('/') ? logo.substring(1) : logo;
    return '${Envs.apiBaseUrlImages}/$path';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = store.status.toUpperCase() == 'ACTIVE';
    final logoUrl = _resolveLogoUrl(store.logo);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            image: logoUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(logoUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: logoUrl.isEmpty
              ? const HugeIcon(
                  icon: HugeIcons.strokeRoundedStore01,
                  color: Colors.grey,
                )
              : null,
        ),
        title: Text(
          (store.branchName != null && store.branchName!.isNotEmpty)
              ? store.branchName!
              : store.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.branchName != null && store.branchName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  'Tienda: ${store.name}',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            if (store.address != null)
              Text(
                store.address!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(
                  isActive ? 'Activa' : 'Inactiva',
                  isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '${store.productsCount} productos',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
