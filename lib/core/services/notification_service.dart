import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Function(String?)? onNotificationTap;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (onNotificationTap != null) {
          onNotificationTap!(response.payload);
        }
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  /// Show a detailed AQI alert with health advice (mask instructions, etc.)
  Future<void> showAqiAlert({
    required int aqi,
    required String category,
    required String advice,
    String? location,
  }) async {
    final String locationText = location != null ? ' in $location' : '';
    final String fullBody = '$advice (AQI Index: $aqi)';

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'aqi_alerts_channel',
      'Air Quality Alerts',
      channelDescription: 'Notifications for high AQI levels',
      importance: Importance.max,
      priority: Priority.high,
      // Use BigTextStyle to ensure instructions aren't cut off
      styleInformation: BigTextStyleInformation(
        fullBody,
        contentTitle: 'AQI Alert: $category$locationText',
        summaryText: 'Health Advisory',
      ),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID to prevent overwriting
      'AQI Alert: $category$locationText',
      fullBody,
      platformChannelSpecifics,
      payload: 'aqi_dashboard',
    );
  }

  /// Used for foreground FCM messages
  Future<void> showRawNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fcm_alerts_channel',
      'General Alerts',
      channelDescription: 'Air quality monitoring alerts',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecond + 100,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
