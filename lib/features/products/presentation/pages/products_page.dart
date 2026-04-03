import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedFilterHorizontal,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProductCard(
            context,
            'Laptop HP 15"',
            'Electrónica',
            '\$899.99',
            'Tienda Centro',
            45,
            'https://via.placeholder.com/150',
          ),
          const SizedBox(height: 12),
          _buildProductCard(
            context,
            'Mouse Inalámbrico',
            'Accesorios',
            '\$25.99',
            'Tienda Norte',
            120,
            'https://via.placeholder.com/150',
          ),
          const SizedBox(height: 12),
          _buildProductCard(
            context,
            'Teclado Mecánico',
            'Accesorios',
            '\$79.99',
            'Tienda Centro',
            32,
            'https://via.placeholder.com/150',
          ),
          const SizedBox(height: 12),
          _buildProductCard(
            context,
            'Monitor 24"',
            'Electrónica',
            '\$199.99',
            'Tienda Sur',
            18,
            'https://via.placeholder.com/150',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          color: Colors.white,
        ),
        label: const Text('Nuevo Producto'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String name,
    String category,
    String price,
    String store,
    int stock,
    String imageUrl,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedStore01,
                        size: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const Spacer(),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedPackage,
                        size: 14,
                        color: stock > 20 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: $stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: stock > 20 ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
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
    );
  }
}
