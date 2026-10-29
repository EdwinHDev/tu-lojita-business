import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'item_wizard_stepper.dart';

class ItemWizardBottomBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const ItemWizardBottomBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
    required this.isLoading,
    this.isEditing = false,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;
    final nextStepName = currentStep < totalSteps - 1
        ? ItemWizardStepper.steps[currentStep + 1].shortTitle
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Secondary / Back Button
              if (currentStep == 0)
                OutlinedButton(
                  onPressed: isLoading ? null : onPrevious,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onPrevious,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text(
                    'Atrás',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              const SizedBox(width: 12),

              // Primary Action (Next or Submit)
              Expanded(
                child: isLastStep
                    ? ElevatedButton.icon(
                        onPressed: isLoading ? null : onSubmit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                color: Colors.white,
                                size: 18,
                              ),
                        label: Text(
                          isLoading
                              ? 'PROCESANDO...'
                              : (isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR ARTÍCULO'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isLoading ? null : onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Siguiente: $nextStepName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
