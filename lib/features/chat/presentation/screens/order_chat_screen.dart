import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/features/chat/domain/entities/chat_message.dart';
import 'package:tu_lojita_business/features/chat/presentation/providers/chat_provider.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/orders_provider.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/core/network/socket_service.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/core/utils/notification_helper.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String userName;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.userName,
  });

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    
    // Unirse a la sala y marcar mensajes como leídos
    _socketService.joinChat(widget.orderId);
    _socketService.markMessagesRead(widget.orderId);
    
    _clearNotifications();
  }

  void _clearNotifications() {
    // Cancelar notificación local del OS (idéntico a lo que pasa en OrderDetailsScreen)
    NotificationHelper.cancelNotification(widget.orderId.hashCode);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationsAsync = ref.read(notificationsProvider);
      if (notificationsAsync.value != null) {
        final unreadForOrder = notificationsAsync.value!.where((n) => 
          !n.isRead && n.targetId == widget.orderId
        ).toList();
        
        if (unreadForOrder.isNotEmpty) {
          final repo = ref.read(notificationRepositoryProvider);
          Future.wait(unreadForOrder.map((n) => repo.markAsRead(n.id))).then((_) {
            if (mounted) {
              ref.invalidate(notificationsProvider);
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider(widget.orderId).notifier).sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.orderId));
    final authState = ref.watch(authProvider);
    final currentUser = (authState is Authenticated) ? authState.user : null;

    // Obtener la orden para verificar si el chat debe ser de solo lectura
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final bool isReadOnly = orderAsync.maybeWhen(
      data: (order) => order.status == 'FULLY_PAID' || order.status == 'CANCELLED',
      orElse: () => false,
    );

    // Auto-scroll al final al recibir nuevos mensajes
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    Widget? readOnlyBanner;
    if (isReadOnly) {
      readOnlyBanner = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFFF1F5F9),
        child: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCircleLock01,
              color: const Color(0xFF64748B),
              size: 16,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Este chat se encuentra en modo solo lectura porque el pedido ha sido completado o cancelado.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF1F2937),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: () {
          final displayName = widget.userName.trim().isEmpty ? 'Cliente' : widget.userName;
          final initialLetter = displayName.substring(0, 1).toUpperCase();
          final orderShortId = widget.orderId.length >= 6
              ? widget.orderId.substring(widget.orderId.length - 6).toUpperCase()
              : widget.orderId.toUpperCase();

          return Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                child: Text(
                  initialLetter,
                  style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/dashboard/orders/${widget.orderId}'),
                    child: Text(
                      'Pedido #$orderShortId',
                      style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ],
          );
        }(),
      ),
      body: Column(
        children: [
          readOnlyBanner ?? const SizedBox.shrink(),
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)))
                : chatState.messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 16, left: 8),
                                child: Text(
                                  'Escribiendo...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = chatState.messages[index];
                          final isMe = message.sender.id == currentUser?.id;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          if (!isReadOnly) _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedChat01,
              color: Color(0xFF9CA3AF),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay mensajes aún',
            style: TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicia la conversación con el cliente',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final timeStr = message.createdAt.toTimeString(use24Hour: true);
    final bool hasError = message.hasError;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: hasError 
            ? () => ref.read(chatProvider(widget.orderId).notifier).retryMessage(message.id)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: hasError 
                ? const Color(0xFFFEF2F2)
                : (isMe ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6)),
            border: hasError ? Border.all(color: const Color(0xFFEF4444), width: 1) : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: hasError 
                      ? const Color(0xFF991B1B)
                      : (isMe ? Colors.white : const Color(0xFF1F2937)),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: hasError 
                          ? const Color(0xFFEF4444)
                          : (isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF9CA3AF)),
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        if (hasError) {
                          return const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedAlertCircle,
                                color: Color(0xFFEF4444),
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Tocar para reintentar',
                                style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        }

                        final isTemp = message.id.startsWith('temp-');
                        final isRead = message.isRead;
                        final isDelivered = message.isDelivered;

                        if (isTemp) {
                          return const HugeIcon(
                            icon: HugeIcons.strokeRoundedTime02,
                            color: Colors.white70,
                            size: 12,
                          );
                        }
                        
                        if (isRead) {
                          return const _WhatsAppTicks(isRead: true);
                        }
                        
                        if (isDelivered) {
                          return const _WhatsAppTicks(isRead: false);
                        }
                        
                        return const HugeIcon(
                          icon: HugeIcons.strokeRoundedTick01,
                          color: Colors.white70,
                          size: 14,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: (text) {
                  _socketService.emitTyping(widget.orderId, text.isNotEmpty);
                },
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedSent,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppTicks extends StatelessWidget {
  final bool isRead;
  const _WhatsAppTicks({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final tickColor = isRead ? Colors.lightBlueAccent : Colors.white70;

    return SizedBox(
      width: 18,
      child: Stack(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedTick01,
            color: tickColor,
            size: 14,
          ),
          Positioned(
            left: 4,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedTick01,
              color: tickColor,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
