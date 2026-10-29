import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_state.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/categories/presentation/widgets/category_selection_bottom_sheet.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/widgets/rif_input_field.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/widgets/logo_crop_dialog.dart';
import 'package:tu_lojita_business/features/subscription/domain/entities/platform_payment_method.dart';
import 'package:tu_lojita_business/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:tu_lojita_business/features/subscription/presentation/widgets/platform_qr_dialog.dart';

class CompanyOnboardingScreen extends ConsumerStatefulWidget {
  const CompanyOnboardingScreen({super.key});

  @override
  ConsumerState<CompanyOnboardingScreen> createState() => _CompanyOnboardingScreenState();
}

class _CompanyOnboardingScreenState extends ConsumerState<CompanyOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Identidad
  final _formKeyStep1 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rifController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _logoFile;
  final _picker = ImagePicker();
  bool _isPickingImage = false;

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryImageUrl;
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;
  String? _selectedSubcategoryImageUrl;

  // Step 2: Membresía & Pago
  final _formKeyStep2 = GlobalKey<FormState>();
  final _refController = TextEditingController();
  PlatformPaymentMethod? _selectedMethod;
  File? _receiptFile;

  // Submission state
  bool _isSubmitting = false;
  String _submittingStatusText = 'Creando empresa...';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // Cargar métodos receptores de la plataforma
      await ref.read(subscriptionProvider.notifier).loadPaymentMethods();

      // Verificar si el usuario ya tenía tienda previa (caso migración)
      await ref.read(companyOnboardingProvider.notifier).checkStatus();
      if (!mounted) return;
      final st = ref.read(companyOnboardingProvider);
      if (st.hasStore && st.detectedSubcategoryId != null) {
        setState(() {
          _selectedSubcategoryId = st.detectedSubcategoryId;
          _selectedSubcategoryName = st.detectedSubcategoryName;
          _selectedCategoryId = st.detectedCategoryId;
          _selectedCategoryName = st.detectedCategoryName;
          if (st.detectedStoreRif != null && _rifController.text.isEmpty) {
            _rifController.text = st.detectedStoreRif!;
          }
          if (st.detectedStoreName != null && _nameController.text.isEmpty) {
            _nameController.text = st.detectedStoreName!;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _rifController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _pickLogo() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        final adjustedFile = await LogoCropDialog.show(context, File(pickedFile.path));
        if (adjustedFile != null && mounted) {
          setState(() {
            _logoFile = adjustedFile;
          });
        }
      }
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _openCategorySelector() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectionBottomSheet(
        initialCategoryId: _selectedCategoryId,
        initialSubcategoryId: _selectedSubcategoryId,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryId = result['categoryId'];
        _selectedCategoryName = result['categoryName'];
        _selectedCategoryImageUrl = result['categoryImageUrl'];
        _selectedSubcategoryId = result['subcategoryId'];
        _selectedSubcategoryName = result['subcategoryName'];
        _selectedSubcategoryImageUrl = result['subcategoryImageUrl'];
      });
    }
  }

  void _validateAndProceedToStep2() {
    FocusScope.of(context).unfocus();
    if (!_formKeyStep1.currentState!.validate()) return;

    final onboardingState = ref.read(companyOnboardingProvider);
    if (_logoFile == null && onboardingState.detectedStoreLogo == null) {
      NotificationService.showWarning(context, 'Por favor, selecciona o sube un logo para tu empresa');
      return;
    }

    if (_selectedSubcategoryId == null) {
      NotificationService.showWarning(
        context,
        'Por favor, selecciona el rubro comercial de tu empresa',
      );
      return;
    }

    _goToStep(1);
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        _receiptFile = File(picked.path);
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    NotificationService.showSuccess(context, '$label copiado al portapapeles');
  }

  void _copyAllPaymentDetails(PlatformPaymentMethod m) {
    final d = m.accountDetails;
    final buffer = StringBuffer();
    buffer.writeln(m.title);

    if (d['bankName'] != null && d['bankName'].toString().trim().isNotEmpty) {
      buffer.writeln('Banco: ${d['bankName'].toString().trim()}');
    }
    if (d['accountHolder'] != null && d['accountHolder'].toString().trim().isNotEmpty) {
      buffer.writeln('Titular: ${d['accountHolder'].toString().trim()}');
    }
    if (d['idNumber'] != null && d['idNumber'].toString().trim().isNotEmpty) {
      buffer.writeln('C.I. / RIF: ${d['idNumber'].toString().trim()}');
    }
    if (d['phoneNumber'] != null && d['phoneNumber'].toString().trim().isNotEmpty) {
      buffer.writeln('Teléfono: ${d['phoneNumber'].toString().trim()}');
    }
    if (d['accountNumber'] != null && d['accountNumber'].toString().trim().isNotEmpty) {
      buffer.writeln('Nº Cuenta: ${d['accountNumber'].toString().trim()}');
    }
    if (d['accountType'] != null && d['accountType'].toString().trim().isNotEmpty) {
      buffer.writeln('Tipo: ${d['accountType'].toString().trim()}');
    }
    if (d['binancePayId'] != null && d['binancePayId'].toString().trim().isNotEmpty) {
      buffer.writeln('Binance Pay ID: ${d['binancePayId'].toString().trim()}');
    }
    if (d['email'] != null && d['email'].toString().trim().isNotEmpty) {
      buffer.writeln('Correo: ${d['email'].toString().trim()}');
    }

    final fullText = buffer.toString().trim();
    Clipboard.setData(ClipboardData(text: fullText));
    NotificationService.showSuccess(
      context,
      'Datos de ${m.title} copiados al portapapeles',
    );
  }

  Future<void> _submitAll() async {
    FocusScope.of(context).unfocus();
    if (!_formKeyStep2.currentState!.validate()) return;

    if (_selectedMethod == null) {
      NotificationService.showWarning(context, 'Selecciona la cuenta bancaria donde transferiste');
      return;
    }

    if (_receiptFile == null) {
      NotificationService.showWarning(context, 'Adjunta la captura o foto del comprobante de pago');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingStatusText = 'Creando empresa y subiendo logo...';
    });

    final ValueNotifier<String> progressStatus = ValueNotifier<String>('Creando empresa y subiendo logo...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ValueListenableBuilder<String>(
              valueListenable: progressStatus,
              builder: (context, statusText, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor espera un momento, estamos configurando tu negocio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Crear empresa
      final companyCreated = await ref.read(companyOnboardingProvider.notifier).createCompany(
            name: _nameController.text.trim(),
            rif: _rifController.text.trim(),
            logoFile: _logoFile,
            subcategoryId: _selectedSubcategoryId,
            phone: _phoneController.text.trim(),
            description: _descriptionController.text.trim(),
          );

      if (!companyCreated) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        final err = ref.read(companyOnboardingProvider).error;
        if (mounted) {
          NotificationService.showError(
            context,
            err ?? 'No se pudo crear la empresa. Verifica los datos.',
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      // 2. Reportar pago de membresía
      progressStatus.value = 'Enviando comprobante de pago...';
      if (mounted) {
        setState(() {
          _submittingStatusText = 'Enviando comprobante de pago...';
        });
      }

      final paymentReported = await ref
          .read(subscriptionProvider.notifier)
          .reportSubscriptionPayment(
            amount: 20.0,
            paymentMethodId: _selectedMethod!.id,
            referenceNumber: _refController.text.trim(),
            receiptFile: _receiptFile!,
          );

      progressStatus.value = 'Sincronizando información...';
      if (mounted) {
        setState(() {
          _submittingStatusText = 'Sincronizando información...';
        });
      }

      // Sincronizar estado de suscripción primero
      await ref.read(subscriptionProvider.notifier).loadSubscriptionAndMethods();
      if (!mounted) return;

      // Cerrar modal de progreso
      Navigator.of(context, rootNavigator: true).pop();

      if (paymentReported) {
        NotificationService.showSuccess(
          context,
          '¡Empresa registrada y pago enviado para verificación!',
        );
        context.go('/subscription/pending');
        ref.read(authProvider.notifier).silentRefresh();
      } else {
        NotificationService.showWarning(
          context,
          'Empresa creada, pero ocurrió un problema al registrar el comprobante. Por favor vuelve a enviarlo.',
        );
        context.go('/subscription/paywall');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        NotificationService.showError(
          context,
          'Ocurrió un error inesperado: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(companyOnboardingProvider);
    final subState = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar errores de onboarding
    ref.listen<CompanyOnboardingState>(companyOnboardingProvider, (previous, next) {
      if (next.error != null && !_isSubmitting) {
        NotificationService.showError(context, next.error!);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Registro de Empresa',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de pasos tipo Wizard
            _StepProgressBar(
              currentStep: _currentStep,
              onStepTapped: (step) {
                if (_isSubmitting) return;
                if (step == 0) {
                  _goToStep(0);
                } else if (step == 1) {
                  _validateAndProceedToStep2();
                }
              },
            ),

            // Contenido en carrusel de páginas
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Paso 1: Identidad
                  _buildStep1Identity(isDark, onboardingState),

                  // Paso 2: Membresía & Activación
                  _buildStep2Membership(isDark, subState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // PASO 1: IDENTIDAD Y RUBRO COMERCIAL
  // ----------------------------------------------------
  Widget _buildStep1Identity(bool isDark, CompanyOnboardingState onboardingState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de bienvenida
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedStore01,
                      color: Color(0xFF4F46E5),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paso 1: Identidad Corporativa',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Registra el nombre, RIF y rubro legal que representarán a todas tus sucursales.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (onboardingState.hasStore) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      color: Colors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hemos detectado tu tienda existente. Su RIF y datos serán sincronizados bajo esta empresa matriz.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.amber.shade200 : Colors.brown.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Selector de Logo Circular Moderno
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4F46E5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        image: _logoFile != null
                            ? DecorationImage(
                                image: FileImage(_logoFile!),
                                fit: BoxFit.cover,
                              )
                            : onboardingState.detectedStoreLogo != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      '${Envs.apiBaseUrlImages}${onboardingState.detectedStoreLogo!}',
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _logoFile == null && onboardingState.detectedStoreLogo == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedCamera01,
                                  color: Color(0xFF4F46E5),
                                  size: 28,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Subir Logo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedEdit02,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Toca el círculo para recortar y ajustar tu logo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Campo Nombre de la Empresa
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Empresa',
                hintText: 'Ej: Inversiones Los Andes, C.A.',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'El nombre de la empresa es obligatorio';
                if (v.trim().length < 3) return 'Debe tener al menos 3 caracteres';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campo RIF
            RifInputField(
              controller: _rifController,
              readOnly: onboardingState.hasStore,
            ),

            const SizedBox(height: 16),

            // Selector Rubro Comercial
            InkWell(
              onTap: _openCategorySelector,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedSubcategoryId != null
                        ? const Color(0xFF4F46E5)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: _selectedSubcategoryId != null ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    _buildRubroIcon(isDark),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rubro Comercial de la Empresa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (_selectedSubcategoryId != null)
                            Text(
                              '${_selectedCategoryName ?? "Categoría"} • ${_selectedSubcategoryName ?? "Subcategoría"}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                              ),
                            )
                          else
                            const Text(
                              'Toca para seleccionar categoría y rubro',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Campo Teléfono de Contacto de la Empresa
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Teléfono de Contacto de la Empresa',
                hintText: 'Ej: +58 412 1234567',
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCall,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El teléfono de contacto es obligatorio';
                }
                if (v.trim().length < 7) {
                  return 'Ingresa un número de teléfono válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            // Campo Descripción de la Empresa
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción de la Empresa',
                hintText: 'Describe la actividad comercial o propuesta de tu empresa...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNote01,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'La descripción de la empresa es obligatoria';
                }
                if (v.trim().length < 10) {
                  return 'Describe tu empresa en al menos 10 caracteres';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Botón Continuar a Membresía
            ElevatedButton(
              onPressed: _validateAndProceedToStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuar a Membresía',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRubroIcon(bool isDark) {
    final rawUrl = _selectedSubcategoryImageUrl?.trim().isNotEmpty == true
        ? _selectedSubcategoryImageUrl!.trim()
        : (_selectedCategoryImageUrl?.trim().isNotEmpty == true
            ? _selectedCategoryImageUrl!.trim()
            : null);

    if (rawUrl != null) {
      final fullUrl = rawUrl.startsWith('http')
          ? rawUrl
          : '${Envs.apiBaseUrlImages}$rawUrl';

      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          fullUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackTagIcon(isDark),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildFallbackTagIcon(isDark);
  }

  Widget _buildFallbackTagIcon(bool isDark) {
    final isSelected = _selectedSubcategoryId != null;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF4F46E5)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedTag01,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF4F46E5)),
          size: 20,
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // PASO 2: MEMBRESÍA Y PAGO
  // ----------------------------------------------------
  Widget _buildStep2Membership(bool isDark, SubscriptionState subState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón superior para volver al paso 1
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _isSubmitting ? null : () => _goToStep(0),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
                label: const Text(
                  'Volver a datos de la empresa',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Card Banner Membresía
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedCrown,
                    color: Colors.amber,
                    size: 38,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Plan Único Empresarial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Activación inicial de tu cuenta comercial',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$20.00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'USD / mes',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Beneficios clave
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beneficios de tu suscripción:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildBenefitRow('Cubre todas tus sucursales y tiendas sin tarifas adicionales.'),
                  _buildBenefitRow('Gestión ilimitada de catálogo, productos y variaciones.'),
                  _buildBenefitRow('Ventas de contado y financiamiento en cuotas automáticas.'),
                  _buildBenefitRow('Canal de chat en vivo y soporte con clientes.'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cuentas receptoras oficiales
            const Text(
              'Cuentas Oficiales para Transferir:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transfiere el equivalente en Bs. (tasa oficial BCV) o vía Binance Pay / USD a:',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            if (subState.paymentMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No hay cuentas disponibles en este momento. Intenta de nuevo en unos instantes.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...subState.paymentMethods.map(
                (m) => _buildPaymentMethodCard(m, isDark),
              ),

            const SizedBox(height: 20),

            // Formulario de reporte de pago
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Reportar Comprobante de Pago',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selector de método
                  DropdownButtonFormField<PlatformPaymentMethod>(
                    initialValue: subState.paymentMethods.any((m) => m.id == _selectedMethod?.id)
                        ? subState.paymentMethods.firstWhere((m) => m.id == _selectedMethod?.id)
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Método Utilizado',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: subState.paymentMethods.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          m.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) {
                            setState(() => _selectedMethod = val);
                          },
                    validator: (val) => val == null ? 'Selecciona la cuenta utilizada' : null,
                  ),

                  const SizedBox(height: 14),

                  // Referencia
                  TextFormField(
                    controller: _refController,
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Número de Referencia',
                      hintText: 'Ej: 04829104',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Ingresa el número de referencia' : null,
                  ),

                  const SizedBox(height: 16),

                  // Comprobante
                  const Text(
                    'Comprobante de Pago (Captura o Foto):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_receiptFile != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _receiptFile!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (!_isSubmitting)
                          IconButton(
                            onPressed: () => setState(() => _receiptFile = null),
                            icon: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 14,
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : () => _pickReceiptImage(ImageSource.camera),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedCamera01,
                              color: Color(0xFF4F46E5),
                              size: 18,
                            ),
                            label: const Text('Cámara'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSubmitting ? null : () => _pickReceiptImage(ImageSource.gallery),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedImage01,
                              color: Color(0xFF4F46E5),
                              size: 18,
                            ),
                            label: const Text('Galería'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // BOTÓN FINALIZAR (UN SOLO LOADER DENTRO DEL BOTÓN)
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.7),
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _submittingStatusText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Finalizar y Activar Empresa (\$20.00 USD)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PlatformPaymentMethod m, bool isDark) {
    final d = m.accountDetails;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                m.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.type,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (d['bankName'] != null)
            _buildCopyField('Banco:', d['bankName'].toString()),
          if (d['accountHolder'] != null)
            _buildCopyField('Titular:', d['accountHolder'].toString()),
          if (d['accountType'] != null)
            _buildCopyField('Tipo:', d['accountType'].toString()),
          if (d['phoneNumber'] != null)
            _buildCopyField('Teléfono:', d['phoneNumber'].toString()),
          if (d['idNumber'] != null)
            _buildCopyField('C.I. / RIF:', d['idNumber'].toString()),
          if (d['accountNumber'] != null)
            _buildCopyField('Nº Cuenta:', d['accountNumber'].toString()),
          if (d['binancePayId'] != null)
            _buildCopyField('Binance Pay ID:', d['binancePayId'].toString()),
          if (d['email'] != null)
            _buildCopyField('Correo:', d['email'].toString()),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InkWell(
                onTap: () => _copyAllPaymentDetails(m),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCopy01,
                        color: Color(0xFF4F46E5),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Copiar todo',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (m.qrImageUrl != null && m.qrImageUrl!.trim().isNotEmpty)
                InkWell(
                  onTap: () => PlatformQrDialog.show(
                    context,
                    qrImageUrl: m.qrImageUrl!,
                    title: m.title,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedQrCode,
                          color: Color(0xFF4F46E5),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ver Código QR para Escanear',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.open_in_full_rounded, size: 14, color: Color(0xFF4F46E5)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(value, label.replaceAll(':', '')),
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCopy01,
                color: Color(0xFF4F46E5),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// INDICADOR DE PASOS DEL WIZARD (UI/UX MODERNA)
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      child: Row(
        children: [
          _buildStepItem(0, '1. Identidad', currentStep >= 0, currentStep == 0),
          _buildStepDivider(currentStep >= 1),
          _buildStepItem(1, '2. Membresía y Pago', currentStep >= 1, currentStep == 1),
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
            radius: 12,
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
                  : (isCompletedOrCurrent ? Colors.grey.shade800 : Colors.grey.shade500),
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
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
