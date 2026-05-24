import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/store_settings_notifier.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

class TimezoneSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const TimezoneSettingsScreen({super.key, required this.storeId});

  @override
  ConsumerState<TimezoneSettingsScreen> createState() => _TimezoneSettingsScreenState();
}

class _TimezoneSettingsScreenState extends ConsumerState<TimezoneSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsProvider);
    final notifier = ref.read(storeSettingsProvider.notifier);
    final hasChanges = state.timezone != state.store?.timezone;

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
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Zona Horaria',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Premium Header card with gradient details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4F46E5).withValues(alpha: 0.05),
                            const Color(0xFF6366F1).withValues(alpha: 0.02)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              color: const Color(0xFF4F46E5),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Huso Horario del Comercio',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Define la zona horaria utilizada para el cálculo de estadísticas diarias, límites mensuales y fecha/hora mostrada en tu facturación y reportes.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Selecciona tu zona horaria',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Selector Dropdown Form Field
                    DropdownButtonFormField<String>(
                      initialValue: state.timezone,
                      onChanged: (value) {
                        if (value != null) {
                          notifier.updateTimezone(value);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedGlobe,
                            color: const Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'America/Caracas',
                          child: Text(
                            'Venezuela (UTC-4)',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Save Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (state.isSaving || !hasChanges)
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final success = await notifier.saveSettings(widget.storeId);
                                if (success && mounted) {
                                  navigator.pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          disabledForegroundColor: const Color(0xFF9CA3AF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: state.isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Guardar Configuración',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
                if (state.isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    ),
                  ),
              ],
            ),
    );
  }
}
