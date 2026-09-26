import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/utils/notification_service.dart';
import '../providers/notifications_provider.dart';
import '../providers/stores_notifier.dart';
import '../../domain/entities/notification.dart';
import 'settings/store_health_sheet.dart';
import '../widgets/chat_penalty_explanation_modal.dart';
import 'package:tu_lojita_business/features/reports/presentation/widgets/report_detail_sheet.dart';
import 'package:tu_lojita_business/features/auth/presentation/providers/auth_providers.dart';
import 'package:tu_lojita_business/core/utils/achievement_image_helper.dart';
import 'package:tu_lojita_business/features/ranking/presentation/providers/ranking_providers.dart';

enum NotificationFilter { all, unread, chats, orders }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _selectedFilter = NotificationFilter.all;
  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(notificationsProvider);
    });
  }

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
                  'PAYMENT_REJECTED',
                  'MEDIATION_REQUEST',
                  'MEDIATION_RESPONSE',
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
              'PAYMENT_REJECTED',
              'MEDIATION_REQUEST',
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

  String _formatNotificationBody(String rawBody) {
    if (rawBody.isEmpty) return rawBody;
    var formatted = rawBody;
    formatted = formatted.replaceAll('(ACCOUNT_REACTIVATION)', 'Reactivación de compras');
    formatted = formatted.replaceAll('(SETTLE_DEBT)', 'Acuerdo de saldo pendiente');
    formatted = formatted.replaceAll('(CLARIFY_MISUNDERSTANDING)', 'Aclaratoria de malentendido');
    formatted = formatted.replaceAll('(OTHER)', 'Consulta general');
    formatted = formatted.replaceAll('mediación Reactivación', 'mediación: Reactivación');
    formatted = formatted.replaceAll('mediación Acuerdo', 'mediación: Acuerdo');
    formatted = formatted.replaceAll('mediación Aclaratoria', 'mediación: Aclaratoria');
    formatted = formatted.replaceAll('mediación Consulta', 'mediación: Consulta');
    return formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUnread = !notification.isRead;
    final timeStr = timeago.format(notification.createdAt, locale: 'es');

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
      case 'MEDIATION_REQUEST':
      case 'MEDIATION_RESPONSE':
        final isCustomerMed = notification.title.toLowerCase().contains('mediación') ||
            notification.title.toLowerCase().contains('mediacion');
        iconData = HugeIcons.strokeRoundedAlertSquare;
        iconColor = isCustomerMed ? Colors.purple.shade700 : const Color(0xFFE11D48);
        categoryLabel = isCustomerMed ? 'Mediación' : 'Reclamo';
        break;
      case 'STRIKE_APPLIED':
        iconData = HugeIcons.strokeRoundedAlert02;
        iconColor = const Color(0xFFD97706);
        categoryLabel = 'Sanción';
        break;
      case 'STORE_SUSPENDED':
        iconData = HugeIcons.strokeRoundedAlertCircle;
        iconColor = const Color(0xFFDC2626);
        categoryLabel = 'Suspensión';
        break;
      case 'ITEM_HIDDEN':
        iconData = HugeIcons.strokeRoundedViewOffSlash;
        iconColor = const Color(0xFFEA580C);
        categoryLabel = 'Publicación';
        break;
      case 'BUYER_REVIEW_PROMPT':
        iconData = HugeIcons.strokeRoundedStar;
        iconColor = Colors.amber.shade700;
        categoryLabel = 'Calificar cliente';
        break;
      case 'ORDER_REVIEW_RECEIVED':
        iconData = HugeIcons.strokeRoundedStar;
        iconColor = Colors.amber.shade700;
        categoryLabel = 'Nueva reseña';
        break;
      case 'ACHIEVEMENT_UNLOCKED':
        iconData = HugeIcons.strokeRoundedAward01;
        iconColor = Colors.amber.shade800;
        categoryLabel = 'Logro';
        break;
      case 'DIVISION_UP':
      case 'DIVISION_DOWN':
      case 'STORE_FLAGGED':
      case 'WEEKLY_RANKING_SUMMARY':
      case 'STREAK_EXPIRING':
      case 'CATEGORY_RIVALRY':
      case 'RANK_SHIELD_EXPIRING':
      case 'DANGER_ZONE_ALERT':
        iconData = HugeIcons.strokeRoundedCrown;
        iconColor = Colors.amber.shade700;
        categoryLabel = 'Ranking';
        break;
      default:
        iconData = HugeIcons.strokeRoundedNotification02;
        iconColor = Colors.indigo.shade600;
        categoryLabel = 'Sistema';
    }

    String? achievementBadgeUrl;
    if (notification.type == 'ACHIEVEMENT_UNLOCKED') {
      final titleMatch = RegExp(r'["“«](.+?)["”»]').firstMatch(notification.body);
      final achievementName = titleMatch?.group(1);

      // Check if store achievements list is already available in provider cache
      final storeId = ref.watch(storesProvider).stores.firstOrNull?.id;
      if (storeId != null && storeId.isNotEmpty) {
        final achievements = ref.watch(storeAchievementsProvider(storeId)).asData?.value;
        if (achievements != null) {
          final match = achievements.where((a) =>
            (notification.targetId != null && notification.targetId!.isNotEmpty && a.id == notification.targetId) ||
            (achievementName != null && a.title.toLowerCase().trim() == achievementName.toLowerCase().trim())
          ).firstOrNull;
          if (match != null && match.badgeUrl != null && match.badgeUrl!.isNotEmpty) {
            achievementBadgeUrl = resolveAchievementBadgeUrl(match.badgeUrl, achievementName: match.title);
          }
        }
      }
      achievementBadgeUrl ??= resolveAchievementBadgeUrl(null, achievementName: achievementName);
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
                    if (notification.type == 'ACHIEVEMENT_UNLOCKED' && achievementBadgeUrl != null)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: Image.network(
                          achievementBadgeUrl,
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => HugeIcon(
                            icon: HugeIcons.strokeRoundedAward01,
                            color: iconColor,
                            size: 22,
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              ),
                            );
                          },
                        ),
                      )
                    else
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
                            _formatNotificationBody(notification.body),
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
    if (notification.type == 'STRIKE_APPLIED' ||
        notification.type == 'STORE_SUSPENDED') {
      final storeId = (notification.targetId != null &&
              notification.targetId!.isNotEmpty)
          ? notification.targetId!
          : (ref.read(storesProvider).stores.firstOrNull?.id ?? '');
      if (storeId.isNotEmpty) {
        StoreHealthSheet.show(context, storeId);
      }
    } else if (notification.type == 'ITEM_HIDDEN') {
      final storeId = ref.read(storesProvider).stores.firstOrNull?.id;
      if (storeId != null && storeId.isNotEmpty) {
        context.push('/dashboard/stores/$storeId/items');
      } else {
        context.push('/dashboard');
      }
    } else if (notification.type == 'REPORT_RESOLUTION') {
      if (notification.targetId != null && notification.targetId!.isNotEmpty) {
        ReportDetailSheet.show(context, notification.targetId!);
      } else {
        ChatPenaltyExplanationModal.show(
          context,
          title: notification.title,
          body: notification.body,
        );
      }
    } else if (notification.type == 'CHAT_PENALTY' ||
        notification.title.toLowerCase().contains('moderación') ||
        notification.title.toLowerCase().contains('suspensión') ||
        notification.title.toLowerCase().contains('advertencia')) {
      ChatPenaltyExplanationModal.show(
        context,
        title: notification.title,
        body: notification.body,
      );
    } else if (notification.type == 'ACHIEVEMENT_UNLOCKED') {
      var storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      if (storeId.isEmpty) {
        await ref.read(storesProvider.notifier).loadData();
        storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      }

      int bonus = 0;
      final match = RegExp(r'\+(\d+)\s*(?:LP|PR)', caseSensitive: false)
          .firstMatch(notification.body);
      if (match != null) {
        bonus = int.tryParse(match.group(1) ?? '0') ?? 0;
      }

      String achievementTitle = notification.title;
      String achievementDesc = notification.body;

      final titleMatch = RegExp(r'["“«](.+?)["”»]').firstMatch(notification.body);
      if (titleMatch != null) {
        achievementTitle = titleMatch.group(1) ?? notification.title;
      }

      // Initial baseline URL resolved by title
      String badgeUrl = resolveAchievementBadgeUrl(null, achievementName: achievementTitle);

      // Mostrar loader sutil mientras se descarga y precachea la imagen
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black26,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),
          ),
        );
      }

      final achievementId = notification.targetId;
      if (achievementId != null && achievementId.isNotEmpty) {
        try {
          final dio = ref.read(dioProvider);
          final res = await dio
              .get('/ranking/achievements/$achievementId')
              .timeout(const Duration(seconds: 4));
          if (res.data is Map<String, dynamic>) {
            final data = res.data as Map<String, dynamic>;
            if (data['name'] != null && data['name'].toString().isNotEmpty) {
              achievementTitle = data['name'].toString();
            }
            if (data['description'] != null &&
                data['description'].toString().isNotEmpty) {
              achievementDesc = data['description'].toString();
            }
            if (data['lpBonus'] != null) {
              bonus = int.tryParse(data['lpBonus'].toString()) ?? bonus;
            }
            final rawImg = (data['imageUrl'] ?? data['badgeUrl'])?.toString();
            badgeUrl = resolveAchievementBadgeUrl(rawImg, achievementName: achievementTitle);
          }
        } catch (_) {
          // Si falla la consulta directa, fallback sin romper el flujo
        }
      }

      // Descargar y precachear en memoria antes de abrir la pantalla
      if (badgeUrl.isNotEmpty && context.mounted) {
        try {
          await precacheImage(NetworkImage(badgeUrl), context)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Si el precache falla o excede el timeout, continuar
        }
      }

      // Cerrar loader
      if (context.mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        context.push('/dashboard/ranking/achievement-unlocked', extra: {
          'title': achievementTitle,
          'description': achievementDesc,
          'lpBonus': bonus,
          'badgeUrl': badgeUrl,
          'storeId': storeId,
        });
      }
    } else if (notification.type == 'DIVISION_UP') {
      var storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      if (storeId.isEmpty) {
        await ref.read(storesProvider.notifier).loadData();
        storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      }
      if (context.mounted) {
        context.push('/dashboard/ranking/celebration', extra: {
          'storeId': storeId,
        });
      }
    } else if (notification.type == 'DIVISION_DOWN') {
      var storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      if (storeId.isEmpty) {
        await ref.read(storesProvider.notifier).loadData();
        storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      }
      if (context.mounted) {
        context.push('/dashboard/ranking/division-down', extra: {
          'storeId': storeId,
        });
      }
    } else if (notification.type == 'STORE_FLAGGED') {
      var storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      if (storeId.isEmpty) {
        await ref.read(storesProvider.notifier).loadData();
        storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      }
      if (context.mounted) {
        context.push('/dashboard/ranking/flagged', extra: {
          'storeId': storeId,
          'reason': notification.body,
        });
      }
    } else if (notification.type == 'WEEKLY_RANKING_SUMMARY' ||
        notification.type == 'STREAK_EXPIRING' ||
        notification.type == 'CATEGORY_RIVALRY' ||
        notification.type == 'RANK_SHIELD_EXPIRING' ||
        notification.type == 'DANGER_ZONE_ALERT') {
      var storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      if (storeId.isEmpty) {
        await ref.read(storesProvider.notifier).loadData();
        storeId = ref.read(storesProvider).stores.firstOrNull?.id ?? '';
      }
      if (context.mounted) {
        if (storeId.isNotEmpty) {
          context.push('/dashboard/stores/$storeId/ranking');
        } else {
          NotificationService.showInfo(context, notification.body);
        }
      }
    } else if (notification.targetId != null && notification.targetId!.isNotEmpty) {
      if (notification.type == 'CHAT_MESSAGE') {
        context.push('/dashboard/orders/${notification.targetId}/chat');
      } else if (notification.type == 'MEDIATION_REQUEST' ||
          notification.type == 'MEDIATION_RESPONSE') {
        final isCustomerMed = notification.title.toLowerCase().contains('mediación') ||
            notification.title.toLowerCase().contains('mediacion') ||
            notification.body.toLowerCase().contains('solicitud de mediación') ||
            notification.body.toLowerCase().contains('solicitud de mediacion');

        if (isCustomerMed) {
          var storeId = ref.read(storesProvider).stores.firstOrNull?.id;
          if (storeId == null || storeId.isEmpty) {
            await ref.read(storesProvider.notifier).loadData();
            storeId = ref.read(storesProvider).stores.firstOrNull?.id;
          }

          if (context.mounted) {
            if (storeId != null && storeId.isNotEmpty) {
              context.push('/dashboard/stores/$storeId/mediation-requests');
            } else {
              NotificationService.showInfo(context, notification.body);
            }
          }
        } else {
          context.push('/dashboard/orders/${notification.targetId}?openDispute=true');
          ref.read(notificationRepositoryProvider).markDisputeRead(notification.targetId!);
        }
      } else if (notification.type == 'ORDER_CREATED' ||
          notification.type == 'ORDER_STATUS_CHANGED' ||
          notification.type == 'PAYMENT_REPORTED' ||
          notification.type == 'PAYMENT_APPROVED' ||
          notification.type == 'PAYMENT_REJECTED' ||
          notification.type == 'ORDER_REVIEW_RECEIVED' ||
          notification.type == 'BUYER_REVIEW_PROMPT' ||
          notification.type.startsWith('ORDER_') ||
          notification.type.startsWith('PAYMENT_')) {
        context.push('/dashboard/orders/${notification.targetId}');
      }
    }

    if (!notification.isRead) {
      ref.read(notificationRepositoryProvider)
          .markAsRead(notification.id)
          .then((_) {
            ref.invalidate(notificationsProvider);
          })
          .catchError((_) {});
    }
  }
}
