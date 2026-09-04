import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/repositories/payment_methods_repository.dart';
import '../providers/store_details_notifier.dart';
import 'create_store_category_modal.dart';
import '../../../payment_methods/presentation/screens/payment_methods_list_screen.dart';

class ItemCreationPrerequisitesModal extends ConsumerStatefulWidget {
  final String storeId;
  final bool initialHasCategories;
  final bool initialHasActivePaymentMethods;
  final VoidCallback onPrerequisitesMet;

  const ItemCreationPrerequisitesModal({
    super.key,
    required this.storeId,
    required this.initialHasCategories,
    required this.initialHasActivePaymentMethods,
    required this.onPrerequisitesMet,
  });

  static Future<void> show({
    required BuildContext context,
    required String storeId,
    required bool hasCategories,
    required bool hasActivePaymentMethods,
    required VoidCallback onPrerequisitesMet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ItemCreationPrerequisitesModal(
        storeId: storeId,
        initialHasCategories: hasCategories,
        initialHasActivePaymentMethods: hasActivePaymentMethods,
        onPrerequisitesMet: onPrerequisitesMet,
      ),
    );
  }

  @override
  ConsumerState<ItemCreationPrerequisitesModal> createState() =>
      _ItemCreationPrerequisitesModalState();
}

class _ItemCreationPrerequisitesModalState
    extends ConsumerState<ItemCreationPrerequisitesModal> {
  late bool _hasCategories;
  late bool _hasActivePaymentMethods;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _hasCategories = widget.initialHasCategories;
    _hasActivePaymentMethods = widget.initialHasActivePaymentMethods;
  }

  Future<void> _recheckPrerequisites() async {
    setState(() => _isChecking = true);
    try {
      // 1. Re-check categories
      await ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
      final storeData = ref.read(storeDetailsProvider).forStore(widget.storeId);
      final hasCategories = storeData.categories.isNotEmpty;

      // 2. Re-check payment methods
      ref.invalidate(storePaymentMethodsProvider(widget.storeId));
      final methods = await ref.read(paymentMethodsRepositoryProvider).getStoreMethods(widget.storeId);
      final hasActivePaymentMethods = methods.any((m) => m.isActive);

      if (mounted) {
        setState(() {
          _hasCategories = hasCategories;
          _hasActivePaymentMethods = hasActivePaymentMethods;
          _isChecking = false;
        });

        if (_hasCategories && _hasActivePaymentMethods) {
          Navigator.pop(context);
          widget.onPrerequisitesMet();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _openCreateCategory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => CreateStoreCategoryModal(
        storeId: widget.storeId,
        onSuccess: () {
          _recheckPrerequisites();
        },
      ),
    );
  }

  Future<void> _openPaymentMethods() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodsListScreen(storeId: widget.storeId),
      ),
    );
    _recheckPrerequisites();
  }

  @override
  Widget build(BuildContext context) {
    final bool allMet = _hasCategories && _hasActivePaymentMethods;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with alert icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración Previa Requerida',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Completa estos pasos para publicar artículos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isChecking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Para que tus clientes puedan explorar tu catálogo y pagar sus compras, tu tienda debe tener configurado:',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // ── Requirement 1: Categoría ──
            _buildChecklistItem(
              title: 'Categoría de Productos',
              description: _hasCategories
                  ? 'Tu tienda cuenta con categorías registradas.'
                  : 'Necesitas al menos una categoría para clasificar el artículo.',
              isMet: _hasCategories,
              icon: HugeIcons.strokeRoundedFolder01,
              actionLabel: 'Crear Categoría',
              onAction: _hasCategories ? null : _openCreateCategory,
            ),

            const SizedBox(height: 12),

            // ── Requirement 2: Métodos de Pago ──
            _buildChecklistItem(
              title: 'Método de Pago Activo',
              description: _hasActivePaymentMethods
                  ? 'Tu tienda tiene métodos de pago listos para cobrar.'
                  : 'Configura Pago Móvil o transferencia para recibir pagos.',
              isMet: _hasActivePaymentMethods,
              icon: HugeIcons.strokeRoundedCreditCard,
              actionLabel: 'Configurar Pagos',
              onAction: _hasActivePaymentMethods ? null : _openPaymentMethods,
            ),

            const SizedBox(height: 24),

            // Bottom action buttons
            if (allMet)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onPrerequisitesMet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuar a Crear Artículo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _recheckPrerequisites,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Verificar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String description,
    required bool isMet,
    required List<List<dynamic>> icon,
    required String actionLabel,
    VoidCallback? onAction,
  }) {
    final Color badgeColor = isMet ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final Color badgeBg = isMet ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final String statusText = isMet ? 'Listo' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMet ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMet
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: isMet ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: badgeColor,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isMet && onAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
