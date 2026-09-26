import 'package:tu_lojita_business/core/config/envs.dart';

const Map<String, String> canonicalAchievementSlugs = {
  'primeros pasos': 'first_step',
  'primer paso': 'first_step',
  'vendedor estrella': 'star_seller',
  'centurión del comercio': 'centurion',
  'centurion del comercio': 'centurion',
  'reputación impecable': 'five_stars',
  'reputacion impecable': 'five_stars',
  'paz y salvo': 'no_disputes',
  'perfil dorado': 'gold_profile',
};

/// Resolves remote achievement badge image URLs from relative paths or achievement names.
/// Supports both assets served by the main API server and uploaded badges on the images server.
String resolveAchievementBadgeUrl(String? rawUrl, {String? achievementName}) {
  if (rawUrl != null && rawUrl.trim().isNotEmpty) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/assets/')) {
      final serverBase = Envs.apiBaseUrl.replaceAll('/api/v1', '');
      return '$serverBase$trimmed';
    }
    if (trimmed.startsWith('assets/')) {
      final serverBase = Envs.apiBaseUrl.replaceAll('/api/v1', '');
      return '$serverBase/$trimmed';
    }
    if (trimmed.startsWith('/img/') || trimmed.startsWith('/uploads/')) {
      final cleanBase = Envs.apiBaseUrlImages.replaceAll(RegExp(r'/+$'), '');
      return '$cleanBase$trimmed';
    }
    if (trimmed.startsWith('img/') || trimmed.startsWith('uploads/')) {
      final cleanBase = Envs.apiBaseUrlImages.replaceAll(RegExp(r'/+$'), '');
      return '$cleanBase/$trimmed';
    }
    if (trimmed.endsWith('.png') || trimmed.endsWith('.webp') || trimmed.endsWith('.jpg')) {
      final serverBase = Envs.apiBaseUrl.replaceAll('/api/v1', '');
      return '$serverBase/assets/ranking/achievements/$trimmed';
    }
  }

  // Fallback by achievement name
  if (achievementName != null && achievementName.trim().isNotEmpty) {
    final cleanName = achievementName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'["“"”«»!¡🏆]'), '')
        .trim();
    final slug = canonicalAchievementSlugs[cleanName] ??
        cleanName.replaceAll(RegExp(r'[^a-záéíóúñ0-9]+'), '_');
    final serverBase = Envs.apiBaseUrl.replaceAll('/api/v1', '');
    return '$serverBase/assets/ranking/achievements/$slug.png';
  }

  final serverBase = Envs.apiBaseUrl.replaceAll('/api/v1', '');
  return '$serverBase/assets/ranking/achievements/first_step.png';
}
