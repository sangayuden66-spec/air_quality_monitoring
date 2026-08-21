import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import '../../main.dart'; // Import to access navigatorKey
import '../../firebase_options.dart';
import '../../features/alerts/screens/alerts_screen.dart';

/// Mandatory top-level function for background FCM handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _saveIncomingAlertToHistoryForCurrentUser(message);
  debugPrint('Handling background message: ${message.messageId}');
}

Future<bool> _saveIncomingAlertToHistoryForCurrentUser(
  RemoteMessage message,
) async {
  try {
    final data = message.data;
    final targetUid = await _resolveTargetUid(message);
    if (targetUid == null || targetUid.isEmpty) {
      debugPrint(
        'Skipping history save: no resolvable user id for incoming notification',
      );
      return false;
    }

    final normalizedType = _normalizedNotificationType(message);
    final int aqiIndex =
        int.tryParse(
          data['aqiIndex']?.toString() ??
              data['aqi_index']?.toString() ??
              data['aqi']?.toString() ??
              '',
        ) ??
        0;
    final int triggeredThreshold =
        int.tryParse(
          data['triggeredThreshold']?.toString() ??
              data['threshold']?.toString() ??
              '',
        ) ??
        0;

    final payload = {
      'type': normalizedType,
      'title': message.notification?.title ?? 'Air Quality Alert',
      'message': message.notification?.body ?? '',
      'aqi': aqiIndex,
      'aqiIndex': aqiIndex,
      'category':
          data['category']?.toString() ??
          (message.notification?.title ?? 'AQI Alert'),
      'threshold': triggeredThreshold,
      'triggeredThreshold': triggeredThreshold,
      'locationName':
          data['locationName']?.toString() ??
          data['location']?.toString() ??
          'Current location',
      'location':
          data['location']?.toString() ??
          data['locationName']?.toString() ??
          'Current location',
      'latitude': double.tryParse(data['latitude']?.toString() ?? '') ?? 0.0,
      'longitude': double.tryParse(data['longitude']?.toString() ?? '') ?? 0.0,
      'healthAdvice':
          data['healthAdvice']?.toString() ??
          (message.notification?.body ?? ''),
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'pollutants': {
        'pm25': double.tryParse(data['pm25']?.toString() ?? '') ?? 0.0,
        'pm10': double.tryParse(data['pm10']?.toString() ?? '') ?? 0.0,
        'co': double.tryParse(data['co']?.toString() ?? '') ?? 0.0,
        'no2': double.tryParse(data['no2']?.toString() ?? '') ?? 0.0,
        'so2': double.tryParse(data['so2']?.toString() ?? '') ?? 0.0,
        'o3': double.tryParse(data['o3']?.toString() ?? '') ?? 0.0,
      },
      'alertId': data['alertId']?.toString(),
    };

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('notificationHistory');

    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      await historyRef.doc(messageId).set(payload, SetOptions(merge: true));
    } else {
      await historyRef.add(payload);
    }
    return true;
  } catch (e) {
    debugPrint('Error saving incoming notification history: $e');
    return false;
  }
}

Future<String?> _resolveTargetUid(RemoteMessage message) async {
  final data = message.data;
  final fromPayload =
      (data['uid'] ??
              data['userId'] ??
              data['user_id'] ??
              data['targetUid'] ??
              data['targetUserId'] ??
              data['recipientUid'] ??
              data['recipientId'])
          ?.toString();
  if (fromPayload != null && fromPayload.isNotEmpty) {
    return fromPayload;
  }

  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId != null && currentUserId.isNotEmpty) {
    return currentUserId;
  }

  try {
    final restoredUser = await FirebaseAuth.instance
        .authStateChanges()
        .where((user) => user != null)
        .map((user) => user!.uid)
        .first
        .timeout(const Duration(seconds: 2));
    if (restoredUser.isNotEmpty) {
      return restoredUser;
    }
  } catch (_) {
    // No restorable auth user within timeout.
  }

  return FirebaseAuth.instance.currentUser?.uid;
}

String _rawNotificationType(RemoteMessage message) {
  final raw = (message.data['type'] ?? '').toString().toLowerCase();
  if (raw.isNotEmpty) return raw;

  final category = (message.data['category'] ?? '').toString().toLowerCase();
  final title = (message.notification?.title ?? '').toLowerCase();
  if (category.contains('health') || title.contains('health')) return 'health';
  if (category.contains('summary') || title.contains('summary')) {
    return 'summary';
  }
  return 'aqi_alert';
}

String _normalizedNotificationType(RemoteMessage message) {
  final type = _rawNotificationType(message);
  if (type.contains('summary')) return 'summary';
  if (type.contains('health')) return 'healthAdvice';
  return 'airQualityAlert';
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _localNotifications = NotificationService();
  final List<RemoteMessage> _pendingMessagesForSave = [];

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
        await _flushPendingMessagesForSave();
      }
    });

    // 4. Listen for token refreshes
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM Foreground: ${message.notification?.title}');
      await _saveIncomingAlertToHistory(message);

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

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('Notification tapped with data: ${message.data}');
    await _saveIncomingAlertToHistory(message);
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
  }

  Future<void> _saveIncomingAlertToHistory(RemoteMessage message) async {
    final saved = await _saveIncomingAlertToHistoryForCurrentUser(message);
    if (!saved) {
      _queuePendingMessageForSave(message);
    }
  }

  void _queuePendingMessageForSave(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      final alreadyQueued = _pendingMessagesForSave.any(
        (queued) => queued.messageId == messageId,
      );
      if (alreadyQueued) return;
    }
    _pendingMessagesForSave.add(message);
  }

  Future<void> _flushPendingMessagesForSave() async {
    if (_pendingMessagesForSave.isEmpty) return;

    final remaining = <RemoteMessage>[];
    for (final pending in _pendingMessagesForSave) {
      final saved = await _saveIncomingAlertToHistoryForCurrentUser(pending);
      if (!saved) {
        remaining.add(pending);
      }
    }

    _pendingMessagesForSave
      ..clear()
      ..addAll(remaining);
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
