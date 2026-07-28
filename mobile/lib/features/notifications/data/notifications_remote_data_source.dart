import 'package:dio/dio.dart';

import '../domain/notification_model.dart';

class NotificationsRemoteDataSource {
  final Dio _dio;

  NotificationsRemoteDataSource(this._dio);

  Future<NotificationsResult> getNotifications() async {
    final response = await _dio.get('/notifications');
    final data = response.data['data'] as Map<String, dynamic>;
    final rawList = (data['notifications'] as List<dynamic>? ?? []);
    final notifications = rawList
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    final unreadCount = (data['unreadCount'] as int?) ?? 0;
    return NotificationsResult(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }
}
