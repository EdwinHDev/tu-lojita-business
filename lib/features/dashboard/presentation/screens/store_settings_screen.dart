import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/config/envs.dart';
import '../providers/store_settings_notifier.dart';
import '../providers/store_settings_state.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;

  const StoreSettingsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _feeController = TextEditingController();
  final _minInitialController = TextEditingController();
  final _installmentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
    });
  }

  @override
  void dispose() {
    _feeController.dispose();
    _minInitialController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    // Append dimensions for banner
    return '${Envs.apiBaseUrlImages}/$cleanPath?w=1200&h=400';
  }

  void _listenToSuccess(StoreSettingsState? previous, StoreSettingsState next) {
    if (next.successMessage != null && previous?.successMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.successMessage!),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
    if (next.error != null && previous?.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.error!),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }

    // Sync controllers if store is loaded
    if (next.store != null && previous?.store == null) {
      _feeController.text = next.feePercentage.toString();
      _minInitialController.text = next.minInitialPercentage.toString();
      _installmentsController.text = next.maxInstallments.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);
    ref.listen(storeSettingsProvider, _listenToSuccess);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Imagen de Portada'),
                  const SizedBox(height: 12),
                  _buildBannerPicker(state),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Políticas de Pago'),
                  const SizedBox(height: 16),
                  _buildPartialPaymentsSection(state),
                  const SizedBox(height: 40),
                  _buildSaveButton(state),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildBannerPicker(StoreSettingsState state) {
    ImageProvider? imageProvider;
    if (state.bannerFile != null) {
      imageProvider = FileImage(state.bannerFile!);
    } else if (state.store?.coverImage != null && state.store!.coverImage!.isNotEmpty) {
      imageProvider = NetworkImage(_resolveImageUrl(state.store!.coverImage));
    }

    return GestureDetector(
      onTap: () => ref.read(storeSettingsProvider.notifier).pickBanner(),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          image: imageProvider != null
              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: imageProvider == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedImageAdd02,
                    color: Color(0xFF6B7280),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Subir Banner (3:1)',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPartialPaymentsSection(StoreSettingsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permitir pagos parciales',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Permite a los clientes pagar en cuotas',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: state.allowPartialPayments,
                activeTrackColor: const Color(0xFF4F46E5),
                onChanged: (val) => ref
                    .read(storeSettingsProvider.notifier)
                    .updatePartialPayments(val),
              ),
            ],
          ),
          if (state.allowPartialPayments) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'Porcentaje de recargo (%)',
              controller: _feeController,
              onChanged: (val) => ref
                  .read(storeSettingsProvider.notifier)
                  .updateFeePercentage(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Pago inicial mínimo (%)',
              controller: _minInitialController,
              onChanged: (val) => ref
                  .read(storeSettingsProvider.notifier)
                  .updateMinInitialPercentage(double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Número máximo de cuotas',
              controller: _installmentsController,
              keyboardType: TextInputType.number,
              onChanged: (val) => ref
                  .read(storeSettingsProvider.notifier)
                  .updateMaxInstallments(int.tryParse(val) ?? 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(StoreSettingsState state) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: state.isSaving
            ? null
            : () => ref.read(storeSettingsProvider.notifier).saveSettings(widget.storeId),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: state.isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
