import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../../domain/entities/store_ai_models.dart';
import '../providers/store_ai_providers.dart';

enum _CompareMode { after, before, split }

class AiImageEnhancerSheet extends ConsumerStatefulWidget {
  final String storeId;
  final Uint8List originalBytes;
  final String fileName;
  final String mimeType;

  const AiImageEnhancerSheet({
    super.key,
    required this.storeId,
    required this.originalBytes,
    required this.fileName,
    required this.mimeType,
  });

  static Future<File?> show(
    BuildContext context, {
    required String storeId,
    required Uint8List originalBytes,
    required String fileName,
    required String mimeType,
  }) {
    return showModalBottomSheet<File?>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AiImageEnhancerSheet(
        storeId: storeId,
        originalBytes: originalBytes,
        fileName: fileName,
        mimeType: mimeType,
      ),
    );
  }

  @override
  ConsumerState<AiImageEnhancerSheet> createState() =>
      _AiImageEnhancerSheetState();
}

class _AiImageEnhancerSheetState extends ConsumerState<AiImageEnhancerSheet> {
  final _customPromptController = TextEditingController();

  String? _selectedPresetId;
  String? _selectedStorePromptId;
  bool _isGenerating = false;
  bool _isSavingTempFile = false;
  StoreAiException? _generationError;
  AiEnhancedImageResult? _enhancedResult;
  int? _latestRemainingQuota;
  _CompareMode _compareMode = _CompareMode.after;

  @override
  void dispose() {
    _customPromptController.dispose();
    super.dispose();
  }

  bool get _hasValidPromptSelection {
    if (_selectedPresetId != null && _selectedPresetId!.isNotEmpty) {
      return true;
    }
    if (_selectedStorePromptId != null && _selectedStorePromptId!.isNotEmpty) {
      return true;
    }
    return _customPromptController.text.trim().length >= 4;
  }

  Future<void> _generateEnhancement() async {
    if (_isGenerating) return;

    final customText = _customPromptController.text.trim();
    if (!_hasValidPromptSelection) {
      NotificationService.showError(
        context,
        'Elige un preset o escribe una instrucción de al menos 4 caracteres.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final repo = ref.read(storeAiRepositoryProvider);
      final result = await repo.enhanceImage(
        widget.storeId,
        imageBytes: widget.originalBytes,
        fileName: widget.fileName,
        mimeType: widget.mimeType,
        presetId: _selectedPresetId,
        storePromptId: _selectedStorePromptId,
        customPrompt: customText.isNotEmpty ? customText : null,
      );

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _enhancedResult = result;
        _latestRemainingQuota = result.remainingDailyQuota;
        _compareMode = _CompareMode.after;
      });
    } on StoreAiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generationError = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generationError = StoreAiException(message: e.toString());
      });
    }
  }

  Future<void> _acceptEnhancedImage() async {
    final result = _enhancedResult;
    if (result == null || _isSavingTempFile) return;

    setState(() => _isSavingTempFile = true);
    try {
      final ext = _extensionForMime(result.mimeType);
      final tempDir = await Directory.systemTemp.createTemp('tulojita_ai_');
      final filePath =
          '${tempDir.path}${Platform.pathSeparator}ai_enhanced_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File(filePath);
      await file.writeAsBytes(result.bytes, flush: true);

      ref.invalidate(storeAiCatalogProvider(widget.storeId));
      ref.invalidate(storeAiSettingsProvider(widget.storeId));

      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingTempFile = false);
      NotificationService.showError(
        context,
        'No se pudo preparar la imagen mejorada: $e',
      );
    }
  }

  String _extensionForMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.contains('jpeg') || lower.contains('jpg')) return 'jpg';
    if (lower.contains('webp')) return 'webp';
    return 'png';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.92;
    final catalogAsync = ref.watch(storeAiCatalogProvider(widget.storeId));

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(catalogAsync.asData?.value),
              const Divider(height: 1),
              Flexible(
                child: catalogAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 56),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                  error: (err, _) => _buildCatalogErrorView(err.toString()),
                  data: (catalog) {
                    if (!catalog.available) {
                      return _buildUnavailableView(catalog);
                    }
                    if (_enhancedResult != null) {
                      return _buildComparisonView(_enhancedResult!);
                    }
                    return _buildPromptSelectionView(catalog);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(StoreAiCatalog? catalog) {
    final remaining = _latestRemainingQuota ?? catalog?.remainingDailyQuota;
    final dailyLimit = catalog?.dailyLimit;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mejorar Fotografía con IA',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                if (remaining != null && dailyLimit != null)
                  Text(
                    'Disponibles hoy en sucursal: $remaining de $dailyLimit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
            onPressed: _isGenerating || _isSavingTempFile
                ? null
                : () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogErrorView(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF374151), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(storeAiCatalogProvider(widget.storeId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableView(StoreAiCatalog catalog) {
    final reason = !catalog.globalEnabled
        ? 'El Estudio Fotográfico IA se encuentra deshabilitado temporalmente a nivel global.'
        : 'Esta sucursal no tiene el Estudio Fotográfico IA activo en este momento.';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF), size: 42),
          const SizedBox(height: 12),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSelectionView(StoreAiCatalog catalog) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Base photo preview + Fidelity notice
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  widget.originalBytes,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: Color(0xFFB45309),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fidelidad del producto: La IA mejorará fondo e iluminación preservando el artículo real. Verifica siempre que coincida con lo que entregarás al cliente.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_generationError != null) ...[
            const SizedBox(height: 14),
            _buildErrorBanner(_generationError!),
          ],

          // 1. Official Presets
          if (catalog.officialPresets.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Estilos Recomendados',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecciona un estilo prediseñado para e-commerce:',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            ...catalog.officialPresets.map((preset) {
              final isSelected = _selectedPresetId == preset.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: _isGenerating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedPresetId = null;
                            } else {
                              _selectedPresetId = preset.id;
                              _selectedStorePromptId = null;
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF5F3FF)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF4C1D95)
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              if (preset.description != null &&
                                  preset.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  preset.description!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          // 2. Store Saved Prompts
          if (catalog.storePrompts.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Prompts de tu Tienda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Instrucciones personalizadas guardadas por la tienda:',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            ...catalog.storePrompts.map((sp) {
              final isSelected = _selectedStorePromptId == sp.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: _isGenerating
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedStorePromptId = null;
                            } else {
                              _selectedStorePromptId = sp.id;
                              _selectedPresetId = null;
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF5F3FF)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sp.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? const Color(0xFF4C1D95)
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sp.prompt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
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
            }),
          ],

          // 3. Free Custom Prompt
          const SizedBox(height: 14),
          Text(
            (_selectedPresetId != null || _selectedStorePromptId != null)
                ? 'Detalle adicional (opcional)'
                : 'Escribe tu propio prompt',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _customPromptController,
            enabled: !_isGenerating,
            maxLines: 3,
            maxLength: 400,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Ej. Centra este artículo, mejora la nitidez y deja un fondo blanco limpio de estudio...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_isGenerating || !_hasValidPromptSelection)
                  ? null
                  : _generateEnhancement,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _isGenerating
                    ? 'Generando mejora con Gemini...'
                    : 'Mejorar con IA',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD8B4FE),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(StoreAiException error) {
    final isQuota = error.isQuotaOrBilling ||
        error.code == 'STORE_DAILY_QUOTA_EXCEEDED' ||
        error.code == 'STORE_RATE_LIMITED';

    final bgColor =
        isQuota ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2);
    final borderColor =
        isQuota ? const Color(0xFFFCD34D) : const Color(0xFFFCA5A5);
    final textColor =
        isQuota ? const Color(0xFF92400E) : const Color(0xFF991B1B);
    final iconColor =
        isQuota ? const Color(0xFFD97706) : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isQuota ? Icons.warning_amber_rounded : Icons.error_outline,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.isQuotaOrBilling
                      ? 'Cuota o facturación requerida en Google AI Studio'
                      : (error.isInvalidKey
                          ? 'API Key de sucursal inválida o revocada'
                          : 'No se pudo generar la mejora'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  error.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView(AiEnhancedImageResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildCompareTab(
                  label: 'Mejorada IA',
                  mode: _CompareMode.after,
                ),
                _buildCompareTab(
                  label: 'Original',
                  mode: _CompareMode.before,
                ),
                _buildCompareTab(
                  label: 'Lado a lado',
                  mode: _CompareMode.split,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preview canvas
          if (_compareMode == _CompareMode.split)
            Row(
              children: [
                Expanded(
                  child: _buildPreviewCard(
                    bytes: widget.originalBytes,
                    badge: 'Antes',
                    badgeColor: const Color(0xFF4B5563),
                    height: 220,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPreviewCard(
                    bytes: result.bytes,
                    badge: 'Después (IA)',
                    badgeColor: const Color(0xFF7C3AED),
                    height: 220,
                  ),
                ),
              ],
            )
          else
            _buildPreviewCard(
              bytes: _compareMode == _CompareMode.after
                  ? result.bytes
                  : widget.originalBytes,
              badge: _compareMode == _CompareMode.after
                  ? 'Resultado con IA'
                  : 'Foto Original',
              badgeColor: _compareMode == _CompareMode.after
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF4B5563),
              height: 290,
            ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta vista previa solo vive en memoria. La imagen original no cambiará hasta que presiones "Usar esta imagen".',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSavingTempFile
                      ? null
                      : () {
                          setState(() {
                            _enhancedResult = null;
                          });
                        },
                  icon: const Icon(Icons.refresh, size: 17),
                  label: const Text('Descartar / Otro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSavingTempFile ? null : _acceptEnhancedImage,
                  icon: _isSavingTempFile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Usar esta imagen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompareTab({
    required String label,
    required _CompareMode mode,
  }) {
    final isSelected = _compareMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _compareMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required Uint8List bytes,
    required String badge,
    required Color badgeColor,
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
