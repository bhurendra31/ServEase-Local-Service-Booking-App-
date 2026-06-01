import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'screens/worker_login_screen.dart';
import 'screens/worker_home_screen.dart';

/// 🔔 GLOBAL NOTIFICATION PLUGIN
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔔 SETUP NOTIFICATION CHANNEL (ANDROID)
Future<void> setupFlutterNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Worker notifications',
    importance: Importance.max,
    playSound: true,
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(channel);

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

 await flutterLocalNotificationsPlugin.initialize(
  initSettings,
  onDidReceiveNotificationResponse: (response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  },
);

}

/// 🔔 SHOW SYSTEM NOTIFICATION (FOREGROUND)
Future<void> showRealNotification({
  required String title,
  required String body,
}) async {
  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notificationDetails,
  );
}

/// 🔔 FCM FOREGROUND LISTENER
void setupFirebaseMessagingListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      showRealNotification(
        title: notification.title ?? 'ServEase Worker',
        body: notification.body ?? '',
      );
    }
  });
}

/// 🔔 REQUEST NOTIFICATION PERMISSION (Android 13+)
Future<void> requestNotificationPermission() async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await requestNotificationPermission(); // ✅ ADD THIS
  await setupFlutterNotifications();
  setupFirebaseMessagingListeners();

  runApp(const WorkerApp());
}

class WorkerApp extends StatelessWidget {
  const WorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ServEase Worker',
      theme: ThemeData(
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WorkerAuthGate(),
    );
  }
}

/// 🔐 AUTH GATE FOR WORKER APP
class WorkerAuthGate extends StatelessWidget {
  const WorkerAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const WorkerHomeScreen();
        }

        return const WorkerLoginScreen();
      },
    );
  }
}
