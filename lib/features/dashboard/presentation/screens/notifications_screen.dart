import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tu_lojita_business/core/utils/date_utils.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/notifications_provider.dart';
import '../../domain/entities/notification.dart';

enum NotificationFilter { all, unread, chats, orders }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;
  bool _isMarkingAllAsRead = false;

  Future<void> _markAllAsRead(List<AppNotification> unreadNotifications) async {
    if (unreadNotifications.isEmpty) return;

    setState(() {
      _isMarkingAllAsRead = true;
    });

    try {
      await Future.wait(
        unreadNotifications.map((n) => ref.read(notificationRepositoryProvider).markAsRead(n.id)),
      );
      ref.invalidate(notificationsProvider);
      if (mounted) {
        NotificationService.showSuccess(context, 'Todas las notificaciones marcadas como leídas');
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showError(context, 'Error al marcar las notificaciones como leídas');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingAllAsRead = false;
        });
      }
    }
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications) {
    switch (_selectedFilter) {
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.chats:
        return notifications.where((n) => n.type == 'CHAT_MESSAGE').toList();
      case NotificationFilter.orders:
        return notifications
            .where((n) => [
                  'ORDER_CREATED',
                  'PAYMENT_REPORTED',
                  'PAYMENT_APPROVED',
                  'PAYMENT_REJECTED'
                ].contains(n.type))
            .toList();
      case NotificationFilter.all:
        return notifications;
    }
  }

  String _getFilterFriendlyName() {
    switch (_selectedFilter) {
      case NotificationFilter.unread:
        return 'No leídas';
      case NotificationFilter.chats:
        return 'Mensajes';
      case NotificationFilter.orders:
        return 'Pedidos y Pagos';
      case NotificationFilter.all:
        return 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: Color(0xFF111827),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final unread = notifications.where((n) => !n.isRead).toList();
              if (unread.isEmpty) return const SizedBox.shrink();

              return _isMarkingAllAsRead
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Marcar todas como leídas',
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTickDouble01,
                        color: Colors.indigo,
                        size: 24,
                      ),
                      onPressed: () => _markAllAsRead(unread),
                    );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: Color(0xFF4B5563),
              size: 22,
            ),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final filtered = _filterNotifications(notifications);
          final sortedNotifications = List<AppNotification>.from(filtered)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Chips Row
              _buildFilterChips(notifications),
              
              // Notifications List
              Expanded(
                child: RefreshIndicator(
                  color: Colors.indigo,
                  onRefresh: () async => ref.invalidate(notificationsProvider),
                  child: sortedNotifications.isEmpty
                      ? _buildPremiumEmptyState(
                          context,
                          notifications.isEmpty ? 'General' : _getFilterFriendlyName(),
                          notifications.isEmpty,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: sortedNotifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final notification = sortedNotifications[index];
                            return _PremiumNotificationTile(
                              key: ValueKey(notification.id),
                              notification: notification,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Colors.indigo,
          ),
        ),
        error: (error, stack) => _buildPremiumErrorState(),
      ),
    );
  }

  Widget _buildFilterChips(List<AppNotification> notifications) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final chatsCount = notifications.where((n) => n.type == 'CHAT_MESSAGE').length;
    final ordersCount = notifications
        .where((n) => [
              'ORDER_CREATED',
              'PAYMENT_REPORTED',
              'PAYMENT_APPROVED',
              'PAYMENT_REJECTED'
            ].contains(n.type))
        .length;

    return Container(
      height: 62,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildChip(NotificationFilter.all, 'Todas', notifications.length),
          const SizedBox(width: 8),
          _buildChip(NotificationFilter.unread, 'No leídas', unreadCount, badgeColor: const Color(0xFFE11D48)),
          const SizedBox(width: 8),
          _buildChip(NotificationFilter.chats, 'Mensajes', chatsCount, badgeColor: Colors.blue.shade600),
          const SizedBox(width: 8),
          _buildChip(NotificationFilter.orders, 'Pedidos', ordersCount, badgeColor: Colors.orange.shade700),
        ],
      ),
    );
  }

  Widget _buildChip(NotificationFilter filter, String label, int count, {Color? badgeColor}) {
    final isSelected = _selectedFilter == filter;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : (badgeColor ?? Colors.indigo).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (badgeColor ?? Colors.indigo),
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = filter;
            });
          }
        },
        selectedColor: Colors.indigo,
        backgroundColor: const Color(0xFFF3F4F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.indigo : Colors.transparent,
            width: 1,
          ),
        ),
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
        shadowColor: Colors.indigo.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildPremiumEmptyState(BuildContext context, String filterName, bool absoluteEmpty) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Circle Illustration
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.indigo.withValues(alpha: 0.15),
                          Colors.indigo.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedNotification01,
                      color: Colors.indigo.shade400,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                absoluteEmpty ? 'Bandeja limpia' : 'Sin notificaciones',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                absoluteEmpty
                    ? 'Te avisaremos cuando haya novedades importantes en tu tienda.'
                    : 'No tienes notificaciones en la categoría "$filterName" por ahora.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (!absoluteEmpty && _selectedFilter != NotificationFilter.all) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFilter = NotificationFilter.all;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: const Text(
                    'Ver Todas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                color: Color(0xFFDC2626),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar notificaciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Por favor, verifica tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => ref.invalidate(notificationsProvider),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                size: 16,
                color: Colors.indigo,
              ),
              label: const Text(
                'Reintentar',
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumNotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _PremiumNotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUnread = !notification.isRead;
    final timeStr = notification.createdAt.toDateTimeString();

    Color iconColor;
    dynamic iconData;
    String categoryLabel;

    switch (notification.type) {
      case 'ORDER_CREATED':
        iconData = HugeIcons.strokeRoundedShoppingBag01;
        iconColor = Colors.orange.shade700;
        categoryLabel = 'Pedido nuevo';
        break;
      case 'PAYMENT_REPORTED':
        iconData = HugeIcons.strokeRoundedInvoice01;
        iconColor = Colors.amber.shade800;
        categoryLabel = 'Pago reportado';
        break;
      case 'PAYMENT_APPROVED':
        iconData = HugeIcons.strokeRoundedTick01;
        iconColor = const Color(0xFF10B981);
        categoryLabel = 'Pago aprobado';
        break;
      case 'PAYMENT_REJECTED':
        iconData = HugeIcons.strokeRoundedAlert01;
        iconColor = const Color(0xFFE11D48);
        categoryLabel = 'Pago rechazado';
        break;
      case 'CHAT_MESSAGE':
        iconData = HugeIcons.strokeRoundedMessage01;
        iconColor = Colors.blue.shade700;
        categoryLabel = 'Chat';
        break;
      default:
        iconData = HugeIcons.strokeRoundedNotification02;
        iconColor = Colors.indigo.shade600;
        categoryLabel = 'Sistema';
    }

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread ? Colors.indigo.withValues(alpha: 0.15) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Left visual indicator bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: Container(
                color: isUnread ? iconColor : Colors.grey.shade300,
              ),
            ),
            InkWell(
              onTap: () => _handleTap(context, ref),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: HugeIcon(
                        icon: iconData,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  categoryLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.indigo,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: isUnread ? const Color(0xFF111827) : const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.body,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isUnread ? const Color(0xFF374151) : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                size: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      await ref.read(notificationRepositoryProvider).markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
    }

    if (!context.mounted) return;

    if (notification.targetId != null && notification.targetId!.isNotEmpty) {
      if (notification.type == 'CHAT_MESSAGE') {
        context.push('/dashboard/orders/${notification.targetId}/chat');
      } else {
        context.push('/dashboard/orders/${notification.targetId}');
      }
    }
  }
}
