import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class StoresPage extends StatelessWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tiendas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStoreCard(
            context,
            'Tienda Centro',
            'Av. Principal #123',
            45,
            '\$12,450',
            Colors.blue,
            true,
          ),
          const SizedBox(height: 12),
          _buildStoreCard(
            context,
            'Tienda Norte',
            'Calle Norte #456',
            32,
            '\$8,320',
            Colors.orange,
            true,
          ),
          const SizedBox(height: 12),
          _buildStoreCard(
            context,
            'Tienda Sur',
            'Zona Sur #789',
            58,
            '\$15,890',
            Colors.purple,
            true,
          ),
          const SizedBox(height: 12),
          _buildStoreCard(
            context,
            'Tienda Este',
            'Sector Este #321',
            28,
            '\$6,540',
            Colors.green,
            false,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateStoreDialog(context);
        },
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
        ),
        label: const Text('Nueva Tienda'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    String name,
    String address,
    int products,
    String sales,
    Color color,
    bool isActive,
  ) {
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade600 : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Activa' : 'Inactiva',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            size: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            address,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreVertical,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    HugeIcons.strokeRoundedPackage,
                    'Productos',
                    products.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    HugeIcons.strokeRoundedDollar01,
                    'Ventas Hoy',
                    sales,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    HugeIcons.strokeRoundedAnalytics01,
                    'Estado',
                    isActive ? 'Abierta' : 'Cerrada',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, dynamic icon, String label, String value) {
    return Column(
      children: [
        HugeIcon(icon: icon, size: 20, color: Theme.of(context).textTheme.bodyMedium?.color),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _showCreateStoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Tienda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre de la tienda',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tienda creada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
