import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tu_lojita_business/features/chat/domain/entities/chat_message.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';

class SupportChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? errorMessage;

  const SupportChatState({
    this.messages = const [],
    this.isLoading = true,
    this.isTyping = false,
    this.errorMessage,
  });

  SupportChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? errorMessage,
  }) {
    return SupportChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SupportChatNotifier extends Notifier<SupportChatState> {
  SupportChatNotifier(this._orderId, [this._channelType = 'DISPUTE_MERCHANT_SUPPORT']);

  final String _orderId;
  final String _channelType;

  StreamSubscription? _messageSub;
  StreamSubscription? _historySub;
  StreamSubscription? _typingSub;
  StreamSubscription? _readSub;
  StreamSubscription? _deliveredSub;
  Timer? _typingTimer;

  void _cancelSubscriptions() {
    _messageSub?.cancel();
    _historySub?.cancel();
    _typingSub?.cancel();
    _readSub?.cancel();
    _deliveredSub?.cancel();
    _typingTimer?.cancel();
  }

  @override
  SupportChatState build() {
    _cancelSubscriptions();

    final socketService = ref.read(socketServiceProvider);

    // Escuchar historial de soporte
    _historySub = socketService.supportChatHistoryStream.listen((data) {
      final orderId = data['orderId'] as String?;
      final channelType = data['channelType'] as String?;
      if (orderId == _orderId && channelType == _channelType) {
        final rawMessages = data['messages'] as List? ?? [];
        final messages = rawMessages
            .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        state = state.copyWith(messages: messages, isLoading: false);
      }
    });

    // Unirse a la sala aislada de mediación
    socketService.joinSupportChat(_orderId, _channelType);
    socketService.markSupportMessagesRead(_orderId, _channelType);

    // Escuchar nuevos mensajes de soporte
    _messageSub = socketService.supportChatMessageStream.listen((data) {
      final message = ChatMessage.fromJson(data);
      final msgChannelType = message.channelType ?? data['channelType'] as String?;

      if (message.orderId == _orderId && msgChannelType == _channelType) {
        final authState = ref.read(authProvider);
        final currentUser = (authState is Authenticated) ? authState.user : null;
        List<ChatMessage> currentMessages = List.from(state.messages);

        if (message.sender.id == currentUser?.id) {
          if (currentMessages.any((m) => m.id == message.id && !m.id.startsWith('temp-'))) {
            return;
          }
          final tempIndex = currentMessages.indexWhere(
            (m) => m.id.startsWith('temp-') && (
              (message.imageUrl != null && m.imageUrl == message.imageUrl) ||
              (m.content == message.content)
            ),
          );
          if (tempIndex != -1) {
            currentMessages.removeAt(tempIndex);
          }
        } else {
          // El comercio tiene la conversación abierta en pantalla -> marcar leído inmediatamente
          socketService.markSupportMessagesRead(_orderId, _channelType);
        }

        state = state.copyWith(
          messages: [...currentMessages, message],
          isLoading: false,
        );
      }
    });

    // Escuchar typing
    _typingSub = socketService.supportTypingStream.listen((data) {
      if (data['orderId'] != _orderId || data['channelType'] != _channelType) return;

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

    // Escuchar read receipts
    _readSub = socketService.supportMessagesReadStream.listen((data) {
      if (data['orderId'] != _orderId || data['channelType'] != _channelType) return;

      final authState = ref.read(authProvider);
      final currentUser = (authState is Authenticated) ? authState.user : null;
      final readBy = data['readBy'] as String?;

      if (readBy == null || readBy == currentUser?.id) return;

      final updatedMessages = state.messages.map((m) {
        if (!m.isRead && m.sender.id == currentUser?.id) {
          return m.copyWith(isRead: true, isDelivered: true);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
    });

    // Escuchar delivery receipts
    _deliveredSub = socketService.supportMessagesDeliveredStream.listen((data) {
      if (data['orderId'] != _orderId || data['channelType'] != _channelType) return;

      final updatedMessages = state.messages.map((m) {
        if (!m.isDelivered && !m.isRead) {
          return m.copyWith(isDelivered: true);
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updatedMessages);
    });

    // Limpieza al desmontar
    ref.onDispose(() {
      _cancelSubscriptions();
      socketService.leaveSupportChat(_orderId, _channelType);
    });

    return const SupportChatState();
  }

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (content.trim().isEmpty && imageUrl == null) return;

    final authState = ref.read(authProvider);
    final currentUser = (authState is Authenticated) ? authState.user : null;
    if (currentUser == null) return;

    final effectiveContent = content.trim().isEmpty
        ? (imageUrl != null ? '📷 Imagen adjunta' : '')
        : content.trim();

    // Crear mensaje temporal (sending)
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      id: tempId,
      orderId: _orderId,
      sender: currentUser,
      content: effectiveContent,
      imageUrl: imageUrl,
      channelType: _channelType,
      createdAt: DateTime.now(),
      hasError: false,
    );

    // Añadir a la lista localmente
    state = state.copyWith(messages: [...state.messages, tempMessage]);

    // Enviar con ACK y timeout
    final socketService = ref.read(socketServiceProvider);
    final response = await socketService.sendSupportMessageWithAck(
      _orderId,
      _channelType,
      effectiveContent,
      imageUrl: imageUrl,
    );

    _handleSendMessageResponse(tempId, response);
  }

  void _handleSendMessageResponse(String tempId, Map<String, dynamic> response) {
    final index = state.messages.indexWhere((m) => m.id == tempId);
    if (index == -1) return;

    final currentMsg = state.messages[index];
    final updatedMessages = List<ChatMessage>.from(state.messages);

    if (response['success'] == true && response['messageId'] != null) {
      final realId = response['messageId'] as String;
      final alreadyExists = updatedMessages.any((m) => m.id == realId);
      if (alreadyExists) {
        updatedMessages.removeAt(index);
      } else {
        final realImageUrl = response['imageUrl'] as String? ?? currentMsg.imageUrl;
        final createdAtStr = response['createdAt'] as String?;
        final realCreatedAt = createdAtStr != null 
            ? DateTime.tryParse(createdAtStr) ?? currentMsg.createdAt 
            : currentMsg.createdAt;

        updatedMessages[index] = currentMsg.copyWith(
          id: realId,
          imageUrl: realImageUrl,
          channelType: _channelType,
          createdAt: realCreatedAt,
          hasError: false,
        );
      }
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
    final response = await socketService.sendSupportMessageWithAck(
      _orderId,
      _channelType,
      message.content,
      imageUrl: message.imageUrl,
    );

    _handleSendMessageResponse(tempId, response);
  }
}

final supportChatProvider = NotifierProvider.family<SupportChatNotifier, SupportChatState, String>(
  SupportChatNotifier.new,
);
