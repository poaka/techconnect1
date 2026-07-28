import '../data/notifications_remote_data_source.dart';
import '../domain/notification_model.dart';
import '../domain/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _dataSource;

  NotificationsRepositoryImpl(this._dataSource);

  @override
  Future<NotificationsResult> getNotifications() =>
      _dataSource.getNotifications();

  @override
  Future<void> markAsRead(String notificationId) =>
      _dataSource.markAsRead(notificationId);

  @override
  Future<void> markAllAsRead() => _dataSource.markAllAsRead();
}
