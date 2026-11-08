import 'dart:typed_data';
import '../entities/store_ai_models.dart';

abstract class StoreAiRepository {
  Future<StoreAiSettings> getSettings(String storeId);

  Future<StoreAiKeyTestResult> testKey(
    String storeId, {
    required String apiKey,
    bool saveIfValid = true,
  });

  Future<StoreAiSettings> updateSettings(
    String storeId, {
    bool? isEnabled,
    int? dailyLimit,
    List<StoreSavedPrompt>? customPrompts,
  });

  Future<StoreAiSettings> deleteKey(String storeId);

  Future<StoreAiCatalog> getCatalog(String storeId);

  Future<AiEnhancedImageResult> enhanceImage(
    String storeId, {
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
    String? presetId,
    String? storePromptId,
    String? customPrompt,
  });
}
