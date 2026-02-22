import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cinematick/services/notification_service.dart';
import 'package:cinematick/models/notification_model.dart';
import 'package:cinematick/views/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize timezone database
  tz.initializeTimeZones();

  // 🔔 Initialize Push Notifications
  await _initializeNotifications();

  // Configure system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeNotifications() async {
  final notificationService = NotificationService();

  await notificationService.initialize(
    onNotificationReceived: (notification) {
      print('Notification received: ${notification.title}');
      // Handle foreground notification received
      _showNotificationSnackBar(notification);
    },
    onNotificationTapped: (notification) {
      print('Notification tapped: ${notification.title}');
      // Handle notification tap
      _handleNotificationTap(notification);
    },
  );
}

void _showNotificationSnackBar(PushNotification notification) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationTap(notification),
        ),
      ),
    );
  }
}

void _handleNotificationTap(PushNotification notification) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    // Navigate to notification detail or relevant screen based on type
    if (notification.movieId != null) {
      // Navigate to movie detail screen
      // Example: Navigator.pushNamed(context, '/movie/${notification.movieId}');
    } else if (notification.screeningId != null) {
      // Navigate to screening detail or booking screen
      // Example: Navigator.pushNamed(context, '/screening/${notification.screeningId}');
    } else {
      // Navigate to notifications history
      // Navigator.pushNamed(context, '/notifications');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinemaTick',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
    );
  }
}
