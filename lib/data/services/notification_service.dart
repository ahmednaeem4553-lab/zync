import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:zync/modules/chat/view/chat_view.dart';
import 'package:zync/modules/chat/viewmodel/chat_viewmodel.dart';

// Top-level function for background/terminated notification taps
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  Get.toNamed('/main');
}

class NotificationServices {
  static final NotificationServices _instance =
      NotificationServices._internal();
  factory NotificationServices() => _instance;
  NotificationServices._internal();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'zync_high_importance_channel';
  static const String channelName = 'Zync Chat Notifications';

  // Initialize local notifications (Call this once in main.dart)
  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    // Android channel + Android 13+ permission
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImpl?.requestNotificationsPermission();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.high,
      playSound: true,
    );

    await androidImpl?.createNotificationChannel(channel);
  }

  // Foreground notification tap handler
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    Get.toNamed('/main');
  }

  // Handle foreground FCM messages with smart skip logic
  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print(
          '📩 Foreground FCM | Title: ${message.notification?.title} | chatId: ${message.data['chatId']}',
        );
      }

      // Skip notification if user is already viewing this exact chat
      if (Get.currentRoute == '/chat') {
        final chatVm = Get.isRegistered<ChatViewModel>()
            ? Get.find<ChatViewModel>()
            : null;

        if (chatVm != null && chatVm.currentChatId != null) {
          final currentChatId = chatVm.currentChatId!;
          final incomingChatId = message.data['chatId']?.toString();

          if (incomingChatId != null && currentChatId == incomingChatId) {
            if (kDebugMode) {
              print('✅ Already viewing this chat → Notification SKIPPED');
            }
            return; // Do not show notification
          }
        }
      }

      // Show notification for other cases
      await showNotification(message);
    });

    // Handle when app is opened from background via notification
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

  // Show local notification - Correct syntax for flutter_local_notifications: 21.0.0
  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Zync chat notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> requestNotificationPermission() async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<String?> getDeviceToken() async {
    return await messaging.getToken();
  }

  void isTokenRefresh() {
    messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) print('Token refreshed: $token');
    });
  }

  Future<void> setupInteractMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleMessage(initialMessage);
    }
  }

  void handleMessage(RemoteMessage message) {
    if (kDebugMode) print('Notification tapped - Data: ${message.data}');

    if (message.data['type'] == 'msj') {
      Get.to(() => const ChatView());
    } else {
      Get.toNamed('/main');
    }
  }

  Future<void> forgroundMessage() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}
