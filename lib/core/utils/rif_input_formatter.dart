import 'package:flutter/services.dart';

/// Formateador de texto para el Registro de Información Fiscal (RIF) venezolano.
///
/// Formatea la entrada del usuario en tiempo real en la estructura:
/// `[V/E/J/G/C/P]-[0-9]{8}-[0-9]` (ej. `J-12345678-9`).
class RifTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Permitir borrar sin interferir con la lógica de auto-formateo
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Remover todos los caracteres no alfanuméricos
    final cleanText = text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    
    // Primer carácter: Debe ser V, E, J, G, C, P
    final firstChar = cleanText[0].toUpperCase();
    const allowedLetters = ['V', 'E', 'J', 'G', 'C', 'P'];
    if (!allowedLetters.contains(firstChar)) {
      return oldValue; // Rechazar si no empieza con una letra de RIF válida
    }
    buffer.write(firstChar);

    // Si hay más caracteres, agregar el guion e iterar
    if (cleanText.length > 1) {
      buffer.write('-');
      
      // Agregar hasta 8 dígitos
      int digitCount = 0;
      int i = 1;
      for (; i < cleanText.length && digitCount < 8; i++) {
        final char = cleanText[i];
        if (int.tryParse(char) != null) {
          buffer.write(char);
          digitCount++;
        } else {
          return oldValue; // Rechazar cualquier carácter no numérico en esta sección
        }
      }

      // Si tenemos los 8 dígitos y hay más caracteres, agregar el segundo guion
      if (digitCount == 8 && i < cleanText.length) {
        buffer.write('-');
        
        // Agregar el dígito verificador
        final lastChar = cleanText[i];
        if (int.tryParse(lastChar) != null) {
          buffer.write(lastChar);
        } else {
          return oldValue; // Rechazar si el último carácter no es un número
        }
      } else if (i < cleanText.length) {
        return oldValue; // Evitar caracteres adicionales si aún no se completan los 8 dígitos
      }
    } else {
      // Si solo se ingresó la letra inicial, auto-completar el guion para guiar al usuario
      buffer.write('-');
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
