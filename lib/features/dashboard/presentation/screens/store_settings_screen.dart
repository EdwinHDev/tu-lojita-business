import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/store_settings_notifier.dart';
import '../../../payment_methods/presentation/screens/payment_methods_list_screen.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/partial_payments_settings_screen.dart';
import 'settings/chat_settings_screen.dart';
import 'settings/timezone_settings_screen.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const StoreSettingsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Configuración de Tienda',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedImageAdd02,
                  title: 'Identidad Visual',
                  subtitle: 'Banner y logo de la tienda',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AppearanceSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedCreditCard,
                  title: 'Pagos Parciales',
                  subtitle: 'Cuotas, recargos y frecuencias',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PartialPaymentsSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedChat01,
                  title: 'Configuración de Chat',
                  subtitle: 'Habilitar o deshabilitar chat de órdenes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedWallet01,
                  title: 'Métodos de Pago',
                  subtitle: 'Cuentas bancarias y pagos móviles',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentMethodsListScreen(storeId: widget.storeId)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  title: 'Zona Horaria',
                  subtitle: 'Huso horario para estadísticas y fechas',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TimezoneSettingsScreen(storeId: widget.storeId)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMenuTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: HugeIcon(
            icon: icon,
            color: const Color(0xFF4F46E5),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827), fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B7280), size: 20),
      ),
    );
  }
}
