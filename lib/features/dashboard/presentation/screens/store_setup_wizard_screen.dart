import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/store.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/first_branch_tutorial_carousel.dart';

class StoreSetupWizardScreen extends ConsumerStatefulWidget {
  const StoreSetupWizardScreen({super.key});

  @override
  ConsumerState<StoreSetupWizardScreen> createState() =>
      _StoreSetupWizardScreenState();
}

class _StoreSetupWizardScreenState
    extends ConsumerState<StoreSetupWizardScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _branchNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instagramController;
  late final TextEditingController _tiktokController;

  File? _coverImageFile;
  String? _existingCoverImageUrl;
  bool _initialized = false;
  bool _hasSyncedExistingStore = false;
  bool _isSubmitting = false;
  bool _hasCompletedTutorial = false;

  @override
  void initState() {
    super.initState();
    _branchNameController = TextEditingController(text: 'Principal');
    _phoneController = TextEditingController();
    _descriptionController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initFormData();
      _initialized = true;
    }
  }

  void _initFormData() {
    final stores = ref.read(storesProvider).stores;
    final authState = ref.read(authProvider);
    final company = authState is Authenticated ? authState.user.company : null;
    final Store? existingStore = stores.isNotEmpty ? stores.first : null;

    if (existingStore != null) {
      _hasSyncedExistingStore = true;
      final existingBranch = existingStore.branchName?.trim();
      _branchNameController.text =
          (existingBranch != null && existingBranch.isNotEmpty)
              ? existingBranch
              : 'Principal';
      _phoneController.text = existingStore.phone.isNotEmpty
          ? existingStore.phone
          : (company?.phone ?? '');
      _descriptionController.text = existingStore.description.isNotEmpty
          ? existingStore.description
          : (company?.description ?? '');
      _instagramController.text = existingStore.instagram ?? '';
      _tiktokController.text = existingStore.tiktok ?? '';
      _existingCoverImageUrl = existingStore.coverImage;
    } else {
      _branchNameController.text = 'Principal';
      _phoneController.text = company?.phone ?? '';
      _descriptionController.text = company?.description ?? '';
      _instagramController.text = '';
      _tiktokController.text = '';
      _existingCoverImageUrl = null;
    }
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  String? _sanitizeHandle(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'^@+'), '').trim();
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = Envs.apiBaseUrlImages.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    return '$base/$cleanPath';
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _coverImageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(
        context,
        'No se pudo seleccionar la imagen: $e',
      );
    }
  }

  void _removeCoverImage() {
    setState(() {
      _coverImageFile = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final stores = ref.read(storesProvider).stores;
    final authState = ref.read(authProvider);
    final company = authState is Authenticated ? authState.user.company : null;
    final Store? existingStore = stores.isNotEmpty ? stores.first : null;

    final branchName = _branchNameController.text.trim().isNotEmpty
        ? _branchNameController.text.trim()
        : 'Principal';

    // Para tiendas migradas, aseguramos tomar los datos existentes si el campo no se mostró
    final phone = _phoneController.text.trim().isNotEmpty
        ? _phoneController.text.trim()
        : (existingStore?.phone ?? company?.phone ?? '');
    final description = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : (existingStore?.description ?? company?.description ?? '');

    final instagram = _sanitizeHandle(_instagramController.text) ??
        existingStore?.instagram;
    final tiktok =
        _sanitizeHandle(_tiktokController.text) ?? existingStore?.tiktok;

    bool success = false;

    if (existingStore != null) {
      success = await ref.read(storesProvider.notifier).setupExistingStore(
            storeId: existingStore.id,
            branchName: branchName,
            phone: phone,
            description: description,
            coverImageFile: _coverImageFile,
            instagram: instagram,
            tiktok: tiktok,
          );
    } else {
      success = await ref.read(storesProvider.notifier).createStore(
            branchName: branchName,
            phone: phone,
            description: description,
            coverImageFile: _coverImageFile,
            instagram: instagram,
            tiktok: tiktok,
          );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      NotificationService.showSuccess(
        context,
        '¡Tu sede ha sido configurada con éxito!',
      );
      context.go('/dashboard');
    } else {
      final err = ref.read(storesProvider).errorMessage ??
          'No se pudo completar la configuración. Intenta nuevamente.';
      NotificationService.showError(context, err);
    }
  }

  Future<void> _promptLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar Sesión?'),
        content: const Text(
          'Podrás continuar con la configuración de tu sede cuando vuelvas a iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storesProvider).stores;
    final authState = ref.watch(authProvider);
    final company = authState is Authenticated ? authState.user.company : null;
    final Store? existingStore = stores.isNotEmpty ? stores.first : null;
    final isMigration = existingStore != null;

    // Sincronizar reactivamente si existingStore resolvió después de la inicialización
    if (existingStore != null && !_hasSyncedExistingStore) {
      _hasSyncedExistingStore = true;
      if (_existingCoverImageUrl == null &&
          existingStore.coverImage != null &&
          existingStore.coverImage!.trim().isNotEmpty) {
        _existingCoverImageUrl = existingStore.coverImage;
      }
      final existingBranch = existingStore.branchName?.trim();
      if ((_branchNameController.text.isEmpty ||
              _branchNameController.text == 'Principal') &&
          existingBranch != null &&
          existingBranch.isNotEmpty) {
        _branchNameController.text = existingBranch;
      }
      if (_phoneController.text.isEmpty && existingStore.phone.isNotEmpty) {
        _phoneController.text = existingStore.phone;
      }
      if (_descriptionController.text.isEmpty &&
          existingStore.description.isNotEmpty) {
        _descriptionController.text = existingStore.description;
      }
      if (_instagramController.text.isEmpty &&
          existingStore.instagram != null &&
          existingStore.instagram!.isNotEmpty) {
        _instagramController.text = existingStore.instagram!;
      }
      if (_tiktokController.text.isEmpty &&
          existingStore.tiktok != null &&
          existingStore.tiktok!.isNotEmpty) {
        _tiktokController.text = existingStore.tiktok!;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Evitar que el usuario salga hacia el dashboard sin configurar su sede
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Configuración Necesaria'),
            content: const Text(
              'Para comenzar a utilizar tu panel empresarial debes confirmar o crear tu primera sede. Si deseas continuar después, puedes cerrar sesión.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar aquí'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            !_hasCompletedTutorial
                ? 'Bienvenido a Tu Lojita'
                : (isMigration ? 'Vincula tu Sede' : 'Configura tu Sede'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: _hasCompletedTutorial
              ? IconButton(
                  tooltip: 'Ver tutorial',
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                  onPressed: () => FirstBranchTutorialBottomSheet.show(context),
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Cerrar Sesión',
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedLogout01,
                color: Colors.redAccent,
                size: 22,
              ),
              onPressed: _promptLogout,
            ),
          ],
        ),
        body: SafeArea(
          child: !_hasCompletedTutorial
              ? FirstBranchTutorialCarousel(
                  onComplete: () {
                    setState(() {
                      _hasCompletedTutorial = true;
                    });
                  },
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Differentiated Views: Migration vs New
                        if (isMigration) ...[
                          _buildMigrationExistingStoreCard(
                            existingStore,
                            company?.name,
                          ),
                          const SizedBox(height: 20),
                          _buildBranchNameOnlyCard(),
                        ] else ...[
                          _buildContextualBanner(false, null, company?.name),
                          const SizedBox(height: 20),
                          _buildCoverImageCard(null),
                          const SizedBox(height: 20),
                          _buildFullStoreFormCard(),
                          const SizedBox(height: 20),
                          _buildSocialNetworksCard(),
                        ],

                        const SizedBox(height: 32),

                        // Primary Submit Button
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            disabledBackgroundColor: const Color(0xFFA5B4FC),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isMigration
                                      ? '¡Confirmar Sede y Entrar al Dashboard! 🎉'
                                      : '¡Crear Tienda Principal y Entrar! 🚀',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MIGRATION VIEW: Preview existing store card
  // --------------------------------------------------------------------------
  Widget _buildMigrationExistingStoreCard(
    Store existingStore,
    String? companyName,
  ) {
    final effectiveLogo = existingStore.logo.isNotEmpty
        ? existingStore.logo
        : '';
    final resolvedLogoUrl = _resolveImageUrl(effectiveLogo);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: resolvedLogoUrl.isNotEmpty
                      ? Image.network(
                          resolvedLogoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedStore01,
                              color: Color(0xFF4F46E5),
                              size: 26,
                            ),
                          ),
                        )
                      : const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedStore01,
                            color: Color(0xFF4F46E5),
                            size: 26,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            existingStore.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Activa',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Empresa: ${companyName ?? existingStore.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: Color(0xFF16A34A),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tus productos, teléfono y descripción ya están asociados a esta tienda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MIGRATION VIEW: Branch Name input only
  // --------------------------------------------------------------------------
  Widget _buildBranchNameOnlyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              HugeIcon(
                icon: HugeIcons.strokeRoundedStore01,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Nombre de esta Sede',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Hemos rellenado "Principal" por ti. Tus clientes solo verán el nombre de tu empresa, no verán este sufijo.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _branchNameController,
            decoration: InputDecoration(
              labelText: 'Nombre de la Sucursal *',
              hintText: 'Ej. Principal',
              helperText:
                  'Puedes dejar "Principal" o personalizarlo para tu organización.',
              helperMaxLines: 2,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedStore01,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre de la sucursal es obligatorio';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // NEW STORE VIEW: Contextual Banner
  // --------------------------------------------------------------------------
  Widget _buildContextualBanner(
    bool isMigration,
    Store? existingStore,
    String? companyName,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Configuremos tu primera sucursal!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Tu empresa '),
                      TextSpan(
                        text: companyName ?? 'registrada',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            ' está lista. Ahora vamos a dejar configurada tu sede principal para comenzar a vender.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // NEW STORE VIEW: Full Store Form Card
  // --------------------------------------------------------------------------
  Widget _buildFullStoreFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de la Sede Principal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Branch Name Field
          TextFormField(
            controller: _branchNameController,
            decoration: InputDecoration(
              labelText: 'Nombre de la Sucursal *',
              hintText: 'Ej. Principal',
              helperText:
                  'Pre-llenado como "Principal". Tus clientes solo verán el nombre de tu empresa.',
              helperMaxLines: 2,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedStore01,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre de la sucursal es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono de Contacto *',
              hintText: 'Ej. 04141234567',
              helperText: 'Teléfono para atención a clientes en esta sede.',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono de contacto es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Descripción de la Sucursal *',
              hintText:
                  'Describe brevemente la sede, especialidades o atención...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFile01,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es obligatoria';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // NEW STORE VIEW: Social Networks Card
  // --------------------------------------------------------------------------
  Widget _buildSocialNetworksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Redes Sociales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Opcional',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Conecta tus canales digitales para que tus clientes te descubran y sigan.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Instagram Field
          TextFormField(
            controller: _instagramController,
            decoration: InputDecoration(
              labelText: 'Instagram',
              hintText: '@tu_tienda',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedInstagram,
                  color: Color(0xFFE1306C),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE1306C),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TikTok Field
          TextFormField(
            controller: _tiktokController,
            decoration: InputDecoration(
              labelText: 'TikTok',
              hintText: '@tu_tienda',
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedTiktok,
                  color: Color(0xFF010101),
                  size: 20,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF010101),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // COVER IMAGE CARD
  // --------------------------------------------------------------------------
  Widget _buildCoverImageCard(Store? existingStore) {
    final effectiveRemoteUrl = _coverImageFile == null
        ? (_existingCoverImageUrl ?? existingStore?.coverImage)
        : null;
    final hasLocalImage = _coverImageFile != null;
    final hasRemoteImage = !hasLocalImage &&
        effectiveRemoteUrl != null &&
        effectiveRemoteUrl.trim().isNotEmpty;
    final hasAnyImage = hasLocalImage || hasRemoteImage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 2,
                      children: const [
                        Text(
                          'Foto de Portada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '(Opcional)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Banner visible en la cabecera de tu tienda y directorio.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (hasAnyImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        image: DecorationImage(
                          image: hasLocalImage
                              ? FileImage(_coverImageFile!)
                              : NetworkImage(_resolveImageUrl(effectiveRemoteUrl))
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: _pickCoverImage,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.65),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text(
                            'Cambiar',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (hasLocalImage) ...[
                          const SizedBox(width: 6),
                          IconButton.filled(
                            onPressed: _removeCoverImage,
                            tooltip: 'Descartar imagen seleccionada',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.85),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(8),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '1200 x 400 px (3:1)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCamera01,
                        color: Color(0xFF4F46E5),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Toca para subir banner de cabecera',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Recomendado: 1200 x 400 px (proporción 3:1)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
