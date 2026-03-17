import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'zync_messages',
    'Zync Messages',
    description: 'Notifications for new messages in Zync',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications
    await _setupLocalNotifications();

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Save token
    await _saveToken();

    // Token refresh
    _fcm.onTokenRefresh.listen(_updateToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _setupLocalNotifications() async {
    // v21 Android init settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // v21 Linux settings (required even if not used)
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      // v21 uses onDidReceiveNotificationResponse instead of onSelectNotification
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );
  }

  // v21 callback signature
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap — navigate to chat if needed
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      // v21 show() method
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            // v21 styleInformation
            styleInformation: const DefaultStyleInformation(
              true,
              true,
            ),
          ),
        ),
      );
    }
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

    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update({'fcmToken': token});
  }

  Future<void> sendNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required bool isImage,
  }) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'receiverId': receiverId,
      'senderName': senderName,
      'message': isImage ? '📷 sent you a photo' : message,
      'sentAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }
}

// v21 requires background callback to be top level
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {}