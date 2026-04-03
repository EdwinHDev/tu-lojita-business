import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../widgets/settings_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification02,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () {},
          ),
          Builder(
            builder: (context) => IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      endDrawer: const SettingsDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(context),
            const SizedBox(height: 24),
            Text(
              'Ventas Recientes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildRecentSalesCard(context),
            const SizedBox(height: 24),
            Text(
              'Tiendas Activas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildActiveStoresCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          'Ventas Hoy',
          '\$12,450',
          HugeIcons.strokeRoundedDollar01,
          Colors.green,
          '+12.5%',
        ),
        _buildMetricCard(
          context,
          'Tiendas',
          '8',
          HugeIcons.strokeRoundedStore01,
          Colors.blue,
          '2 nuevas',
        ),
        _buildMetricCard(
          context,
          'Productos',
          '342',
          HugeIcons.strokeRoundedPackage,
          Colors.orange,
          '+28 esta semana',
        ),
        _buildMetricCard(
          context,
          'Clientes',
          '1,234',
          HugeIcons.strokeRoundedUserMultiple,
          Colors.purple,
          '+45 este mes',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    dynamic icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                HugeIcon(icon: icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSaleItem(context, 'Tienda Centro', '\$450', '10:30 AM', Colors.green, HugeIcons.strokeRoundedShoppingBag01),
            const Divider(),
            _buildSaleItem(context, 'Tienda Norte', '\$320', '09:15 AM', Colors.green, HugeIcons.strokeRoundedShoppingBag01),
            const Divider(),
            _buildSaleItem(context, 'Tienda Sur', '\$890', '08:45 AM', Colors.green, HugeIcons.strokeRoundedShoppingBag01),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItem(BuildContext context, String store, String amount, String time, Color color, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStoresCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStoreItem(context, 'Tienda Centro', '45 productos', Colors.blue, HugeIcons.strokeRoundedStore01),
            const Divider(),
            _buildStoreItem(context, 'Tienda Norte', '32 productos', Colors.orange, HugeIcons.strokeRoundedStore01),
            const Divider(),
            _buildStoreItem(context, 'Tienda Sur', '58 productos', Colors.purple, HugeIcons.strokeRoundedStore01),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context, String name, String products, Color color, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  products,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }
}
