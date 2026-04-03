import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/stores/presentation/pages/stores_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    StoresPage(),
    ProductsPage(),
    SalesPage(),
    CustomersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDashboardSpeed01,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDashboardSpeed01,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedStore01,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedStore01,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Tiendas',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPackage,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedPackage,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingBag01,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedShoppingBag01,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUserMultiple,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            activeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedUserMultiple,
              color: Theme.of(context).primaryColor,
            ),
            label: 'Clientes',
          ),
        ],
      ),
    );
  }
}
