import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GeminiPhotoGuidanceBottomSheet extends StatelessWidget {
  static const String promptText =
      'Mejora esta fotografía de producto para catálogo: la imagen final debe ser en formato cuadrado 1:1, '
      'con el artículo perfectamente centrado ocupando aproximadamente el 80% del encuadre, '
      'sobre un fondo blanco puro de estudio (#FFFFFF), con iluminación profesional nítida '
      'y sombras suaves naturales, manteniendo exactamente intactos los colores, '
      'texturas, formas y detalles originales del producto.';

  static const String geminiUrl = 'https://gemini.google.com';

  const GeminiPhotoGuidanceBottomSheet({super.key});

  /// Abre la hoja inferior modal con bordes redondeados y estilo visual coherente.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GeminiPhotoGuidanceBottomSheet(),
    );
  }

  Future<void> _copyPrompt(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: promptText));
    if (context.mounted) {
      NotificationService.showSuccess(
        context,
        '¡Prompt copiado al portapapeles!',
      );
    }
  }

  Future<void> _openGeminiWeb(BuildContext context) async {
    final uri = Uri.parse(geminiUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        NotificationService.showError(
          context,
          'No se pudo abrir el navegador. Entra a $geminiUrl',
        );
      }
    } catch (_) {
      if (context.mounted) {
        NotificationService.showError(
          context,
          'No se pudo abrir el navegador. Entra a $geminiUrl',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabecera con icono, título y botón cerrar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Mejora tus fotos gratis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Usa Google Gemini en la web para obtener fotos de catálogo nítidas y centradas sin costo.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Paso 1: Copiar Prompt
              _buildStepHeader(
                stepNumber: '1',
                title: 'Copia este prompt optimizado',
                subtitle:
                    'Indica a Gemini que encuadre en formato 1:1 cuadrado y aplique fondo blanco de estudio:',
              ),
              const SizedBox(height: 10),

              // Contenedor visual del prompt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      promptText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        key: const Key('gemini_guidance_copy_button'),
                        onPressed: () => _copyPrompt(context),
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text(
                          'Copiar Prompt',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Paso 2: Abrir Gemini Web
              _buildStepHeader(
                stepNumber: '2',
                title: 'Abre Gemini y transforma tu imagen',
                subtitle:
                    'Ingresa gratis con tu cuenta de Google, adjunta la foto de tu producto y pega el prompt copiado.',
              ),
              const SizedBox(height: 12),

              // Botón de redirección externa
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('gemini_guidance_open_web_button'),
                  onPressed: () => _openGeminiWeb(context),
                  icon: const Icon(Icons.open_in_new, size: 17),
                  label: const Text(
                    'Abrir Google Gemini Web',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nota de pie
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Una vez generada la imagen mejorada en Gemini, descárgala a tu galería y añádela como foto principal en Tu Lojita.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF065F46),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader({
    required String stepNumber,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
