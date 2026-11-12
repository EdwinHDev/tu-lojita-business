import 'package:tu_lojita_business/core/config/envs.dart';

/// Resolves a relative or absolute dashboard image path into a loadable URL.
String resolveDashboardImageUrl(String? rawPath) {
  if (rawPath == null) return '';
  final trimmed = rawPath.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final cleanBase = Envs.apiBaseUrlImages.replaceAll(RegExp(r'/+$'), '');
  final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '$cleanBase/$cleanPath';
}
