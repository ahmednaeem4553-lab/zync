import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendNotification(
  String chatid,
  String title,
  String body,
  String type,
  String id,
) async {
  try {
    // Load the service account key
    final serviceAccountJson = await rootBundle.loadString('assets/json/serviceAccountKey.json');
    final serviceAccount = json.decode(serviceAccountJson);

    // Create credentials
    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccount);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    // Obtain an auth client
    final authClient = await clientViaServiceAccount(accountCredentials, scopes);
    final accessToken = authClient.credentials.accessToken;

    // Create notification data
    final notificationData = {
      'title': title,
      'body': body,
      'type': type,
      'userId': id,
      'date': DateTime.now().toIso8601String(),
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save notification to Firestore
    await FirebaseFirestore.instance.collection('notifications').add(notificationData);

    DocumentSnapshot userDoc;
    // Retrieve user document
    // if (isDriver) {
    //   userDoc = await FirebaseFirestore.instance.collection('drivers').doc(id).get();
    // } else
    {
      userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
    }

    final userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null && userData['fcmToken'] != null) {
      final fcmToken = userData['fcmToken'] as String;

      print('Sending notification to FCM token: $fcmToken');

      // Create notification message
      final message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'type': type,
            'userId': id,
            'chatId': chatid,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }
      };

      // Send the HTTP v1 request
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/zync-70721/messages:send');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${accessToken.data}',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification. Response: ${response.body}');
      }
    } else {
      print('User has no FCM token or is inactive: $id');
    }
  } catch (error) {
    print('Error in sendNotification: $error');
  }
}
