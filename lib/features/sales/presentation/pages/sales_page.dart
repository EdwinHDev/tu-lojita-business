import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
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
          _buildSaleCard(
            context,
            '#12345',
            'Juan Pérez',
            'Tienda Centro',
            '\$450.00',
            '10:30 AM',
            'Completada',
            Colors.green,
            3,
          ),
          const SizedBox(height: 12),
          _buildSaleCard(
            context,
            '#12344',
            'María García',
            'Tienda Norte',
            '\$320.50',
            '09:15 AM',
            'Completada',
            Colors.green,
            2,
          ),
          const SizedBox(height: 12),
          _buildSaleCard(
            context,
            '#12343',
            'Carlos López',
            'Tienda Sur',
            '\$890.00',
            '08:45 AM',
            'Pendiente',
            Colors.orange,
            5,
          ),
          const SizedBox(height: 12),
          _buildSaleCard(
            context,
            '#12342',
            'Ana Martínez',
            'Tienda Centro',
            '\$125.99',
            'Ayer 18:30',
            'Completada',
            Colors.green,
            1,
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(
    BuildContext context,
    String orderId,
    String customer,
    String store,
    String amount,
    String time,
    String status,
    Color statusColor,
    int items,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  customer,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedStore01,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  store,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$items items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
