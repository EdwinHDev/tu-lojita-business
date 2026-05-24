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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: logoUrl.isNotEmpty ? Colors.white : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            image: logoUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(logoUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: logoUrl.isEmpty
              ? const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                )
              : null,
        ),
        title: Text(
          (store.branchName != null && store.branchName!.isNotEmpty)
              ? store.branchName!
              : store.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.3,
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
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            if (store.address != null && store.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  store.address!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  isActive ? 'Activa' : 'Inactiva',
                  isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                ),
                const SizedBox(width: 12),
                Text(
                  '${store.productsCount} productos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          color: Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
