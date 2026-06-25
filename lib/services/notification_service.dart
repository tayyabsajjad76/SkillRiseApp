import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {

  debugPrint('📬 BG message: ${message.messageId}');
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _db  = FirebaseFirestore.instance;

  static Future<void> init(BuildContext context) async {

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');

    await _saveToken();

    _fcm.onTokenRefresh.listen(_updateToken);

    FirebaseMessaging.onMessage.listen((message) {
      _handleForegroundMessage(message, context);
    });
  }

  static Future<void> _saveToken() async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
    debugPrint('✅ FCM token saved');
  }

  static Future<void> _updateToken(String token) async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  static void _handleForegroundMessage(RemoteMessage message, BuildContext context) {
    final title = message.notification?.title ?? 'Notification';
    final body  = message.notification?.body  ?? '';


    _saveNotification(title, body);


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (body.isNotEmpty) Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF1A56FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Future<void> _saveNotification(String title, String body) async {
    final uid = AuthService.getUid();
    if (uid == null) return;
    await _db
        .collection('users').doc(uid)
        .collection('notifications')
        .add({
      'title'    : title,
      'body'     : body,
      'icon'     : '🔔',
      'read'     : false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}