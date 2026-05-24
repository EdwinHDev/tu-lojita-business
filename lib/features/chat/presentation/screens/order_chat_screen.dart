import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import '../../../../features/dashboard/presentation/providers/notifications_provider.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';
import '../../../../core/network/socket_service.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';

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
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _chatSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _readSubscription;
  StreamSubscription? _deliveredSubscription;
  StreamSubscription? _closedSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _socketService.joinChat(widget.orderId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Marcar como leídos los mensajes al abrir el chat (la entrega la gestiona el servidor en join_chat)
      _socketService.markMessagesRead(widget.orderId);

      // Escuchar historial primero
      _socketService.chatHistoryStream.listen((history) {
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(history.cast<Map<String, dynamic>>());
          });
          _scrollToBottom();
        }
      });

      _chatSubscription = _socketService.chatStream.listen((message) {
        if (message['orderId'] == widget.orderId || message['order']?['id'] == widget.orderId) {
          if (mounted) {
            final authState = ref.read(authProvider);
            final currentUser = (authState is Authenticated) ? authState.user : null;
            setState(() {
              // Remover temporal si existe
              if (message['sender']?['id'] == currentUser?.id) {
                _messages.removeWhere((m) => 
                  m['id'].toString().startsWith('temp-') && m['content'] == message['content']
                );
              }
              _messages.add(message);
            });
            _scrollToBottom();
            // Solo marcar como leídos cuando el mensaje es de OTRA persona.
            // El eco de nuestro propio mensaje NO debe disparar mark_messages_read.
            if (message['sender']?['id'] != currentUser?.id) {
              _socketService.markMessagesRead(widget.orderId);
            }
          }
        }
      });

      _typingSubscription = _socketService.chatTypingStream.listen((data) {
        if (data['orderId'] == widget.orderId && mounted) {
          setState(() {
            _isTyping = data['isTyping'];
          });
          _typingTimer?.cancel();
          if (_isTyping) {
            _typingTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) setState(() => _isTyping = false);
            });
          }
        }
      });

      _readSubscription = _socketService.chatMessagesReadStream.listen((data) {
        if (data['orderId'] == widget.orderId && mounted) {
          final authState = ref.read(authProvider);
          final currentUserId = (authState is Authenticated) ? authState.user.id : '';
          final readBy = data['readBy'] as String?;

          // CRÍTICO: solo poner azul cuando EL OTRO leyó mis mensajes.
          // Si readBy == yo, significa que YO abrí el chat y leí los mensajes del otro.
          // Eso NO implica que el otro haya leído los míos → ignorar.
          if (readBy == null || readBy == currentUserId) return;

          setState(() {
            for (var m in _messages) {
              if (m['sender']?['id'] == currentUserId && m['isRead'] != true) {
                m['isRead'] = true;
                m['isDelivered'] = true;
              }
            }
          });
        }
      });

      _deliveredSubscription = _socketService.chatMessagesDeliveredStream.listen((data) {
        if (data['orderId'] == widget.orderId && mounted) {
          setState(() {
            for (var m in _messages) {
              if (m['isRead'] != true) {
                m['isDelivered'] = true;
              }
            }
          });
        }
      });

      _closedSubscription = _socketService.chatClosedStream.listen((data) {
        if (data['orderId'] == widget.orderId && mounted) {
          NotificationService.showError(
            context, 
            'El chat ha sido cerrado porque la orden fue pagada o cancelada.',
          );
          if (context.canPop()) {
            context.pop();
          }
        }
      });

    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _typingSubscription?.cancel();
    _readSubscription?.cancel();
    _deliveredSubscription?.cancel();
    _closedSubscription?.cancel();
    _typingTimer?.cancel();
    _socketService.leaveChat(widget.orderId);
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

    final authState = ref.read(authProvider);
    final currentUser = (authState is Authenticated) ? authState.user : null;
    
    // Optimistic message
    final tempMsg = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'content': text,
      'createdAt': DateTime.now().toIso8601String(),
      'sender': currentUser?.toJson(),
      'orderId': widget.orderId,
    };
    
    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    _socketService.sendMessage(widget.orderId, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              child: Text(
                widget.userName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/dashboard/orders/${widget.orderId}'),
                  child: Text(
                    'Pedido #${widget.orderId.substring(widget.orderId.length - 6).toUpperCase()}',
                    style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 12, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
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
                      final message = _messages[index];
                      final sender = message['sender'];
                      // Si el sender ID es igual al del usuario logueado en la app de negocio
                      final authState = ref.watch(authProvider);
                      final currentUserId = (authState is Authenticated) ? authState.user.id : '';
                      final isMe = sender?['id'] == currentUserId;

                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final timestamp = DateTime.tryParse(message['createdAt'] ?? '') ?? DateTime.now();
    final timeStr = timestamp.toTimeString(use24Hour: true);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF4F46E5) : const Color(0xFFF3F4F6),
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
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1F2937),
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
                    color: isMe ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF9CA3AF),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final isTemp = message['id'].toString().startsWith('temp-');
                      final isRead = message['isRead'] == true;
                      final isDelivered = message['isDelivered'] == true;

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
