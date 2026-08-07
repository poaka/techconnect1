import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return context.tr('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${context.tr('min_ago')}';
    if (diff.inHours < 24) return '${diff.inHours} ${context.tr('hours_ago')}';
    if (diff.inDays == 1) return context.tr('yesterday');
    if (diff.inDays < 7) return '${diff.inDays} ${context.tr('days_ago')}';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'request_created':
        return Icons.add_task_outlined;
      case 'request_status_change':
        return Icons.sync_alt_rounded;
      case 'verification_update':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'request_created':
        return AppColors.primary;
      case 'request_status_change':
        return AppColors.accent;
      case 'verification_update':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications_title')),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(context.tr('mark_all_read')),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              onPressed: () => notifier.markAllAsRead(),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.fetch(),
          child: _buildBody(context, state, notifier),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: isDark ? AppColors.darkBorder : AppColors.border),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.fetch(),
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: context.tr('no_notifications'),
              subtitle: context.tr('no_notifications_desc'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? AppColors.darkBorder : AppColors.border),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _NotificationTile(
          notification: notification,
          formattedDate: _formatDate(context, notification.createdAt),
          icon: _getNotificationIcon(notification.type),
          iconColor: _getNotificationColor(notification.type),
          onTap: () {
            if (!notification.isRead) {
              notifier.markAsRead(notification.id);
            }
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String formattedDate;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.formattedDate,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unreadBg = isDark
        ? AppColors.darkPrimarySubtle
        : AppColors.primarySubtle.withValues(alpha: 0.6);
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtitleColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? unreadBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
