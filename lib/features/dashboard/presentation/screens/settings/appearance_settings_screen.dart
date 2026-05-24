import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../providers/store_settings_notifier.dart';
import '../../providers/store_settings_state.dart';
import 'widgets/settings_widgets.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  final String storeId;
  const AppearanceSettingsScreen({super.key, required this.storeId});

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath?w=1200&h=400';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeSettingsProvider);

    ref.listen(storeSettingsProvider.select((s) => s.successMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        NotificationService.showSuccess(context, next);
      }
    });

    ref.listen(storeSettingsProvider.select((s) => s.error), (prev, next) {
      if (next != null && next.isNotEmpty) {
        NotificationService.showError(context, next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Identidad Visual',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsSectionTitle(title: 'Imagen de Portada'),
            const SizedBox(height: 12),
            _buildBannerPicker(ref, state),
            const SizedBox(height: 40),
            _buildSaveButton(ref, state, storeId),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPicker(WidgetRef ref, StoreSettingsState state) {
    ImageProvider? imageProvider;
    if (state.bannerFile != null) {
      imageProvider = FileImage(state.bannerFile!);
    } else if (state.store?.coverImage != null &&
        state.store!.coverImage!.isNotEmpty) {
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

  Widget _buildSaveButton(
    WidgetRef ref,
    StoreSettingsState state,
    String storeId,
  ) {
    final hasChanges = state.bannerFile != null;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (state.isSaving || !hasChanges)
            ? null
            : () => ref
                  .read(storeSettingsProvider.notifier)
                  .saveSettings(storeId),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          disabledForegroundColor: const Color(0xFF9CA3AF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: state.isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Guardar Cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
