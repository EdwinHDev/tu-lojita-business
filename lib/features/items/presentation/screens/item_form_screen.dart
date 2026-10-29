import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../dashboard/presentation/providers/store_details_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/item.dart';
import '../providers/item_form_provider.dart';
import '../providers/item_list_notifier.dart';
import '../widgets/wizard/item_wizard_bottom_bar.dart';
import '../widgets/wizard/item_wizard_stepper.dart';
import '../widgets/wizard/step_basic_info.dart';
import '../widgets/wizard/step_customizations_and_rules.dart';
import '../widgets/wizard/step_item_preview.dart';
import '../widgets/wizard/step_pricing_and_variants.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final String storeId;
  final Item? item;

  const ItemFormScreen({super.key, required this.storeId, this.item});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _maxVisitedStep = 0;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final user = authState is Authenticated ? authState.user : null;
      if (widget.item == null && user != null && !user.canEditProducts) {
        NotificationService.showWarning(
          context,
          'No tienes permisos requeridos para crear artículos.',
        );
        context.pop(false);
        return;
      }
      if (widget.item != null && user != null && !user.canEditProducts) {
        NotificationService.showWarning(
          context,
          'No tienes permisos requeridos para modificar artículos.',
        );
        context.pop(false);
        return;
      }

      if (widget.item != null) {
        ref.read(itemFormProvider.notifier).initForEditing(widget.item!);
        // In editing mode, allow jumping freely between all steps
        setState(() => _maxVisitedStep = 3);
      }
      ref.read(storeDetailsProvider.notifier).loadData(widget.storeId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    final state = ref.read(itemFormProvider);

    switch (_currentStep) {
      case 0: // Básico & Multimedia
        if (!_step1FormKey.currentState!.validate()) return false;
        if (state.categoryId == null || state.categoryId!.isEmpty) {
          NotificationService.showWarning(
            context,
            'Debes seleccionar una categoría para el artículo.',
          );
          return false;
        }
        return true;

      case 1: // Precios, Variantes & Stock
        if (!_step2FormKey.currentState!.validate()) return false;
        if (state.hasVariants) {
          if (state.variantAxes.isEmpty) {
            NotificationService.showWarning(
              context,
              'Activaste variantes: debes añadir al menos un eje (ej. Talla o Color).',
            );
            return false;
          }
          for (final axis in state.variantAxes) {
            if (axis.values.isEmpty) {
              NotificationService.showWarning(
                context,
                'El eje "${axis.name}" no tiene valores configurados.',
              );
              return false;
            }
          }
        }
        return true;

      case 2: // Personalizaciones & Reglas
        if (!_step3FormKey.currentState!.validate()) return false;
        return true;

      case 3: // Vista Previa
        return true;

      default:
        return true;
    }
  }

  void _onNext() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < 3) {
      final nextStep = _currentStep + 1;
      setState(() {
        _currentStep = nextStep;
        _maxVisitedStep = max(_maxVisitedStep, nextStep);
      });
      _pageController.animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPrevious() {
    if (_currentStep > 0) {
      final prevStep = _currentStep - 1;
      setState(() => _currentStep = prevStep);
      _pageController.animateToPage(
        prevStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop(false);
    }
  }

  void _onStepTapped(int index) {
    if (index > _maxVisitedStep) return;

    // If moving forward, ensure current step is valid
    if (index > _currentStep && !_validateCurrentStep()) return;

    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onSubmit() {
    final authState = ref.read(authProvider);
    final user = authState is Authenticated ? authState.user : null;
    if (user != null && !user.canEditProducts) {
      NotificationService.showWarning(
        context,
        'No tienes permisos para guardar cambios en este artículo.',
      );
      return;
    }
    ref.read(itemFormProvider.notifier).submit(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemFormProvider);

    ref.listen(itemFormProvider, (previous, next) {
      if (next.isSuccess) {
        ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
        ref.read(itemListProvider.notifier).loadInitial(widget.storeId);
        context.pop(true);
        NotificationService.showSuccess(
          context,
          '${state.itemType == ItemType.product ? 'Producto' : 'Servicio'} guardado exitosamente',
        );
      }
      final error = next.errorMessage;
      if (error != null) {
        NotificationService.showError(context, error);
      }
    });

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onPrevious();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            '${widget.item != null ? 'Editar' : 'Nuevo'} ${state.itemType == ItemType.product ? 'Producto' : 'Servicio'}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(false),
          ),
        ),
        body: Column(
          children: [
            // Top Stepper Navigation Header
            ItemWizardStepper(
              currentStep: _currentStep,
              maxVisitedStep: _maxVisitedStep,
              onStepTapped: _onStepTapped,
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Swipable Steps Container (non-scrollable gestures, programmatically controlled)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                    _maxVisitedStep = max(_maxVisitedStep, index);
                  });
                },
                children: [
                  StepBasicInfo(
                    storeId: widget.storeId,
                    formKey: _step1FormKey,
                  ),
                  StepPricingAndVariants(
                    formKey: _step2FormKey,
                  ),
                  StepCustomizationsAndRules(
                    storeId: widget.storeId,
                    formKey: _step3FormKey,
                  ),
                  StepItemPreview(
                    storeId: widget.storeId,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: ItemWizardBottomBar(
          currentStep: _currentStep,
          totalSteps: 4,
          isLoading: state.isLoading,
          isEditing: widget.item != null,
          onPrevious: _onPrevious,
          onNext: _onNext,
          onSubmit: _onSubmit,
        ),
      ),
    );
  }
}
