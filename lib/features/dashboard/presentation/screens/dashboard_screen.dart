import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/views/home_view.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/views/stores_view.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [HomeView(), StoresView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ref.watch(notificationsProvider).maybeWhen(
            data: (notifications) {
              final unreadCount = notifications.where((n) => !n.isRead).length;
              return Badge(
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                child: IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: Colors.indigo,
                  ),
                  onPressed: () => context.go('/dashboard/notifications'),
                ),
              );
            },
            orElse: () => IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: Colors.indigo,
              ),
              onPressed: () => context.go('/dashboard/notifications'),
            ),
          ),
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSettings01,
              color: Colors.indigo,
            ),
            onPressed: () => context.go('/dashboard/settings'),
          ),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: _views)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: Colors.grey,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: Colors.indigo,
            ),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedStore01,
              color: Colors.grey,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedStore01,
              color: Colors.indigo,
            ),
            label: 'Tiendas',
          ),
        ],
      ),
    );
  }
}
