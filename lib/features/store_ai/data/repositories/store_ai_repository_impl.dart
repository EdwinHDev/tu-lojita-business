import 'dart:typed_data';
import '../../domain/entities/store_ai_models.dart';
import '../../domain/repositories/store_ai_repository.dart';
import '../datasources/store_ai_remote_datasource.dart';

class StoreAiRepositoryImpl implements StoreAiRepository {
  final StoreAiRemoteDataSource _remote;

  StoreAiRepositoryImpl(this._remote);

  @override
  Future<StoreAiSettings> getSettings(String storeId) {
    return _remote.getSettings(storeId);
  }

  @override
  Future<StoreAiKeyTestResult> testKey(
    String storeId, {
    required String apiKey,
    bool saveIfValid = true,
  }) {
    return _remote.testKey(
      storeId,
      apiKey: apiKey,
      saveIfValid: saveIfValid,
    );
  }

  @override
  Future<StoreAiSettings> updateSettings(
    String storeId, {
    bool? isEnabled,
    int? dailyLimit,
    List<StoreSavedPrompt>? customPrompts,
  }) {
    return _remote.updateSettings(
      storeId,
      isEnabled: isEnabled,
      dailyLimit: dailyLimit,
      customPrompts: customPrompts,
    );
  }

  @override
  Future<StoreAiSettings> deleteKey(String storeId) {
    return _remote.deleteKey(storeId);
  }

  @override
  Future<StoreAiCatalog> getCatalog(String storeId) {
    return _remote.getCatalog(storeId);
  }

  @override
  Future<AiEnhancedImageResult> enhanceImage(
    String storeId, {
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
    String? presetId,
    String? storePromptId,
    String? customPrompt,
  }) {
    return _remote.enhanceImage(
      storeId,
      imageBytes: imageBytes,
      fileName: fileName,
      mimeType: mimeType,
      presetId: presetId,
      storePromptId: storePromptId,
      customPrompt: customPrompt,
    );
  }
}
