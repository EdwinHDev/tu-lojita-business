import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_details_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/store_settings_notifier.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/stores_notifier.dart';
import '../../domain/entities/store_ai_models.dart';
import '../providers/store_ai_providers.dart';

class StoreAiSettingsScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String? storeDisplayName;

  const StoreAiSettingsScreen({
    super.key,
    required this.storeId,
    this.storeDisplayName,
  });

  @override
  ConsumerState<StoreAiSettingsScreen> createState() =>
      _StoreAiSettingsScreenState();
}

class _StoreAiSettingsScreenState extends ConsumerState<StoreAiSettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _showKeyEditor = false;
  bool _isTestingKey = false;
  bool _isSavingSettings = false;
  StoreAiException? _keyValidationError;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllStoreStates() async {
    ref.invalidate(storeAiSettingsProvider(widget.storeId));
    ref.invalidate(storeAiCatalogProvider(widget.storeId));
    try {
      await ref.read(storesProvider.notifier).loadData();
    } catch (_) {}
    try {
      await ref.read(storeDetailsProvider.notifier).refresh(widget.storeId);
    } catch (_) {}
    try {
      await ref.read(storeSettingsProvider.notifier).loadStore(widget.storeId);
    } catch (_) {}
  }

  Future<void> _openGoogleAiStudio() async {
    final uri = Uri.parse('https://aistudio.google.com/apikey');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      NotificationService.showError(
        context,
        'No se pudo abrir el navegador. Visita aistudio.google.com/apikey',
      );
    }
  }

  Future<void> _testAndSaveKey() async {
    final settingsAsync = ref.read(storeAiSettingsProvider(widget.storeId));
    final globalEnabled = settingsAsync.asData?.value.globalEnabled ?? true;
    if (!globalEnabled) {
      NotificationService.showError(
        context,
        'El sistema de mejora con IA ha sido desactivado temporalmente por la plataforma.',
      );
      return;
    }

    final rawKey = _apiKeyController.text.trim();
    if (rawKey.length < 16) {
      NotificationService.showError(
        context,
        'Pega una API Key válida de Google AI Studio.',
      );
      return;
    }

    setState(() {
      _isTestingKey = true;
      _keyValidationError = null;
    });

    try {
      final repo = ref.read(storeAiRepositoryProvider);
      await repo.testKey(
        widget.storeId,
        apiKey: rawKey,
        saveIfValid: true,
      );

      _apiKeyController.clear();
      await _refreshAllStoreStates();

      if (!mounted) return;
      setState(() {
        _isTestingKey = false;
        _showKeyEditor = false;
      });
      NotificationService.showSuccess(
        context,
        '¡API Key verificada y cifrada para esta sucursal!',
      );
    } on StoreAiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingKey = false;
        _keyValidationError = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTestingKey = false;
        _keyValidationError = StoreAiException(message: e.toString());
      });
    }
  }

  Future<void> _toggleStoreAi(StoreAiSettings current, bool enabled) async {
    if (enabled && !current.globalEnabled) {
      NotificationService.showError(
        context,
        'El sistema de mejora con IA ha sido desactivado temporalmente por la plataforma.',
      );
      return;
    }

    if (!current.hasApiKey && enabled) {
      NotificationService.showError(
        context,
        'Primero debes conectar y validar una API Key de Gemini.',
      );
      return;
    }

    setState(() => _isSavingSettings = true);
    try {
      await ref.read(storeAiRepositoryProvider).updateSettings(
            widget.storeId,
            isEnabled: enabled,
          );
      await _refreshAllStoreStates();
      if (!mounted) return;
      NotificationService.showSuccess(
        context,
        enabled
            ? 'Estudio Fotográfico IA activado en esta sucursal.'
            : 'Estudio Fotográfico IA pausado en esta sucursal.',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  Future<void> _updateDailyLimit(int newLimit) async {
    setState(() => _isSavingSettings = true);
    try {
      await ref.read(storeAiRepositoryProvider).updateSettings(
            widget.storeId,
            dailyLimit: newLimit,
          );
      ref.invalidate(storeAiSettingsProvider(widget.storeId));
      if (!mounted) return;
      NotificationService.showSuccess(
        context,
        'Límite diario actualizado a $newLimit imágenes.',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  Future<void> _confirmDeleteKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Eliminar API Key'),
        content: const Text(
          'Se borrará la credencial cifrada de esta sucursal y el Estudio IA quedará desactivado inmediatamente para ti y tus colaboradores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Llave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSavingSettings = true);
    try {
      await ref.read(storeAiRepositoryProvider).deleteKey(widget.storeId);
      await _refreshAllStoreStates();
      if (!mounted) return;
      setState(() => _showKeyEditor = false);
      NotificationService.showSuccess(
        context,
        'API Key eliminada de esta sucursal.',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  Future<void> _openPromptEditor(
    StoreAiSettings current, {
    StoreSavedPrompt? editing,
  }) async {
    if (editing == null && current.customPrompts.length >= 3) {
      NotificationService.showError(
        context,
        'Puedes guardar hasta un máximo de 3 prompts propios por tienda.',
      );
      return;
    }

    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final promptCtrl = TextEditingController(text: editing?.prompt ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<StoreSavedPrompt>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editing == null
                            ? 'Nuevo Prompt de Tienda'
                            : 'Editar Prompt de Tienda',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Guarda instrucciones frecuentes adaptadas al estilo visual de tu marca.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: 'Nombre corto *',
                      hintText: 'Ej. Fondo Mármol Boutique',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Ingresa un nombre corto'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: promptCtrl,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Instrucción de mejora para la IA *',
                      hintText:
                          'Ej. Centra el producto sobre una superficie de mármol blanco mate con iluminación cálida lateral...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().length < 8
                        ? 'Describe la instrucción con al menos 8 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(
                          ctx,
                          StoreSavedPrompt(
                            id: editing?.id.isNotEmpty == true
                                ? editing!.id
                                : const Uuid().v4(),
                            title: titleCtrl.text.trim(),
                            prompt: promptCtrl.text.trim(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Guardar Prompt',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final updatedList = List<StoreSavedPrompt>.from(current.customPrompts);
    if (editing != null) {
      final idx = updatedList.indexWhere((p) => p.id == editing.id);
      if (idx >= 0) {
        updatedList[idx] = result;
      } else {
        updatedList.add(result);
      }
    } else {
      updatedList.add(result);
    }

    await _saveCustomPrompts(updatedList);
  }

  Future<void> _deleteSavedPrompt(
    StoreAiSettings current,
    StoreSavedPrompt target,
  ) async {
    final updatedList =
        current.customPrompts.where((p) => p.id != target.id).toList();
    await _saveCustomPrompts(updatedList);
  }

  Future<void> _saveCustomPrompts(List<StoreSavedPrompt> prompts) async {
    setState(() => _isSavingSettings = true);
    try {
      await ref.read(storeAiRepositoryProvider).updateSettings(
            widget.storeId,
            customPrompts: prompts,
          );
      ref.invalidate(storeAiSettingsProvider(widget.storeId));
      ref.invalidate(storeAiCatalogProvider(widget.storeId));
      if (!mounted) return;
      NotificationService.showSuccess(
        context,
        'Prompts propios de la sucursal actualizados.',
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState is Authenticated ? authState.user : null;

    if (currentUser == null ||
        currentUser.isCollaborator ||
        (!currentUser.hasCompany && currentUser.company == null)) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Estudio Fotográfico IA',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Esta configuración es exclusiva para el propietario titular de la empresa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    }

    final settingsAsync = ref.watch(storeAiSettingsProvider(widget.storeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estudio Fotográfico IA',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (widget.storeDisplayName != null &&
                widget.storeDisplayName!.isNotEmpty)
              Text(
                widget.storeDisplayName!,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF374151)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(storeAiSettingsProvider(widget.storeId)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) => _buildContent(settings),
      ),
    );
  }

  Widget _buildContent(StoreAiSettings settings) {
    final shouldShowKeyInput = !settings.hasApiKey || _showKeyEditor;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (!settings.globalEnabled) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El servicio global de mejora con IA está temporalmente pausado por la plataforma. Puedes dejar lista tu configuración y se reactivará automáticamente cuando el servicio global esté activo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tarjeta 1: Estado de activación de la sucursal
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF7C3AED),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activar IA en esta Sucursal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings.hasApiKey
                              ? 'Habilita el botón "Mejorar con IA" al subir fotos de artículos o servicios.'
                              : 'Conecta primero tu API Key de Gemini para poder encender este interruptor.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: !settings.globalEnabled
                        ? () => NotificationService.showError(
                              context,
                              'El sistema de mejora con IA ha sido desactivado temporalmente por la plataforma.',
                            )
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: IgnorePointer(
                      ignoring: !settings.globalEnabled,
                      child: Switch.adaptive(
                        value: settings.globalEnabled &&
                            settings.isEnabled &&
                            settings.hasApiKey,
                        activeTrackColor: const Color(0xFF7C3AED),
                        onChanged: (!settings.hasApiKey || _isSavingSettings)
                            ? null
                            : (val) => _toggleStoreAi(settings, val),
                      ),
                    ),
                  ),
                ],
              ),
              if (settings.hasApiKey) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Uso diario de la sucursal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Text(
                            '${settings.usageCountToday} de ${settings.dailyLimit} mejoras hoy',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: [25, 50, 100, 200].contains(settings.dailyLimit)
                          ? settings.dailyLimit
                          : 50,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                      items: const [
                        DropdownMenuItem(value: 25, child: Text('Máx. 25/día')),
                        DropdownMenuItem(value: 50, child: Text('Máx. 50/día')),
                        DropdownMenuItem(
                          value: 100,
                          child: Text('Máx. 100/día'),
                        ),
                        DropdownMenuItem(
                          value: 200,
                          child: Text('Máx. 200/día'),
                        ),
                      ],
                      onChanged: (!settings.globalEnabled || _isSavingSettings)
                          ? null
                          : (val) {
                              if (val != null && val != settings.dailyLimit) {
                                _updateDailyLimit(val);
                              }
                            },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tarjeta 2: Credencial exclusiva de Gemini (BYOK)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'API Key (Google)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: settings.hasApiKey
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      settings.hasApiKey ? 'Cifrada' : 'Sin configurar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: settings.hasApiKey
                            ? const Color(0xFF047857)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu llave se cifra con AES-256-GCM vinculada únicamente a esta sucursal. Ninguna otra tienda ni colaborador puede verla ni extraerla.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 14),

              if (settings.hasApiKey && !_showKeyEditor) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          settings.apiKeyHint ?? 'AIza••••',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: !settings.globalEnabled
                            ? null
                            : () => setState(() {
                                  _showKeyEditor = true;
                                  _keyValidationError = null;
                                }),
                        child: const Text('Reemplazar'),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        tooltip: 'Eliminar API Key',
                        onPressed: (!settings.globalEnabled || _isSavingSettings)
                            ? null
                            : _confirmDeleteKey,
                      ),
                    ],
                  ),
                ),
              ],

              if (shouldShowKeyInput) ...[
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Pega tu API Key de Gemini',
                    hintText: 'AIzaSy...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                if (_keyValidationError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _keyValidationError!.isQuotaOrBilling
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _keyValidationError!.isQuotaOrBilling
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _keyValidationError!.isQuotaOrBilling
                              ? Icons.account_balance_wallet_outlined
                              : Icons.error_outline,
                          size: 18,
                          color: _keyValidationError!.isQuotaOrBilling
                              ? const Color(0xFFB45309)
                              : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _keyValidationError!.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: _keyValidationError!.isQuotaOrBilling
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (settings.hasApiKey) ...[
                      OutlinedButton(
                        onPressed: _isTestingKey
                            ? null
                            : () => setState(() {
                                  _showKeyEditor = false;
                                  _keyValidationError = null;
                                  _apiKeyController.clear();
                                }),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTestingKey ? null : _testAndSaveKey,
                        icon: _isTestingKey
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_outlined, size: 18),
                        label: Text(
                          _isTestingKey
                              ? 'Verificando con Gemini...'
                              : 'Probar y Guardar API Key',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),
              // Guía rápida Google AI Studio
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cómo obtener tu API Key en 3 pasos?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B21B6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '1. Abre Google AI Studio e inicia sesión con tu cuenta Google.\n'
                      '2. Toca "Create API key" y vincula facturación (Tier 1) en tu proyecto para habilitar generación de imágenes.\n'
                      '3. Copia la clave generada y pégala arriba.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _openGoogleAiStudio,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text(
                        'Ir a Google AI Studio (aistudio.google.com)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6D28D9),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tarjeta 3: Hasta 3 Prompts propios guardados de la tienda
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tus prompts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${settings.customPrompts.length} de 3 guardados',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (!settings.globalEnabled ||
                            settings.customPrompts.length >= 3 ||
                            _isSavingSettings)
                        ? null
                        : () => _openPromptEditor(settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(40, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Además de los presets oficiales de Tu Lojita, puedes guardar hasta 3 instrucciones personalizadas para ti y tus colaboradores autorizados.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              if (settings.customPrompts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Aún no has guardado prompts propios en esta sucursal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                )
              else
                ...settings.customPrompts.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.prompt,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF4F46E5),
                          ),
                          onPressed:
                              (!settings.globalEnabled || _isSavingSettings)
                                  ? null
                                  : () => _openPromptEditor(
                                        settings,
                                        editing: item,
                                      ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          onPressed:
                              (!settings.globalEnabled || _isSavingSettings)
                                  ? null
                                  : () => _deleteSavedPrompt(settings, item),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
