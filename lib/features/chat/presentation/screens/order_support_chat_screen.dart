import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_lojita_business/core/config/envs.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_notifier.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_state.dart';
import 'package:tu_lojita_business/features/chat/domain/entities/chat_message.dart';
import 'package:tu_lojita_business/features/chat/presentation/providers/support_chat_provider.dart';
import 'package:tu_lojita_business/features/chat/presentation/widgets/chat_image_preview_dialog.dart';
import 'package:tu_lojita_business/features/company_onboarding/presentation/providers/company_onboarding_providers.dart';
import 'package:tu_lojita_business/features/dashboard/presentation/providers/notifications_provider.dart';
import 'package:tu_lojita_business/features/orders/presentation/providers/dispute_providers.dart';

String _formatSupportChatImageUrl(String? url) {
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

class OrderSupportChatScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderSupportChatScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderSupportChatScreen> createState() => _OrderSupportChatScreenState();
}

class _OrderSupportChatScreenState extends ConsumerState<OrderSupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isUploadingImage = false;
  Timer? _typingDebounce;
  bool _isTypingActive = false;
  StreamSubscription<Map<String, dynamic>>? _supportChatClosedSub;
  bool _isNavigatingToResolution = false;

  @override
  void initState() {
    super.initState();
    _checkInitialDisputeStatus();
    _listenToSupportChatClosed();
  }

  void _listenToSupportChatClosed() {
    _supportChatClosedSub =
        ref.read(socketServiceProvider).supportChatClosedStream.listen((data) {
      final orderId = data['orderId']?.toString();
      if (orderId == widget.orderId && mounted && !_isNavigatingToResolution) {
        _isNavigatingToResolution = true;
        final verdict =
            data['verdictTitle']?.toString() ?? 'Caso resuelto por arbitraje';
        NotificationService.showSuccess(
          context,
          'Soporte ha dictado resolución: $verdict',
        );
        context.go('/dashboard/orders/${widget.orderId}?openDispute=true');
      }
    });
  }

  Future<void> _checkInitialDisputeStatus() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final disputes =
            await ref.read(storeDisputesByOrderProvider(widget.orderId).future);
        final resolvedDispute =
            disputes.where((d) => d.isResolved).firstOrNull;
        if (resolvedDispute != null && mounted && !_isNavigatingToResolution) {
          _isNavigatingToResolution = true;
          NotificationService.showInfo(
            context,
            'Este caso ya ha sido resuelto formalmente por soporte.',
          );
          context.go('/dashboard/orders/${widget.orderId}?openDispute=true');
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _supportChatClosedSub?.cancel();
    _typingDebounce?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    if (text.trim().isNotEmpty) {
      if (!_isTypingActive) {
        _isTypingActive = true;
        ref
            .read(socketServiceProvider)
            .emitSupportTyping(widget.orderId, 'DISPUTE_MERCHANT_SUPPORT', true);
      }
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(seconds: 2), () {
        if (_isTypingActive) {
          _isTypingActive = false;
          ref
              .read(socketServiceProvider)
              .emitSupportTyping(widget.orderId, 'DISPUTE_MERCHANT_SUPPORT', false);
        }
      });
    } else {
      if (_isTypingActive) {
        _isTypingActive = false;
        _typingDebounce?.cancel();
        ref
            .read(socketServiceProvider)
            .emitSupportTyping(widget.orderId, 'DISPUTE_MERCHANT_SUPPORT', false);
      }
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _typingDebounce?.cancel();
      if (_isTypingActive) {
        _isTypingActive = false;
        ref
            .read(socketServiceProvider)
            .emitSupportTyping(widget.orderId, 'DISPUTE_MERCHANT_SUPPORT', false);
      }
      ref
          .read(supportChatProvider(widget.orderId).notifier)
          .sendMessage(text);
      _messageController.clear();
      _focusNode.requestFocus();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isUploadingImage) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
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

      await ref.read(supportChatProvider(widget.orderId).notifier).sendMessage(
        caption,
        imageUrl: uploadedUrl,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Error al subir comprobante: $e');
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
                'Adjuntar Evidencia de la Tienda',
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
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 32, color: Color(0xFF7C3AED)),
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
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_rounded, size: 32, color: Color(0xFF7C3AED)),
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
    final chatState = ref.watch(supportChatProvider(widget.orderId));
    final authState = ref.watch(authProvider);
    final currentUser = (authState is Authenticated) ? authState.user : null;

    ref.listen<SupportChatState>(supportChatProvider(widget.orderId), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final orderShortId = widget.orderId.length >= 8
        ? widget.orderId.substring(0, 8).toUpperCase()
        : widget.orderId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Soporte Tu Lojita',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.verified_rounded, size: 15, color: Color(0xFF7C3AED)),
                    ],
                  ),
                  Text(
                    'Mediación · Pedido #$orderShortId',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
            tooltip: 'Ver Pedido',
            onPressed: () {
              context.push('/orders/${widget.orderId}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de privacidad y confidencialidad para comercio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F3FF),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE9D5FF), width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 15,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Canal Privado con Soporte',
                        style: TextStyle(
                          color: Color(0xFF4C1D95),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'El comprador no tiene acceso a esta conversación. Solo el equipo de soporte de Tu Lojita evaluará tus descargos y comprobantes de la tienda.',
                        style: TextStyle(
                          color: Color(0xFF6D28D9),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: chatState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                    ),
                  )
                : chatState.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFDDD6FE)),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 40,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Inicia la conversación con Soporte',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Envía tus descargos o comprobantes para que el equipo de soporte resuelva la disputa.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 8, left: 8),
                                child: Text(
                                  'Soporte está escribiendo...',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            );
                          }
                          final message = chatState.messages[index];
                          final isMe = message.sender.id == currentUser?.id;
                          return _SupportChatBubble(
                            message: message,
                            isMe: isMe,
                            onRetry: () {
                              ref
                                  .read(supportChatProvider(widget.orderId).notifier)
                                  .retryMessage(message.id);
                            },
                          );
                        },
                      ),
          ),

          // Input de mensaje
          _SupportMessageInput(
            controller: _messageController,
            focusNode: _focusNode,
            isUploading: _isUploadingImage,
            onAttachImage: _showImageSourcePicker,
            onChanged: _onInputChanged,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _SupportChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback onRetry;

  const _SupportChatBubble({
    required this.message,
    required this.isMe,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = message.hasError;
    final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: hasError ? onRetry : null,
        onLongPress: () {
          if (message.content.isNotEmpty) {
            Clipboard.setData(ClipboardData(text: message.content));
            NotificationService.showSuccess(context, 'Mensaje copiado');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hasError
                ? const Color(0xFFFEF2F2)
                : (isMe ? const Color(0xFF7C3AED) : Colors.white),
            border: hasError
                ? Border.all(color: const Color(0xFFEF4444), width: 1)
                : (!isMe ? Border.all(color: const Color(0xFFE2E8F0), width: 1) : null),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_rounded, size: 13, color: Color(0xFF7C3AED)),
                    SizedBox(width: 4),
                    Text(
                      'Soporte Tu Lojita',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              if (hasImage) ...[
                Builder(
                  builder: (context) {
                    final formattedUrl = _formatSupportChatImageUrl(message.imageUrl);
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
                                        color: Color(0xFF7C3AED),
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
                        : (isMe ? Colors.white : const Color(0xFF1E293B)),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.createdAt.toTimeString(),
                    style: TextStyle(
                      color: hasError
                          ? const Color(0xFFEF4444)
                          : (isMe ? Colors.white70 : Colors.grey),
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
                                'Reintentar',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }

                        if (message.id.startsWith('temp-')) {
                          return const HugeIcon(
                            icon: HugeIcons.strokeRoundedTime02,
                            color: Colors.white70,
                            size: 12,
                          );
                        }

                        if (message.isRead) {
                          return const _SupportTicks(isRead: true);
                        }

                        if (message.isDelivered) {
                          return const _SupportTicks(isRead: false);
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
}

class _SupportTicks extends StatelessWidget {
  final bool isRead;
  const _SupportTicks({required this.isRead});

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

class _SupportMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttachImage;
  final bool isUploading;
  final ValueChanged<String>? onChanged;

  const _SupportMessageInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttachImage,
    this.isUploading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            icon: isUploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7C3AED),
                    ),
                  )
                : const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Color(0xFF7C3AED),
                    size: 26,
                  ),
            onPressed: isUploading ? null : onAttachImage,
            tooltip: 'Adjuntar evidencia',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText: 'Escribe a soporte...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            key: const ValueKey('support_send_button'),
            onTap: onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HugeIcon(icon: HugeIcons.strokeRoundedSent, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
