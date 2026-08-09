import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/chat/domain/entities/chat_message.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;

  ChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  ChatNotifier(this._orderId);

  final String _orderId;
  StreamSubscription? _chatSub;
  StreamSubscription? _historySub;
  StreamSubscription? _typingSub;
  StreamSubscription? _readSub;
  StreamSubscription? _deliveredSub;
  Timer? _typingTimer;

  void _cancelSubscriptions() {
    _chatSub?.cancel();
    _historySub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _deliveredSub?.cancel();
    _typingTimer?.cancel();
  }

  @override
  ChatState build() {
    _cancelSubscriptions();

    final socketService = ref.read(socketServiceProvider);

    // 1. Escuchar historial
    _historySub = socketService.chatHistoryStream.listen((data) {
      final messages = data.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m))).toList();
      state = state.copyWith(messages: messages, isLoading: false);
    });

    // 2. Escuchar nuevos mensajes
    _chatSub = socketService.chatStream.listen((data) {
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      if (message.orderId == _orderId || message.orderId.isEmpty) {
        final authState = ref.read(authProvider);
        final currentUser = (authState is Authenticated) ? authState.user : null;
        List<ChatMessage> currentMessages = List.from(state.messages);

        if (message.sender.id == currentUser?.id) {
          // Si el mensaje ya existe por su ID real (confirmado por ACK), ignorar duplicado
          if (currentMessages.any((m) => m.id == message.id && !m.id.startsWith('temp-'))) {
            return;
          }
          // Remover el mensaje temporal más antiguo que coincida con el contenido
          final tempIndex = currentMessages.indexWhere(
            (m) => m.id.startsWith('temp-') && m.content == message.content,
          );
          if (tempIndex != -1) {
            currentMessages.removeAt(tempIndex);
          }
        }

        state = state.copyWith(messages: [...currentMessages, message]);
      }
    });

    // 3. Escuchar typing
    _typingSub = socketService.chatTypingStream.listen((data) {
      if (data['orderId'] != _orderId) return;

      if (data['isTyping'] == true) {
        state = state.copyWith(isTyping: true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          state = state.copyWith(isTyping: false);
        });
      } else {
        state = state.copyWith(isTyping: false);
        _typingTimer?.cancel();
      }
    });

    // 4. Escuchar read receipts
    _readSub = socketService.chatMessagesReadStream.listen((data) {
      if (data['orderId'] != _orderId) return;

      final authState = ref.read(authProvider);
      final currentUserId = (authState is Authenticated) ? authState.user.id : '';
      final readBy = data['readBy'] as String?;

      if (readBy == null || readBy == currentUserId) return;

      final updatedMessages = state.messages.map((m) {
        if (!m.isRead && m.sender.id == currentUserId) {
          return m.copyWith(isRead: true, isDelivered: true);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
    });

    // 5. Escuchar delivery receipts
    _deliveredSub = socketService.chatMessagesDeliveredStream.listen((data) {
      if (data['orderId'] != _orderId) return;

      final updatedMessages = state.messages.map((m) {
        if (!m.isDelivered && !m.isRead) {
          return m.copyWith(isDelivered: true);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
    });

    // onDispose se ejecuta al destruir el provider
    ref.onDispose(() {
      _cancelSubscriptions();
      socketService.leaveChat(_orderId);
    });

    return ChatState();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final authState = ref.read(authProvider);
    final currentUser = (authState is Authenticated) ? authState.user : null;
    if (currentUser == null) return;

    // Crear mensaje temporal (sending)
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      id: tempId,
      orderId: _orderId,
      sender: currentUser,
      content: content,
      createdAt: DateTime.now(),
      hasError: false,
    );

    // Añadir a la lista localmente
    state = state.copyWith(messages: [...state.messages, tempMessage]);

    // Enviar con ACK y timeout
    final socketService = ref.read(socketServiceProvider);
    final response = await socketService.sendMessageWithAck(_orderId, content);

    _handleSendMessageResponse(tempId, response);
  }

  void _handleSendMessageResponse(String tempId, Map<String, dynamic> response) {
    final index = state.messages.indexWhere((m) => m.id == tempId);
    if (index == -1) return;

    final currentMsg = state.messages[index];
    final updatedMessages = List<ChatMessage>.from(state.messages);

    if (response['success'] == true && response['messageId'] != null) {
      final realId = response['messageId'] as String;
      final createdAtStr = response['createdAt'] as String?;
      final realCreatedAt = createdAtStr != null 
          ? DateTime.tryParse(createdAtStr) ?? currentMsg.createdAt 
          : currentMsg.createdAt;

      updatedMessages[index] = currentMsg.copyWith(
        id: realId,
        createdAt: realCreatedAt,
        hasError: false,
      );
    } else {
      updatedMessages[index] = currentMsg.copyWith(hasError: true);
    }

    state = state.copyWith(messages: updatedMessages);
  }

  Future<void> retryMessage(String tempId) async {
    final index = state.messages.indexWhere((m) => m.id == tempId);
    if (index == -1) return;

    final message = state.messages[index];
    final updatedMessages = List<ChatMessage>.from(state.messages);
    updatedMessages[index] = message.copyWith(hasError: false);
    state = state.copyWith(messages: updatedMessages);

    final socketService = ref.read(socketServiceProvider);
    final response = await socketService.sendMessageWithAck(_orderId, message.content);

    _handleSendMessageResponse(tempId, response);
  }
}

final chatProvider = NotifierProvider.family<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);
