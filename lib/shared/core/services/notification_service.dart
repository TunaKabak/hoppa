import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:core_network/core_network.dart';
import 'package:hoppa/shared/core/services/notification_navigation_helper.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<void> initialize() async {
    // İstek izni
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // Local notifications initalization
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInitialize =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iosInitialize,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        final payloadStr = details.payload;
        if (payloadStr != null) {
          try {
            final data = jsonDecode(payloadStr) as Map<String, dynamic>;
            NotificationNavigationHelper.handleNotificationClick(data);
          } catch (e) {
            print("Local notification payload error: $e");
          }
        }
      },
    );

    // Get FCM Token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await registerToken(token);
    }

    // FCM Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      registerToken(newToken);
    });

    // Background message handler registration
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Background message click handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationNavigationHelper.handleNotificationClick(message.data);
    });

    // Terminated message click handler
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        NotificationNavigationHelper.handleNotificationClick(message.data);
      }
    });
  }

  Future<void> registerToken(String token) async {
    try {
      final platform = Platform.isIOS ? "IOS" : "ANDROID";
      await _apiClient.post(
        '/api/notifications/register-token',
        body: {
          'token': token,
          'platform': platform,
        },
      );
      print("FCM Token successfully registered to backend.");
    } catch (e) {
      print("Failed to register FCM token: $e");
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        payload: jsonEncode(message.data),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // name
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
