import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cinematick/models/notification_model.dart';

/// Global background message handler for push notifications
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // You can handle the background message here
  // For now, we just log it
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Function(PushNotification)? _onNotificationReceived;
  Function(PushNotification)? _onNotificationTapped;

  /// Initialize the notification service
  Future<void> initialize({
    required Function(PushNotification) onNotificationReceived,
    required Function(PushNotification) onNotificationTapped,
  }) async {
    _onNotificationReceived = onNotificationReceived;
    _onNotificationTapped = onNotificationTapped;

    // Request user permission for notifications
    await requestNotificationPermission();

    // Get FCM token
    String? token = await getFCMToken();
    print('FCM Token: $token');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification when app is opened from a terminated state
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTapped(initialMessage);
    }

    // Handle notification when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTapped);
  }

  /// Request notification permission (iOS and Android 13+)
  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined notification permission');
    }
  }

  /// Get FCM token for this device
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a notification topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a notification topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received:');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');

    final notification = _convertRemoteMessageToNotification(message);
    _onNotificationReceived?.call(notification);
  }

  /// Handle message when app is tapped from background/terminated
  void _handleMessageTapped(RemoteMessage message) {
    print('Message tapped: ${message.messageId}');
    final notification = _convertRemoteMessageToNotification(message);
    _onNotificationTapped?.call(notification);
  }

  /// Convert RemoteMessage to PushNotification
  PushNotification _convertRemoteMessageToNotification(RemoteMessage message) {
    return PushNotification(
      id: message.messageId ?? DateTime.now().toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: NotificationType.fromString(message.data['type'] ?? 'new_release'),
      imageUrl:
          message.notification?.android?.imageUrl ?? message.data['imageUrl'],
      movieId: message.data['movieId'],
      screeningId: message.data['screeningId'],
      additionalData: message.data,
      timestamp: DateTime.now(),
      isRead: false,
    );
  }

  /// Send notification to FCM (for testing, call from backend)
  static const String newReleaseTopic = 'new_releases';
  static const String specialScreeningTopic = 'special_screenings';
  static const String nearbySessionTopic = 'nearby_sessions';
}
