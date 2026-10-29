import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_creation_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/widgets/store_location_picker_dialog.dart';

class StoreCreationScreen extends ConsumerStatefulWidget {
  const StoreCreationScreen({super.key});

  @override
  ConsumerState<StoreCreationScreen> createState() => _StoreCreationScreenState();
}

class _StoreCreationScreenState extends ConsumerState<StoreCreationScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepTapped(int step) {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(storeCreationProvider.notifier).setStep(step);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeCreationProvider);
    final notifier = ref.read(storeCreationProvider.notifier);

    // Listen for errors
    ref.listen(storeCreationProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next.isNotEmpty) {
        NotificationService.showError(context, next);
      }
    });

    final hasNoStores = ref.watch(storesProvider).stores.isEmpty;
    final canPop = context.canPop();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            hasNoStores ? 'Registra tu Primera Sucursal' : 'Nueva Sucursal',
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
          leading: canPop
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  onPressed: () => context.pop(),
                )
              : IconButton(
                  tooltip: 'Cerrar Sesión',
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout01,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('¿Cerrar Sesión?'),
                        content: const Text(
                          'Podrás continuar con la creación de tu sucursal cuando vuelvas a iniciar sesión.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/onboarding');
                      }
                    }
                  },
                ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Paso ${state.currentStep + 1} de 2',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Ultra-compact step indicator bar (< 45px)
              _StepProgressBar(
                currentStep: state.currentStep,
                onStepTapped: _onStepTapped,
              ),

              // Scrollable page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1Identity(state: state, notifier: notifier),
                    _Step2Operations(state: state, notifier: notifier),
                  ],
                ),
              ),

              // Bottom wizard action buttons
              _BottomActions(
                state: state,
                onNext: () {
                  FocusScope.of(context).unfocus();
                  if (state.currentStep < 1) {
                    _onStepTapped(state.currentStep + 1);
                  } else {
                    _submitForm(context, ref);
                  }
                },
                onBack: () {
                  FocusScope.of(context).unfocus();
                  if (state.currentStep > 0) {
                    _onStepTapped(state.currentStep - 1);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm(BuildContext context, WidgetRef ref) async {
    final state = ref.read(storeCreationProvider);
    final notifier = ref.read(storeCreationProvider.notifier);
    final authState = ref.read(authProvider);
    final company = authState is Authenticated ? authState.user.company : null;

    notifier.setLoading(true);

    try {
      final success = await ref.read(storesProvider.notifier).createStore(
        branchName: state.branchName.trim(),
        phone: state.phone.trim(),
        description: state.description.trim(),
        subCategoryId: state.subCategoryId ?? company?.subcategoryId,
        latitude: state.latitude,
        longitude: state.longitude,
        timezone: state.timezone,
        coverImageFile: state.coverImageFile,
        address: state.type == StoreType.physical
            ? {
                'street': state.street.trim(),
                'city': state.city.trim(),
                'state': state.addressState.trim(),
              }
            : null,
      );

      if (success) {
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
          NotificationService.showSuccess(context, '¡Sucursal creada con éxito!');
        }
      } else {
        final error = ref.read(storesProvider).errorMessage;
        notifier.setError(error ?? 'No se pudo crear la tienda. Verifica los datos.');
      }
    } catch (e) {
      notifier.setError(e.toString());
    } finally {
      notifier.setLoading(false);
    }
  }
}

// ----------------------------------------------------
// ULTRA-COMPACT STEP PROGRESS BAR (< 45px)
// ----------------------------------------------------
class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTapped;

  const _StepProgressBar({
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildStepItem(0, '1. Identidad', currentStep >= 0, currentStep == 0),
          _buildStepDivider(currentStep >= 1),
          _buildStepItem(1, '2. Operación y Ubicación', currentStep >= 1, currentStep == 1),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, bool isCompletedOrCurrent, bool isCurrent) {
    return GestureDetector(
      onTap: () => onStepTapped(step),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isCompletedOrCurrent
                ? const Color(0xFF4F46E5)
                : Colors.grey.shade300,
            child: Text(
              '${step + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent
                  ? const Color(0xFF4F46E5)
                  : (isCompletedOrCurrent ? const Color(0xFF1E293B) : Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// STEP 1: IDENTITY & STOREFRONT
// ----------------------------------------------------
class _Step1Identity extends ConsumerWidget {
  final StoreCreationState state;
  final StoreCreationNotifier notifier;

  const _Step1Identity({required this.state, required this.notifier});

  Future<void> _pickCoverImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        notifier.setCoverImage(File(picked.path));
      }
    } catch (e) {
      if (context.mounted) {
        NotificationService.showError(context, 'No se pudo cargar la imagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final company = authState is Authenticated ? authState.user.company : null;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // 1. Inherited Company Context (Scrolls with the page!)
        if (company != null) ...[
          _CompanyContextCard(company: company),
          const SizedBox(height: 16),
        ],

        // 2. Cover / Storefront Photo Card (Optional)
        _CoverImagePickerCard(
          coverImageFile: state.coverImageFile,
          onPickImage: () => _pickCoverImage(context),
          onRemoveImage: () => notifier.setCoverImage(null),
        ),
        const SizedBox(height: 16),

        // 3. Store Identity Form Fields Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      icon: HugeIcons.strokeRoundedStore01,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos de la Sucursal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Identifica esta sede de tu empresa',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Branch Name
              TextFormField(
                initialValue: state.branchName,
                onChanged: notifier.updateBranchName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                decoration: PremiumInputDecoration.get(
                  label: 'Nombre de la Sucursal *',
                  hint: 'Ej: Sede Sambil Chacao, Las Mercedes...',
                  icon: HugeIcons.strokeRoundedStore01,
                ),
              ),
              const SizedBox(height: 16),

              // Direct Phone
              TextFormField(
                initialValue: state.phone,
                onChanged: notifier.updatePhone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                decoration: PremiumInputDecoration.get(
                  label: 'Teléfono de contacto *',
                  hint: 'Ej: +58 412 1234567',
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                ),
              ),
              const SizedBox(height: 16),

              // Branch Description
              TextFormField(
                initialValue: state.description,
                onChanged: notifier.updateDescription,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, height: 1.4),
                decoration: PremiumInputDecoration.get(
                  label: 'Descripción o reseña de la sucursal',
                  hint: 'Cuéntale a tus clientes sobre esta sede o punto de venta...',
                  icon: HugeIcons.strokeRoundedNote01,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// INHERITED COMPANY CONTEXT CARD
// ----------------------------------------------------
class _CompanyContextCard extends StatelessWidget {
  final dynamic company;

  const _CompanyContextCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  image: company.logo != null && company.logo.toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage('${Envs.apiBaseUrlImages}${company.logo}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: company.logo == null || company.logo.toString().isEmpty
                    ? const Icon(Icons.business_rounded, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name ?? 'Mi Empresa',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RIF: ${company.rif ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'MATRIZ',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (company.categoryName != null || company.subcategoryName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedTag01,
                    color: Color(0xFF4F46E5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rubro: ${company.categoryName ?? "General"} • ${company.subcategoryName ?? "Comercio"}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// COVER / STOREFRONT IMAGE PICKER CARD
// ----------------------------------------------------
class _CoverImagePickerCard extends StatelessWidget {
  final File? coverImageFile;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const _CoverImagePickerCard({
    required this.coverImageFile,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Foto de Portada / Fachada',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '(Opcional)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Banner de cabecera visible en tu tienda y directorio',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (coverImageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    coverImageFile!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filled(
                          onPressed: onPickImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          onPressed: onRemoveImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        ),
                      ],
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
                        '1200 x 400 px (3:1)',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: onPickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedImageAdd01,
                        color: Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Toca para seleccionar imagen de portada',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Recomendado: 1200 x 400 px (proporción 3:1) en JPG o PNG',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// STEP 2: OPERATIONS & LOCATION
// ----------------------------------------------------
class _Step2Operations extends StatefulWidget {
  final StoreCreationState state;
  final StoreCreationNotifier notifier;

  const _Step2Operations({required this.state, required this.notifier});

  @override
  State<_Step2Operations> createState() => _Step2OperationsState();
}

class _Step2OperationsState extends State<_Step2Operations> {
  bool _isGpsLocating = false;

  Future<void> _handleGpsAutoDetect() async {
    setState(() => _isGpsLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          NotificationService.showWarning(
            context,
            'Por favor activa los servicios de ubicación GPS en tu dispositivo',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            NotificationService.showWarning(context, 'Permiso de ubicación denegado');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          NotificationService.showError(
            context,
            'Permisos de ubicación denegados permanentemente en el sistema',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      widget.notifier.updateCoordinates(position.latitude, position.longitude);

      if (mounted) {
        NotificationService.showSuccess(context, 'Ubicación GPS detectada correctamente');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'No se pudo obtener el GPS: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGpsLocating = false);
      }
    }
  }

  Future<void> _openMapModal() async {
    final result = await StoreLocationPickerDialog.show(
      context,
      initialLatitude: widget.state.latitude,
      initialLongitude: widget.state.longitude,
    );

    if (result != null) {
      widget.notifier.updateCoordinates(result.latitude, result.longitude);
      if (mounted) {
        NotificationService.showSuccess(
          context,
          'Coordenadas actualizadas desde el mapa',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // 1. Operation Mode Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
            children: [
              const Text(
                'Modalidad de Operación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Define cómo atenderá esta sede a tus compradores',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      title: 'Física',
                      description: 'Atención presencial y retiro en local',
                      icon: HugeIcons.strokeRoundedStore01,
                      isSelected: widget.state.type == StoreType.physical,
                      onTap: () => widget.notifier.updateType(StoreType.physical),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      title: 'Virtual',
                      description: 'Solo entregas a domicilio / Dark Kitchen',
                      icon: HugeIcons.strokeRoundedGlobal,
                      isSelected: widget.state.type == StoreType.virtual,
                      onTap: () => widget.notifier.updateType(StoreType.virtual),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Timezone Dropdown Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
            children: [
              const Text(
                'Configuración Regional',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Zona horaria para pedidos, horarios y reportes',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: widget.state.timezone,
                onChanged: (val) {
                  if (val != null) widget.notifier.updateTimezone(val);
                },
                decoration: PremiumInputDecoration.get(
                  label: 'Zona Horaria',
                  hint: 'Selecciona la zona horaria',
                  icon: HugeIcons.strokeRoundedCalendar03,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'America/Caracas',
                    child: Text('Venezuela (Caracas, UTC-4)'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Physical Store Address & Location (Only if physical)
        if (widget.state.type == StoreType.physical) ...[
          const SizedBox(height: 16),

          // Address Fields Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
              children: [
                const Text(
                  'Dirección de la Sede',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Datos legibles de la ubicación para tus clientes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Street
                TextFormField(
                  initialValue: widget.state.street,
                  onChanged: widget.notifier.updateStreet,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: PremiumInputDecoration.get(
                    label: 'Calle / Avenida / Edificio / Local *',
                    hint: 'Ej: Av. Principal de las Mercedes, Local 4...',
                    icon: HugeIcons.strokeRoundedLocation01,
                  ),
                ),
                const SizedBox(height: 16),

                // City & State Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.state.city,
                        onChanged: widget.notifier.updateCity,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        decoration: PremiumInputDecoration.get(
                          label: 'Ciudad *',
                          hint: 'Ej: Caracas',
                          icon: HugeIcons.strokeRoundedCity01,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.state.addressState,
                        onChanged: widget.notifier.updateState,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        decoration: PremiumInputDecoration.get(
                          label: 'Estado *',
                          hint: 'Ej: Miranda',
                          icon: HugeIcons.strokeRoundedLocation01,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Location Modal Trigger Card (Replaces the cramped 300px map!)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        icon: HugeIcons.strokeRoundedMapsLocation01,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Punto Exacto en el Mapa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Necesario para calcular rutas y costos de envío',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Coordinates chip display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: Color(0xFF4F46E5), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coordenadas: ${widget.state.latitude.toStringAsFixed(6)}, ${widget.state.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Map Picker CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openMapModal,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMapsLocation01,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Abrir Mapa Interactivo (Pantalla Completa)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Auto GPS Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _isGpsLocating ? null : _handleGpsAutoDetect,
                    icon: _isGpsLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4F46E5),
                            ),
                          )
                        : const HugeIcon(
                            icon: HugeIcons.strokeRoundedGps01,
                            color: Color(0xFF4F46E5),
                            size: 18,
                          ),
                    label: Text(
                      _isGpsLocating ? 'Obteniendo GPS...' : 'Usar mi ubicación GPS actual',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ----------------------------------------------------
// TYPE CARD SELECTOR WIDGET
// ----------------------------------------------------
class _TypeCard extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(
                    icon: icon,
                    color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade500,
                    size: 22,
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5), size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// PREMIUM INPUT DECORATION
// ----------------------------------------------------
class PremiumInputDecoration {
  static InputDecoration get({
    required String label,
    required String hint,
    required dynamic icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: HugeIcon(icon: icon, color: const Color(0xFF4F46E5), size: 20),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF4F46E5),
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}

// ----------------------------------------------------
// BOTTOM WIZARD ACTION BUTTONS
// ----------------------------------------------------
class _BottomActions extends StatelessWidget {
  final StoreCreationState state;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _BottomActions({
    required this.state,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    bool isNextEnabled = false;
    if (state.currentStep == 0) {
      isNextEnabled = state.branchName.trim().isNotEmpty && state.phone.trim().isNotEmpty;
    } else if (state.currentStep == 1) {
      isNextEnabled = state.type == StoreType.virtual ||
          (state.street.trim().isNotEmpty &&
              state.city.trim().isNotEmpty &&
              state.addressState.trim().isNotEmpty);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.currentStep > 0) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: state.isLoading ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    foregroundColor: const Color(0xFF334155),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Atrás', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (isNextEnabled && !state.isLoading) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Text(
                        state.currentStep == 1 ? 'Crear Sucursal' : 'Siguiente',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
