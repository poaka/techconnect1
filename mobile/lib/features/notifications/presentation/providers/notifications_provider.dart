import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/auth_state.dart';
import '../../data/notifications_remote_data_source.dart';
import '../../data/notifications_repository_impl.dart';
import '../../domain/notification_model.dart';
import '../../domain/notifications_repository.dart';

// ─── Dependency providers ────────────────────────────────────────────────────

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationsRemoteDataSource(dioClient.dio);
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final dataSource = ref.watch(notificationsRemoteDataSourceProvider);
  return NotificationsRepositoryImpl(dataSource);
});

// ─── State ────────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;
  Timer? _pollingTimer;

  NotificationsNotifier(this._repository) : super(const NotificationsState());

  /// Fetch once and start polling every 30 seconds.
  void startPolling() {
    fetch();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetch() async {
    // Don't show loading spinner on background poll refreshes
    if (state.notifications.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final result = await _repository.getNotifications();
      state = state.copyWith(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger les notifications.',
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      final updated = state.notifications.map((n) {
        if (n.id == notificationId) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final newUnread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: newUnread);
    } catch (_) {
      // Silent — the badge will reconcile on next poll
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Impossible de marquer toutes les notifications comme lues.');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final notifier = NotificationsNotifier(repo);

  // Only start polling when the user is authenticated
  final authState = ref.watch(authNotifierProvider);
  if (authState.status == AuthStatus.authenticated) {
    notifier.startPolling();
  }

  ref.onDispose(() => notifier.stopPolling());

  return notifier;
});

/// Convenience provider that exposes only the unread count — used for the badge.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsNotifierProvider).unreadCount;
});
