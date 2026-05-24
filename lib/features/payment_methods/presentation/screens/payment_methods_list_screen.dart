import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/repositories/payment_methods_repository.dart';
import '../../../../core/models/store_payment_method.dart';
import 'payment_method_form_screen.dart';

class PaymentMethodsListScreen extends ConsumerStatefulWidget {
  final String storeId;
  const PaymentMethodsListScreen({super.key, required this.storeId});

  @override
  ConsumerState<PaymentMethodsListScreen> createState() =>
      _PaymentMethodsListScreenState();
}

class _PaymentMethodsListScreenState
    extends ConsumerState<PaymentMethodsListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _emptyStateController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emptyStateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _emptyStateController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _emptyStateController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _emptyStateController.dispose();
    super.dispose();
  }

  void _navigateToForm([StorePaymentMethod? method]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PaymentMethodFormScreen(storeId: widget.storeId, method: method),
      ),
    );
  }

  /// Returns the most relevant detail string for a payment method.
  String _getKeyDetail(StorePaymentMethod method) {
    switch (method.type) {
      case PaymentMethodType.pagoMovil:
        final parts = <String>[];
        if (method.bank != null) parts.add(method.bank!.name);
        if (method.phoneNumber != null) parts.add(method.phoneNumber!);
        return parts.isNotEmpty ? parts.join(' · ') : method.type.displayName;
      case PaymentMethodType.transfer:
        final parts = <String>[];
        if (method.bank != null) parts.add(method.bank!.name);
        if (method.accountNumber != null) {
          final acc = method.accountNumber!;
          parts.add(
            acc.length > 8
                ? '****${acc.substring(acc.length - 4)}'
                : acc,
          );
        }
        return parts.isNotEmpty ? parts.join(' · ') : method.type.displayName;
      case PaymentMethodType.binance:
        if (method.walletAddress != null) {
          final w = method.walletAddress!;
          return w.length > 12
              ? '${w.substring(0, 6)}…${w.substring(w.length - 4)}'
              : w;
        }
        return method.type.displayName;
    }
  }

  /// Returns the HugeIcon data for each payment method type.
  List<List<dynamic>> _getHugeIconForType(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.pagoMovil:
        return HugeIcons.strokeRoundedSmartPhone01;
      case PaymentMethodType.transfer:
        return HugeIcons.strokeRoundedBank;
      case PaymentMethodType.binance:
        return HugeIcons.strokeRoundedBitcoin01;
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(storePaymentMethodsProvider(widget.storeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
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
      ),
      body: methodsAsync.when(
        data: (methods) {
          if (methods.isEmpty) {
            _emptyStateController.forward();
            return _buildEmptyState();
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: methods.length,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemBuilder: (context, index) {
                    return _buildMethodCard(methods[index]);
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToForm(),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Agregar Método',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCreditCard,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Sin métodos de pago',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Configura cómo tus clientes podrán pagarte.\nPuedes añadir Pago Móvil, Zelle o Transferencias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: () => _navigateToForm(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Agregar Método',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(StorePaymentMethod method) {
    final keyDetail = _getKeyDetail(method);
    final isActive = method.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4F46E5).withValues(alpha: 0.15)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToForm(method),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: _getHugeIconForType(method.type),
                    color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      keyDetail,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFF9CA3AF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Switch
              Switch.adaptive(
                value: isActive,
                activeTrackColor: const Color(0xFF4F46E5),
                onChanged: (value) async {
                  await ref
                      .read(paymentMethodsRepositoryProvider)
                      .updateMethod(method.id, {'isActive': value});
                  ref.invalidate(storePaymentMethodsProvider(widget.storeId));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
