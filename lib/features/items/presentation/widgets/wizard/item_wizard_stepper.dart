import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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

  const ItemWizardStepper({
    super.key,
    required this.currentStep,
    required this.maxVisitedStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                steps[currentStep].title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Paso ${currentStep + 1} de ${steps.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper Items with Connecting Lines
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final leftStepIndex = index ~/ 2;
                final isCompletedLine = leftStepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompletedLine
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE2E8F0),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;
              final isCurrent = stepIndex == currentStep;
              final isAccessible = stepIndex <= maxVisitedStep;

              return InkWell(
                onTap: isAccessible ? () => onStepTapped(stepIndex) : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? const Color(0xFF4F46E5)
                              : isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF1F5F9),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF4F46E5)
                                : isCompleted
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : HugeIcon(
                                  icon: steps[stepIndex].icon,
                                  size: 15,
                                  color: isCurrent
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[stepIndex].shortTitle,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF4F46E5)
                              : isCompleted
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
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
