import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinematick/models/notification_model.dart';
import 'package:cinematick/repositories/notification_repository.dart';
import 'package:cinematick/services/notification_service.dart';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository();
});

final notificationServiceProvider = Provider((ref) {
  return NotificationService();
});

/// Stream of user's notifications
final userNotificationsProvider = StreamProvider<List<PushNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUserNotifications();
});

/// Stream of unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount();
});

/// Notifications grouped by type
final newReleaseNotificationsProvider = StreamProvider<List<PushNotification>>((
  ref,
) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationsByType(NotificationType.newRelease);
});

final specialScreeningNotificationsProvider =
    StreamProvider<List<PushNotification>>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByType(
        NotificationType.specialScreening,
      );
    });

final nearbySessionNotificationsProvider =
    StreamProvider<List<PushNotification>>((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByType(NotificationType.nearbySession);
    });

/// Notification preferences provider
final notificationPreferencesProvider = FutureProvider<Map<String, bool>>((
  ref,
) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationPreferences();
});

/// Notification detail for a specific notification
final notificationDetailProvider = Provider.family<PushNotification?, String>((
  ref,
  notificationId,
) {
  final notifications = ref.watch(userNotificationsProvider);
  return notifications.whenData((notifs) {
    try {
      return notifs.firstWhere((n) => n.id == notificationId);
    } catch (e) {
      return null;
    }
  }).value;
});
