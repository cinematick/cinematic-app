import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cinematick/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String collectionsName = 'notifications';

  /// Get current user's notifications from Firestore
  Stream<List<PushNotification>> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionsName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    PushNotification.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList();
        });
  }

  /// Save a notification to Firestore
  Future<void> saveNotification(PushNotification notification) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionsName)
        .doc(notification.id)
        .set(notification.toJson(), SetOptions(merge: true));
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionsName)
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionsName)
        .doc(notificationId)
        .delete();
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final notifications =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection(collectionsName)
            .get();

    for (var doc in notifications.docs) {
      await doc.reference.delete();
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionsName)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get notifications by type
  Stream<List<PushNotification>> getNotificationsByType(NotificationType type) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionsName)
        .where('type', isEqualTo: type.value)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    PushNotification.fromJson({'id': doc.id, ...doc.data()}),
              )
              .toList();
        });
  }

  /// Subscribe user to notification topics based on preferences
  Future<void> subscribeToNotificationTopics({
    required bool subscribeToNewReleases,
    required bool subscribeToSpecialScreenings,
    required bool subscribeToNearbySessionAlerts,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'notificationPreferences': {
        'newReleases': subscribeToNewReleases,
        'specialScreenings': subscribeToSpecialScreenings,
        'nearbySessionAlerts': subscribeToNearbySessionAlerts,
      },
    });
  }

  /// Get user notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    final doc = await _firestore.collection('users').doc(userId).get();
    final preferences = doc.data()?['notificationPreferences'];

    return {
      'newReleases': preferences?['newReleases'] ?? true,
      'specialScreenings': preferences?['specialScreenings'] ?? true,
      'nearbySessionAlerts': preferences?['nearbySessionAlerts'] ?? true,
    };
  }
}
