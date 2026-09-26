import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/features/chat/domain/entities/chat_message.dart';
import 'package:tu_lojita_business/features/chat/presentation/providers/chat_provider.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/orders_provider.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/core/network/socket_service.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/core/utils/notification_helper.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/chat/presentation/widgets/chat_image_preview_dialog.dart';
import 'package:tu_lojita_business/features/reports/presentation/widgets/report_dialog.dart';

String _formatChatImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final baseUrl = Envs.apiBaseUrlImages;
  if (trimmed.startsWith('/')) {
    return '$baseUrl$trimmed';
  }
  return '$baseUrl/$trimmed';
}

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
  final FocusNode _focusNode = FocusNode();
  late SocketService _socketService;
  bool _isUploadingImage = false;

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
    _focusNode.dispose();
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
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploadingImage) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      final imageFile = File(picked.path);

      if (!mounted) return;
      final caption = await ChatImagePreviewDialog.show(
        context,
        imageFile: imageFile,
        initialCaption: _messageController.text.trim(),
      );

      if (caption == null) return;

      setState(() => _isUploadingImage = true);

      final imageDataSource = ref.read(imageRemoteDataSourceProvider);
      final uploadedUrl = await imageDataSource.uploadImage(imageFile);

      await ref.read(chatProvider(widget.orderId).notifier).sendMessage(
        caption,
        imageUrl: uploadedUrl,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Error al subir imagen: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enviar Imagen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.camera);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCamera01,
                            size: 32,
                            color: Color(0xFF4F46E5),
                          ),
                          SizedBox(height: 8),
                          Text('Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            size: 32,
                            color: Color(0xFF4F46E5),
                          ),
                          SizedBox(height: 8),
                          Text('Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.orderId));
    final authState = ref.watch(authProvider);
    final currentUser = (authState is Authenticated) ? authState.user : null;

    // Obtener la orden para verificar si el chat debe ser de solo lectura
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final bool isReadOnly = chatState.isClosed || orderAsync.maybeWhen(
      data: (order) => order.status == 'FULLY_PAID' || order.status == 'CANCELLED',
      orElse: () => false,
    );

    // Auto-scroll al final al recibir nuevos mensajes
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

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
          final orderShortId = widget.orderId.length >= 8
              ? widget.orderId.substring(0, 8).toUpperCase()
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
          if (isReadOnly) _ChatStatusBanner(chatState: chatState),
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
    final bool hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: hasError 
            ? () => ref.read(chatProvider(widget.orderId).notifier).retryMessage(message.id)
            : null,
        onLongPress: () => _showMessageActions(context, message, isMe),
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
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                Builder(
                  builder: (context) {
                    final formattedUrl = _formatChatImageUrl(message.imageUrl);
                    return GestureDetector(
                      onTap: () {
                        if (formattedUrl.isEmpty) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(12),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                InteractiveViewer(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      formattedUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        padding: const EdgeInsets.all(32),
                                        color: Colors.black54,
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.broken_image_rounded, color: Colors.white70, size: 48),
                                            SizedBox(height: 8),
                                            Text(
                                              'No se pudo cargar la imagen',
                                              style: TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: formattedUrl.isNotEmpty
                            ? Image.network(
                                formattedUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 180,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 180,
                                    color: Colors.black12,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 120,
                                  color: Colors.black12,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                  ),
                                ),
                              )
                            : Container(
                                height: 120,
                                color: Colors.black12,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                ),
                              ),
                      ),
                    );
                  },
                ),
                if (message.content.isNotEmpty && message.content != '📷 Imagen adjunta')
                  const SizedBox(height: 6),
              ],
              if (message.content.isNotEmpty && message.content != '📷 Imagen adjunta')
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
        left: 12,
        right: 16,
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
          IconButton(
            icon: _isUploadingImage
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                  )
                : const HugeIcon(
                    icon: HugeIcons.strokeRoundedAttachment01,
                    color: Color(0xFF64748B),
                    size: 24,
                  ),
            onPressed: _isUploadingImage ? null : _showImageSourcePicker,
            tooltip: 'Adjuntar imagen',
          ),
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
                focusNode: _focusNode,
                enabled: !_isUploadingImage,
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isUploadingImage ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isUploadingImage ? Colors.grey : const Color(0xFF4F46E5),
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

  void _showMessageActions(BuildContext context, ChatMessage message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (message.content.isNotEmpty && message.content != '📷 Imagen adjunta')
              ListTile(
                leading:
                    const Icon(Icons.copy_rounded, color: Color(0xFF374151)),
                title: const Text('Copiar texto'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: message.content));
                  NotificationService.showSuccess(context, 'Mensaje copiado');
                },
              ),
            if (!isMe)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: const Text(
                  'Reportar mensaje',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => ReportDialog(
                      title: 'Reportar mensaje',
                      reportType: 'CHAT_MESSAGE',
                      targetChatMessageId: message.id,
                      messageContent: message.content.isNotEmpty
                          ? message.content
                          : (message.imageUrl != null ? '📷 Imagen adjunta' : ''),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
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

class _ChatStatusBanner extends StatelessWidget {
  final ChatState chatState;

  const _ChatStatusBanner({required this.chatState});

  @override
  Widget build(BuildContext context) {
    if (chatState.closedReason == 'USER_CHAT_SUSPENDED') {
      String durationText = 'Aviso administrativo';
      if (chatState.isPermanent == true) {
        durationText = 'Suspensión Definitiva';
      } else if (chatState.suspendedUntil != null) {
        final parsed = DateTime.tryParse(chatState.suspendedUntil!);
        durationText = 'Hasta ${parsed != null ? parsed.toFriendlyDate() : chatState.suspendedUntil}';
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gavel_rounded, size: 20, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Acceso al chat suspendido',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chatState.isPermanent == true ? 'Definitiva' : 'Penalización',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sanción: $durationText',
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (chatState.suspensionReason != null && chatState.suspensionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Motivo: ${chatState.suspensionReason}',
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 12,
                ),
              ),
            ],
            if (chatState.suspensionEvidence != null && chatState.suspensionEvidence!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Evidencia citada por moderación:',
                style: TextStyle(
                  color: Color(0xFF7F1D1D),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...chatState.suspensionEvidence!.map((quote) {
                final isGap = quote.contains('Se omitieron mensajes intermedios') ||
                    quote.trim() == '[ ··· Se omitieron mensajes intermedios ··· ]';

                if (isGap) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.red.shade200,
                            thickness: 1,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.more_horiz_rounded,
                                size: 14,
                                color: Color(0xFF991B1B),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Se omitieron mensajes intermedios',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.red.shade200,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: const Border(
                      left: BorderSide(color: Color(0xFFDC2626), width: 3),
                    ),
                  ),
                  child: Text(
                    '“$quote”',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }

    if (chatState.closedReason == 'COUNTERPART_CHAT_SUSPENDED') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_off_rounded, size: 20, color: Color(0xFFD97706)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No puedes unirte al chat porque el otro usuario se encuentra penalizado por la administración.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF1F5F9),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedCircleLock01,
            color: Color(0xFF64748B),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chatState.closedReason == 'chat_disabled'
                  ? 'El chat ha sido deshabilitado para esta orden.'
                  : (chatState.closedReason != null
                      ? 'Chat cerrado: ${chatState.closedReason}'
                      : 'Este chat se encuentra en modo solo lectura porque el pedido ha sido completado o cancelado.'),
              style: const TextStyle(
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
}

