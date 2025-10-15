import 'dart:developer' as log;

import 'package:chys/app/routes/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationUtil {
  static const String like = "LIKE";
  static const String comment = "COMMENT";
  static const String invitePodcast = "PODCAST_INVITE";

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;

  void allTasks(BuildContext context) async {
    await requestNotificationPermission();
    await firebaseInit(context);
    await onInteractMessage(context);
    await getToken();
  }

  Future<void> firebaseInit(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;
    FirebaseMessaging.onMessage.listen((message) {
      print("📩 Notification Title: ${message.notification?.title}");
      print("📝 Notification Body: ${message.notification?.body}");
      print("📊 Data Payload: ${message.data}");

      if (message.notification != null) {
        initNotification(context, message);
        showNotification(message);
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    const String channelId = "high_importance_channel";

    AndroidNotificationChannel androidNotificationChannel =
        const AndroidNotificationChannel(
      channelId,
      "App Notifications",
      description: "Used for important notifications.",
      importance: Importance.high,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      androidNotificationChannel.id,
      androidNotificationChannel.name,
      channelDescription: androidNotificationChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      sound: "sound.wav",
      presentAlert: true,
      presentBadge: true,
      presentBanner: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    flutterLocalNotificationsPlugin.show(
      1,
      message.notification?.title ?? "No Title",
      message.notification?.body ?? "No Body",
      notificationDetails,
    );
  }

  Future<void> dummyNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        sound: 'sound.wav',
        presentAlert: true,
        presentBadge: true,
        presentBanner: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      123,
      'Sound Test',
      'This is a test notification with sound.wav',
      notificationDetails,
    );
  }

  Future<void> onInteractMessage(BuildContext context) async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      handelMessage(context, message);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handelMessage(context, event);
    });
  }

  void handelMessage(BuildContext context, RemoteMessage message) {
    if (message.data.isNotEmpty) {
      String? notificationType = message.data['type'];

      switch (notificationType) {
        case invitePodcast:
          Get.toNamed(AppRoutes.allPodcast);
          break;
        case like:
        case comment:
          Get.toNamed(AppRoutes.home);
          break;
        default:
          break;
      }
    }
  }

  Future<String> getToken() async {
    try {
      String? token = await firebaseMessaging.getToken();
      log.log("📱 Firebase Token: $token");
      return token ?? "123";
    } catch (error) {
      print("⚠️ Error fetching token: $error");
      return error.toString();
    }
  }

  Future<void> isTokenChange() async {
    firebaseMessaging.onTokenRefresh.listen((String? event) async {
      print("🔄 Token Refreshed: $event");
    });
  }

  Future<void> initNotification(
      BuildContext context, RemoteMessage message) async {
    const androidInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestCriticalPermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (response) {
      print("🔔 Notification Clicked: ${response.payload}");
      handelMessage(context, message);
    });

    print("✅ Notifications: Initialized");
  }

  static Future<void> requestNotificationPermission() async {
    await Future.delayed(const Duration(seconds: 5));
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        print("✅ Notification permission granted");
        break;
      case AuthorizationStatus.denied:
        print("❌ Notification permission denied");
        break;
      case AuthorizationStatus.provisional:
        print("⚠️ Provisional permission granted");
        break;
      default:
        print("❔ Unknown permission status");
    }
  }
}
