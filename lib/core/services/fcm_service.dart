import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import '../../main.dart'; // Import to access navigatorKey

/// Mandatory top-level function for background FCM handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background processing if needed
  debugPrint('Handling background message: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _localNotifications = NotificationService();

  Future<void> init() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions (especially for Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted FCM permission');
    }

    // 3. Sync token immediately and whenever auth state changes
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      }
    });

    // 4. Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground: ${message.notification?.title}');
      
      if (message.notification != null) {
        _localNotifications.showRawNotification(
          title: message.notification!.title ?? 'Air Quality Alert',
          body: message.notification!.body ?? '',
          payload: message.data['type'] ?? 'aqi_alert',
        );
      }
    });

    // 6. Handle notification taps (Background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Handle notification taps (Terminated state)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped with data: ${message.data}');
    final type = message.data['type'];
    
    if (type == 'aqi_alert' || type == 'aqi_dashboard') {
      // Use the global navigatorKey to return to home/dashboard
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(token)
          .set({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM Token synced to Firestore for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> deleteToken() async {
    String? token = await _messaging.getToken();
    final user = _auth.currentUser;
    if (token != null && user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(token)
          .delete();
    }
    await _messaging.deleteToken();
  }
}
