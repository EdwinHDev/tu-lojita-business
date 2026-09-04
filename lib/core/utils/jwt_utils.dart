import 'dart:convert';

/// Comprueba si un token JWT de acceso ha caducado o expira en menos de [marginSeconds].
bool isJwtExpired(String? token, {int marginSeconds = 30}) {
  if (token == null || token.isEmpty) return true;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decodedString = utf8.decode(base64Url.decode(normalized));
    final payloadMap = jsonDecode(decodedString);

    if (payloadMap is Map && payloadMap.containsKey('exp')) {
      final exp = payloadMap['exp'] as int;
      final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowInSeconds >= (exp - marginSeconds);
    }
  } catch (_) {
    return true;
  }
  return true;
}
