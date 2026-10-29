import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../providers/store_settings_notifier.dart';
import '../../providers/store_settings_state.dart';
import 'widgets/settings_widgets.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const AppearanceSettingsScreen({super.key, required this.storeId});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends ConsumerState<AppearanceSettingsScreen> {
  late final TextEditingController _branchController;
  late final TextEditingController _instagramController;
  late final TextEditingController _tiktokController;

  @override
  void initState() {
    super.initState();
    final settingsState = ref.read(storeSettingsProvider);
    final initialBranch = settingsState.branchName.isNotEmpty
        ? settingsState.branchName
        : (settingsState.store?.branchName ?? '');
    _branchController = TextEditingController(text: initialBranch);

    final initialIg = settingsState.instagram.isNotEmpty
        ? settingsState.instagram
        : (settingsState.store?.instagram ?? '');
    _instagramController = TextEditingController(text: initialIg);

    final initialTt = settingsState.tiktok.isNotEmpty
        ? settingsState.tiktok
        : (settingsState.store?.tiktok ?? '');
    _tiktokController = TextEditingController(text: initialTt);
  }

  @override
  void dispose() {
    _branchController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${Envs.apiBaseUrlImages}/$cleanPath?w=1200&h=400';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);

    // Sync controllers if store loads after initial build
    if (_branchController.text.isEmpty &&
        state.store?.branchName != null &&
        state.store!.branchName!.isNotEmpty) {
      _branchController.text = state.store!.branchName!;
    }
    if (_instagramController.text.isEmpty &&
        state.store?.instagram != null &&
        state.store!.instagram!.isNotEmpty) {
      _instagramController.text = state.store!.instagram!;
    }
    if (_tiktokController.text.isEmpty &&
        state.store?.tiktok != null &&
        state.store!.tiktok!.isNotEmpty) {
      _tiktokController.text = state.store!.tiktok!;
    }

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
          'Identidad Visual y Sucursal',
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
            const SettingsSectionTitle(title: 'Nombre de la Sucursal'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextFormField(
                controller: _branchController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.store_outlined,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                  hintText: 'Ej. Sede Norte, Centro, Principal',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  ref.read(storeSettingsProvider.notifier).updateBranchName(value);
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF16A34A),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este nombre identificará esta sede ante tus clientes como "Sucursal [Nombre]". Si tu empresa tiene una sola tienda, el nombre se mantendrá reservado y solo se mostrará cuando agregues más tiendas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SettingsSectionTitle(title: 'Imagen de Portada (Banner)'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedImage01,
                    color: Color(0xFF4F46E5),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recomendado: 1200 x 400 px (proporción 3:1)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Formatos JPG o PNG. Esta imagen se muestra en la cabecera del perfil de tu tienda y en los resultados del directorio.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildBannerPicker(ref, state),
            const SizedBox(height: 24),
            const SettingsSectionTitle(title: 'Redes Sociales (Opcional)'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextFormField(
                controller: _instagramController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedInstagram,
                      color: Color(0xFFE1306C),
                      size: 20,
                    ),
                  ),
                  hintText: 'Instagram (@tu_tienda)',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  ref.read(storeSettingsProvider.notifier).updateInstagram(value);
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextFormField(
                controller: _tiktokController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTiktok,
                      color: Color(0xFF010101),
                      size: 20,
                    ),
                  ),
                  hintText: 'TikTok (@tu_tienda)',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  ref.read(storeSettingsProvider.notifier).updateTiktok(value);
                },
              ),
            ),
            const SizedBox(height: 36),
            _buildSaveButton(ref, state, widget.storeId),
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
                    'Toca para subir banner',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '1200 x 400 px recomendado (3:1)',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCamera01,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cambiar imagen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '1200 x 400 px',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSaveButton(
    WidgetRef ref,
    StoreSettingsState state,
    String storeId,
  ) {
    final originalBranch = state.store?.branchName?.trim() ?? '';
    final currentBranch = state.branchName.trim();
    final isBranchValid = currentBranch.isNotEmpty;
    final isBranchChanged = currentBranch != originalBranch;

    final originalIg = state.store?.instagram?.trim() ?? '';
    final currentIg = state.instagram.trim().replaceAll(RegExp(r'^@+'), '').trim();
    final isIgChanged = currentIg != originalIg;

    final originalTt = state.store?.tiktok?.trim() ?? '';
    final currentTt = state.tiktok.trim().replaceAll(RegExp(r'^@+'), '').trim();
    final isTtChanged = currentTt != originalTt;

    final hasChanges = isBranchValid &&
        (state.bannerFile != null || isBranchChanged || isIgChanged || isTtChanged);

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
