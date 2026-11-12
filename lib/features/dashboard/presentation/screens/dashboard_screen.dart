import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/views/home_view.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/views/stores_view.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final List<Widget> _views = const [HomeView(), StoresView(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final redirected = _checkBranchPrerequisites();
      if (!redirected && mounted) {
        ref
            .read(firebaseMessagingServiceProvider)
            .markAppReadyAndConsumePendingNotification();
      }
    });
  }

  bool _checkBranchPrerequisites() {
    if (!mounted) return false;
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return false;
    final user = authState.user;

    // Colaboradores y administradores no configuran primera sede empresarial
    if (user.role == 'ADMIN' || user.isCollaborator) return false;

    final storesState = ref.read(storesProvider);
    // Si aún está cargando la primera vez y no hay datos, esperar
    if (storesState.isLoading && storesState.stores.isEmpty) return false;

    final stores = storesState.stores;
    final needsSetupWizard = stores.isEmpty ||
        (stores.length == 1 &&
            (stores.first.branchName == null ||
                stores.first.branchName!.trim().isEmpty));

    if (needsSetupWizard) {
      context.go('/dashboard/store-setup-wizard');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StoresState>(storesProvider, (previous, next) {
      if (!next.isLoading && (previous?.isLoading == true || previous == null)) {
        _checkBranchPrerequisites();
      }
    });

    final currentIndex = ref.watch(dashboardIndexProvider);
    final unreadDisputesCount = ref.watch(unreadBusinessDisputeOrdersCountProvider);

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: currentIndex, children: _views)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        indicatorColor: TuLojitaBrandColors.indigo50,
        onDestinationSelected: (index) {
          ref.read(dashboardIndexProvider.notifier).state = index;
        },
        destinations: [
          const NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: Colors.grey,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              color: TuLojitaBrandColors.indigo600,
            ),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadDisputesCount > 0,
              backgroundColor: TuLojitaBrandColors.danger,
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                color: Colors.grey,
              ),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadDisputesCount > 0,
              backgroundColor: TuLojitaBrandColors.danger,
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                color: TuLojitaBrandColors.indigo600,
              ),
            ),
            label: 'Tiendas',
          ),
          const NavigationDestination(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUserAccount,
              color: Colors.grey,
            ),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedUserAccount,
              color: TuLojitaBrandColors.indigo600,
            ),
            label: 'Mi Cuenta',
          ),
        ],
      ),
    );
  }

}
