import 'dart:convert';
import 'dart:typed_data';

class StoreSavedPrompt {
  final String id;
  final String title;
  final String prompt;

  const StoreSavedPrompt({
    required this.id,
    required this.title,
    required this.prompt,
  });

  factory StoreSavedPrompt.fromJson(Map<String, dynamic> json) {
    return StoreSavedPrompt(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      prompt: json['prompt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'prompt': prompt,
    };
  }

  StoreSavedPrompt copyWith({
    String? id,
    String? title,
    String? prompt,
  }) {
    return StoreSavedPrompt(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
    );
  }
}

class OfficialAiPreset {
  final String id;
  final String title;
  final String? description;
  final String prompt;

  const OfficialAiPreset({
    required this.id,
    required this.title,
    this.description,
    required this.prompt,
  });

  factory OfficialAiPreset.fromJson(Map<String, dynamic> json) {
    return OfficialAiPreset(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      prompt: json['prompt']?.toString() ?? '',
    );
  }
}

class StoreAiSettings {
  final String storeId;
  final bool globalEnabled;
  final String activeModel;
  final bool isEnabled;
  final bool hasApiKey;
  final String? apiKeyHint;
  final List<StoreSavedPrompt> customPrompts;
  final int dailyLimit;
  final int usageCountToday;
  final int remainingDailyQuota;

  const StoreAiSettings({
    required this.storeId,
    this.globalEnabled = true,
    this.activeModel = 'gemini-2.5-flash-image',
    this.isEnabled = false,
    this.hasApiKey = false,
    this.apiKeyHint,
    this.customPrompts = const [],
    this.dailyLimit = 50,
    this.usageCountToday = 0,
    this.remainingDailyQuota = 50,
  });

  factory StoreAiSettings.fromJson(Map<String, dynamic> json) {
    final promptsRaw = json['customPrompts'];
    final parsedPrompts = promptsRaw is List
        ? promptsRaw
            .whereType<Map>()
            .map((e) => StoreSavedPrompt.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <StoreSavedPrompt>[];

    return StoreAiSettings(
      storeId: json['storeId']?.toString() ?? '',
      globalEnabled: json['globalEnabled'] != false,
      activeModel: json['activeModel']?.toString() ?? 'gemini-2.5-flash-image',
      isEnabled: json['isEnabled'] == true,
      hasApiKey: json['hasApiKey'] == true,
      apiKeyHint: json['apiKeyHint']?.toString(),
      customPrompts: parsedPrompts,
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 50,
      usageCountToday: (json['usageCountToday'] as num?)?.toInt() ?? 0,
      remainingDailyQuota: (json['remainingDailyQuota'] as num?)?.toInt() ?? 50,
    );
  }
}

class StoreAiKeyTestResult {
  final bool valid;
  final bool saved;
  final String apiKeyHint;
  final StoreAiSettings? settings;

  const StoreAiKeyTestResult({
    required this.valid,
    required this.saved,
    required this.apiKeyHint,
    this.settings,
  });

  factory StoreAiKeyTestResult.fromJson(Map<String, dynamic> json) {
    return StoreAiKeyTestResult(
      valid: json['valid'] == true,
      saved: json['saved'] == true,
      apiKeyHint: json['apiKeyHint']?.toString() ?? '',
      settings: json['settings'] is Map
          ? StoreAiSettings.fromJson(
              Map<String, dynamic>.from(json['settings'] as Map),
            )
          : null,
    );
  }
}

class StoreAiCatalog {
  final String storeId;
  final bool available;
  final bool globalEnabled;
  final bool storeEnabled;
  final List<OfficialAiPreset> officialPresets;
  final List<StoreSavedPrompt> storePrompts;
  final int dailyLimit;
  final int remainingDailyQuota;

  const StoreAiCatalog({
    required this.storeId,
    this.available = false,
    this.globalEnabled = true,
    this.storeEnabled = false,
    this.officialPresets = const [],
    this.storePrompts = const [],
    this.dailyLimit = 50,
    this.remainingDailyQuota = 50,
  });

  factory StoreAiCatalog.fromJson(Map<String, dynamic> json) {
    final officialRaw = json['officialPresets'];
    final storeRaw = json['storePrompts'];

    return StoreAiCatalog(
      storeId: json['storeId']?.toString() ?? '',
      available: json['available'] == true,
      globalEnabled: json['globalEnabled'] != false,
      storeEnabled: json['storeEnabled'] == true,
      officialPresets: officialRaw is List
          ? officialRaw
              .whereType<Map>()
              .map(
                (e) => OfficialAiPreset.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
      storePrompts: storeRaw is List
          ? storeRaw
              .whereType<Map>()
              .map(
                (e) => StoreSavedPrompt.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 50,
      remainingDailyQuota: (json['remainingDailyQuota'] as num?)?.toInt() ?? 50,
    );
  }
}

class AiEnhancedImageResult {
  final String mimeType;
  final String imageBase64;
  final Uint8List bytes;
  final int remainingDailyQuota;

  const AiEnhancedImageResult({
    required this.mimeType,
    required this.imageBase64,
    required this.bytes,
    required this.remainingDailyQuota,
  });

  factory AiEnhancedImageResult.fromJson(Map<String, dynamic> json) {
    final b64 = json['imageBase64']?.toString() ?? '';
    return AiEnhancedImageResult(
      mimeType: json['mimeType']?.toString() ?? 'image/png',
      imageBase64: b64,
      bytes: base64Decode(b64),
      remainingDailyQuota: (json['remainingDailyQuota'] as num?)?.toInt() ?? 0,
    );
  }
}

class StoreAiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const StoreAiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  bool get isInvalidKey => code == 'INVALID_API_KEY';
  bool get isQuotaOrBilling => code == 'QUOTA_OR_BILLING_REQUIRED';

  @override
  String toString() => message;
}
