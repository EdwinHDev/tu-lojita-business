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
import '../widgets/promote_item_sheet.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final String storeId;
  final Item? item;
  final Item? duplicateFrom;

  const ItemFormScreen({
    super.key,
    required this.storeId,
    this.item,
    this.duplicateFrom,
  });

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
      } else if (widget.duplicateFrom != null) {
        ref.read(itemFormProvider.notifier).initForDuplicating(widget.duplicateFrom!);
        // Prefilled duplicate allows jumping between steps right away
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

  Future<void> _showPromotionUpsellDialog(BuildContext context, Item createdItem) async {
    final shouldPromote = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¡Artículo publicado!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu ${createdItem.itemType == ItemType.product ? 'producto' : 'servicio'} "${createdItem.title}" ya está activo en tu tienda.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Color(0xFFD97706), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Deseas promocionarlo en el Home de Tu Lojita para multiplicar sus visitas y ventas?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Promocionar ⭐', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted || !context.mounted) return;

    if (shouldPromote == true && context.mounted) {
      await PromoteItemSheet.show(context, createdItem, widget.storeId);
    }

    if (mounted && context.mounted) {
      context.pop(true);
      NotificationService.showSuccess(
        context,
        'Artículo guardado exitosamente',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemFormProvider);

    ref.listen(itemFormProvider, (previous, next) {
      if (next.isSuccess) {
        ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
        ref.read(itemListProvider.notifier).loadInitial(widget.storeId);

        final newlyCreatedItem = next.createdItem;
        if (widget.item == null && newlyCreatedItem != null) {
          _showPromotionUpsellDialog(context, newlyCreatedItem);
        } else {
          context.pop(true);
          NotificationService.showSuccess(
            context,
            '${state.itemType == ItemType.product ? 'Producto' : 'Servicio'} guardado exitosamente',
          );
        }
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
            '${widget.item != null ? 'Editar' : (widget.duplicateFrom != null ? 'Duplicar' : 'Nuevo')} ${state.itemType == ItemType.product ? 'Producto' : 'Servicio'}',
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
