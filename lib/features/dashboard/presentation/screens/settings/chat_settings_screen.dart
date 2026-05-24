import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_settings_notifier.dart';
import '../../providers/store_settings_state.dart';
import 'widgets/settings_widgets.dart';

class ChatSettingsScreen extends ConsumerWidget {
  final String storeId;
  const ChatSettingsScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Configuración de Chat',
          style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsSectionTitle(title: 'Chat de Órdenes'),
            const SizedBox(height: 16),
            _buildChatToggle(ref, state),
            const SizedBox(height: 40),
            _buildSaveButton(ref, state, storeId),
          ],
        ),
      ),
    );
  }

  Widget _buildChatToggle(WidgetRef ref, StoreSettingsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habilitar chat de órdenes',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                Text(
                  'Permite a los clientes contactarte por cada orden',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: state.allowChat,
            activeTrackColor: const Color(0xFF10B981),
            onChanged: (val) => ref.read(storeSettingsProvider.notifier).updateAllowChat(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(WidgetRef ref, StoreSettingsState state, String storeId) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: state.isSaving
            ? null
            : () => ref.read(storeSettingsProvider.notifier).saveSettings(
                  storeId,
                  specificData: {'allowChat': state.allowChat},
                ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: state.isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Guardar Cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
