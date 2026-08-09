import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/dashboard_providers.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    String userName = 'Usuario';
    String companyLogoUrl = '';
    if (authState is Authenticated) {
      userName = authState.user.firstName;
      final company = authState.user.company;
      if (company != null && company.logo.isNotEmpty) {
        companyLogoUrl = company.logo.startsWith('http')
            ? company.logo
            : '${Envs.apiBaseUrlImages}/${company.logo.startsWith('/') ? company.logo.substring(1) : company.logo}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Header Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, $userName! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aquí tienes el rendimiento general de tu red de tiendas hoy.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (companyLogoUrl.isNotEmpty)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      image: DecorationImage(
                        image: NetworkImage(companyLogoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            // Analytics Metrics Grid (2x2)
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.20,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: [
                _HomeMetricCard(
                  title: 'Ventas de hoy',
                  value: '\$1,250.00',
                  icon: HugeIcons.strokeRoundedMoney01,
                  color: Colors.green,
                  badgeText: '+14.8%',
                ),
                _HomeMetricCard(
                  title: 'Órdenes Activas',
                  value: '48',
                  icon: HugeIcons.strokeRoundedPackage,
                  color: Colors.blue,
                  badgeText: '12 pend',
                ),
                _HomeMetricCard(
                  title: 'Clientes Totales',
                  value: '384',
                  icon: HugeIcons.strokeRoundedUserGroup,
                  color: Colors.orange,
                  badgeText: '+24 hoy',
                ),
                _HomeMetricCard(
                  title: 'Tasa Conversión',
                  value: '96.4%',
                  icon: HugeIcons.strokeRoundedAnalytics01,
                  color: Colors.purple,
                  badgeText: 'Excelente',
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Quick Actions Panel
            const Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              children: [
                _QuickActionCard(
                  title: 'Nueva Sucursal',
                  subtitle: 'Crear sedes físicas/virtuales',
                  icon: HugeIcons.strokeRoundedAdd01,
                  onTap: () => context.go('/dashboard/stores/create'),
                ),
                _QuickActionCard(
                  title: 'Notificaciones',
                  subtitle: 'Revisar alertas activas',
                  icon: HugeIcons.strokeRoundedNotification01,
                  onTap: () => context.go('/dashboard/notifications'),
                ),
                _QuickActionCard(
                  title: 'Ajustes Empresa',
                  subtitle: 'Editar detalles generales',
                  icon: HugeIcons.strokeRoundedSettings01,
                  onTap: () => context.go('/dashboard/settings/company'),
                ),
                _QuickActionCard(
                  title: 'Ajustes de Perfil',
                  subtitle: 'Gestionar mi cuenta',
                  icon: HugeIcons.strokeRoundedUser02,
                  onTap: () => ref.read(dashboardIndexProvider.notifier).state = 2,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Branch Office Performance Insights
            const Text(
              'Rendimiento por Sucursal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _BranchProgressRow(
                    name: 'Sucursal Sambil Chacao',
                    sales: '\$650.00',
                    products: 120,
                    progress: 0.85,
                  ),
                  _BranchProgressRow(
                    name: 'Sucursal Las Mercedes',
                    sales: '\$420.00',
                    products: 94,
                    progress: 0.65,
                  ),
                  _BranchProgressRow(
                    name: 'Sucursal La Candelaria',
                    sales: '\$180.00',
                    products: 68,
                    progress: 0.25,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HomeMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final dynamic icon;
  final Color color;
  final String badgeText;

  const _HomeMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.badgeText,
  });

  Color get _resolvedBgColor {
    if (color == Colors.green) return const Color(0xFFECFDF5);
    if (color == Colors.blue) return const Color(0xFFEFF6FF);
    if (color == Colors.orange) return const Color(0xFFFFF7ED);
    if (color == Colors.purple) return const Color(0xFFFAF5FF);
    return color.withValues(alpha: 0.1);
  }

  Color get _resolvedTextColor {
    if (color == Colors.green) return const Color(0xFF047857);
    if (color == Colors.blue) return const Color(0xFF1D4ED8);
    if (color == Colors.orange) return const Color(0xFFC2410C);
    if (color == Colors.purple) return const Color(0xFF7E22CE);
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _resolvedBgColor,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: icon,
                  color: _resolvedTextColor,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _resolvedBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: _resolvedTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: icon,
                color: const Color(0xFF4F46E5),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: Color(0xFF4F46E5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchProgressRow extends StatelessWidget {
  final String name;
  final String sales;
  final int products;
  final double progress;

  const _BranchProgressRow({
    required this.name,
    required this.sales,
    required this.products,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: Color(0xFF4F46E5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Text(
                sales,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEF2FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$products prod',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
