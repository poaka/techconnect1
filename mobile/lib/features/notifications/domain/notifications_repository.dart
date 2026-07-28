import 'notification_model.dart';

abstract class NotificationsRepository {
  Future<NotificationsResult> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}
