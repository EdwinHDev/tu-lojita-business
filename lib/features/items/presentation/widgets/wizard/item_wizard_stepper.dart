import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/features/items/domain/entities/item.dart';

class WizardStepInfo {
  final String title;
  final String shortTitle;
  final dynamic icon;

  const WizardStepInfo({
    required this.title,
    required this.shortTitle,
    required this.icon,
  });
}

class ItemWizardStepper extends StatelessWidget {
  final int currentStep;
  final int maxVisitedStep;
  final ValueChanged<int> onStepTapped;
  final ItemType itemType;

  static const List<WizardStepInfo> steps = [
    WizardStepInfo(
      title: 'Información Básica',
      shortTitle: 'Básico',
      icon: HugeIcons.strokeRoundedNote01,
    ),
    WizardStepInfo(
      title: 'Precios & Stock',
      shortTitle: 'Precios',
      icon: HugeIcons.strokeRoundedTag01,
    ),
    WizardStepInfo(
      title: 'Personalización',
      shortTitle: 'Opciones',
      icon: HugeIcons.strokeRoundedSlidersHorizontal,
    ),
    WizardStepInfo(
      title: 'Vista Previa',
      shortTitle: 'Preview',
      icon: HugeIcons.strokeRoundedEye,
    ),
  ];

  static List<WizardStepInfo> stepsForType(ItemType itemType) {
    final isService = itemType == ItemType.service;
    return [
      const WizardStepInfo(
        title: 'Información Básica',
        shortTitle: 'Básico',
        icon: HugeIcons.strokeRoundedNote01,
      ),
      WizardStepInfo(
        title: isService ? 'Precios & Variantes' : 'Precios & Stock',
        shortTitle: 'Precios',
        icon: HugeIcons.strokeRoundedTag01,
      ),
      WizardStepInfo(
        title: isService ? 'Agenda & Reglas' : 'Personalización',
        shortTitle: isService ? 'Agenda' : 'Opciones',
        icon: isService
            ? HugeIcons.strokeRoundedCalendar03
            : HugeIcons.strokeRoundedSlidersHorizontal,
      ),
      const WizardStepInfo(
        title: 'Vista Previa',
        shortTitle: 'Preview',
        icon: HugeIcons.strokeRoundedEye,
      ),
    ];
  }

  const ItemWizardStepper({
    super.key,
    required this.currentStep,
    required this.maxVisitedStep,
    required this.onStepTapped,
    this.itemType = ItemType.product,
  });

  @override
  Widget build(BuildContext context) {
    final activeSteps = stepsForType(itemType);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Counter & Current Step Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activeSteps[currentStep].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Paso ${currentStep + 1} de ${activeSteps.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TuLojitaBrandColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper Items with Connecting Lines
          Row(
            children: List.generate(activeSteps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final leftStepIndex = index ~/ 2;
                final isCompletedLine = leftStepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompletedLine
                        ? TuLojitaBrandColors.primary
                        : TuLojitaBrandColors.borderMuted,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;
              final isCurrent = stepIndex == currentStep;
              final isAccessible = stepIndex <= maxVisitedStep;

              return Flexible(
                child: InkWell(
                  key: Key('wizard_step_tab_$stepIndex'),
                  onTap: isAccessible ? () => onStepTapped(stepIndex) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? TuLojitaBrandColors.primary
                                : isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isCurrent
                                  ? TuLojitaBrandColors.primary
                                  : isCompleted
                                      ? const Color(0xFF10B981)
                                      : isAccessible
                                          ? TuLojitaBrandColors.indigo500
                                          : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: TuLojitaBrandColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : HugeIcon(
                                    icon: activeSteps[stepIndex].icon,
                                    size: 14,
                                    color: isCurrent
                                        ? Colors.white
                                        : isAccessible
                                            ? TuLojitaBrandColors.primary
                                            : const Color(0xFF94A3B8),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeSteps[stepIndex].shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent
                                ? TuLojitaBrandColors.primary
                                : isCompleted || isAccessible
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
