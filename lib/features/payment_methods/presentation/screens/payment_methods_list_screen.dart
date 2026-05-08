import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/repositories/payment_methods_repository.dart';
import '../../../../core/models/store_payment_method.dart';
import 'payment_method_form_screen.dart';

class PaymentMethodsListScreen extends ConsumerWidget {
  final String storeId;
  const PaymentMethodsListScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(storePaymentMethodsProvider(storeId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Métodos de Pago',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _navigateToForm(context),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
          ),
        ],
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: methods.length,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemBuilder: (context, index) {
              final method = methods[index];
              return _buildMethodCard(context, ref, method);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _navigateToForm(BuildContext context, [StorePaymentMethod? method]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodFormScreen(storeId: storeId, method: method),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payment_outlined,
                color: Color(0xFF9CA3AF),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin métodos de pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Configura cómo tus clientes podrán pagarte. Puedes añadir Pago Móvil, Zelle o Transferencias.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Configurar Primero'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(BuildContext context, WidgetRef ref, StorePaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Icon(
            _getIconForType(method.type),
            color: const Color(0xFF4F46E5),
            size: 24,
          ),
        ),
        title: Text(
          method.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          method.type.displayName,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        trailing: Switch.adaptive(
          value: method.isActive,
          activeTrackColor: const Color(0xFF4F46E5),
          onChanged: (value) async {
            await ref
                .read(paymentMethodsRepositoryProvider)
                .updateMethod(method.id, {'isActive': value});
            ref.invalidate(storePaymentMethodsProvider(storeId));
          },
        ),
        onTap: () => _navigateToForm(context, method),
      ),
    );
  }

  IconData _getIconForType(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.PAGO_MOVIL:
        return Icons.phone_android;
      case PaymentMethodType.TRANSFER:
        return Icons.account_balance;
      case PaymentMethodType.BINANCE:
        return Icons.currency_bitcoin;
      case PaymentMethodType.ZELLE:
        return Icons.email_outlined;
      case PaymentMethodType.OTHER:
        return Icons.payments;
    }
  }
}

