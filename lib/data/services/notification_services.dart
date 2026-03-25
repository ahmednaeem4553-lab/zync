import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

@pragma('vm:entry-point')
void onBackgroundNotificationTapped(NotificationResponse response) {}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Step 1 — background FCM handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Step 2 — request FCM permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Step 3 — Android init settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Step 4 — iOS init settings
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Step 5 — combined init settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    // Step 6 — initialize plugin with v21 callbacks
    await _plugin.initialize(
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationTapped,
      settings: InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    // Step 7 — create Android notification channel
    // v21 correct way: store implementation first then call method
    final AndroidFlutterLocalNotificationsPlugin androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;

    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        'zync_messages',
        'Zync Messages',
        description: 'Notifications for new messages in Zync',
        importance: Importance.high,
      ),
    );

    // Step 8 — request Android 13+ notification permission
    await androidImplementation.requestNotificationsPermission();

    // Step 9 — save FCM token
    await _saveToken();

    // Step 10 — listen to token refresh
    _fcm.onTokenRefresh.listen(_updateToken);

    // Step 11 — foreground message listener
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  // v21 correct callback signature
  void _onNotificationTapped(NotificationResponse response) {}

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // v21 correct show() — uses named parameters
    _plugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'zync_messages',
          'Zync Messages',
          channelDescription: 'Notifications for new messages in Zync',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await _updateToken(token);
  }

  Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'fcmToken': token});
    } catch (_) {}
  }

  Future<void> sendNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required bool isImage,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'senderName': senderName,
        'message': isImage ? '📷 sent you a photo' : message,
        'sentAt': DateTime.now().toIso8601String(),
        'isRead': false,
      });
    } catch (_) {}
  }
}
