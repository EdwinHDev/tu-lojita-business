import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes (CRM)'),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCustomerCard(
            context,
            'Juan Pérez',
            'juan.perez@email.com',
            '+1 234 567 890',
            12,
            '\$2,450.00',
            'VIP',
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildCustomerCard(
            context,
            'María García',
            'maria.garcia@email.com',
            '+1 234 567 891',
            8,
            '\$1,320.50',
            'Regular',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildCustomerCard(
            context,
            'Carlos López',
            'carlos.lopez@email.com',
            '+1 234 567 892',
            5,
            '\$890.00',
            'Nuevo',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildCustomerCard(
            context,
            'Ana Martínez',
            'ana.martinez@email.com',
            '+1 234 567 893',
            15,
            '\$3,125.99',
            'VIP',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    String name,
    String email,
    String phone,
    int orders,
    String totalSpent,
    String tier,
    Color tierColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: tierColor.withValues(alpha: 0.2),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: tierColor,
                    ),
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              color: tierColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tier,
                              style: TextStyle(
                                color: tierColor,
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
                            icon: HugeIcons.strokeRoundedMail01,
                            size: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCall,
                            size: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
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
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatColumn(
                    context,
                    HugeIcons.strokeRoundedShoppingBag01,
                    'Pedidos',
                    orders.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _buildStatColumn(
                    context,
                    HugeIcons.strokeRoundedDollar01,
                    'Total Gastado',
                    totalSpent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: _buildStatColumn(
                    context,
                    HugeIcons.strokeRoundedCalendar03,
                    'Última Compra',
                    'Hace 2 días',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, dynamic icon, String label, String value) {
    return Column(
      children: [
        HugeIcon(
          icon: icon,
          size: 18,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
