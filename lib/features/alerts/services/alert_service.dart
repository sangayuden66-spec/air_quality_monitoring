import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/air_quality_model.dart';
import '../models/air_quality_alert.dart';
import 'alert_preference_service.dart';

class AlertTriggerDecision {
  final bool shouldNotify;
  final String title;
  final String message;
  final String locationName;

  const AlertTriggerDecision({
    required this.shouldNotify,
    required this.title,
    required this.message,
    required this.locationName,
  });
}

class AlertService {
  AlertService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  static const Duration _cooldown = Duration(hours: 3);

  String? get _userId => _auth.currentUser?.uid;

  /// Fetches real-time alert history from the notificationHistory collection.
  Stream<List<AirQualityAlert>> getAlertsStream() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationHistory')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AirQualityAlert.fromFirestore(doc))
              .toList();
        });
  }

  /// Evaluates threshold/cooldown rules and atomically creates one history record when triggered.
  Future<AlertTriggerDecision> processTriggeredAlert({
    required AirQualityModel data,
  }) async {
    final userId = _userId;
    if (userId == null) {
      return const AlertTriggerDecision(
        shouldNotify: false,
        title: '',
        message: '',
        locationName: '',
      );
    }

    final alertRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('alerts')
        .doc('default_alert');
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationHistory');

    String? title;
    String? message;
    String? locationName;
    bool shouldNotify = false;

    await _firestore.runTransaction((transaction) async {
      final alertSnap = await transaction.get(alertRef);
      if (!alertSnap.exists) return;

      final pref = AlertPreference.fromFirestore(alertSnap);
      if (!pref.enabled) return;
      if (data.aqiIndex < pref.threshold) return;

      final now = DateTime.now();
      final lastNotifiedAt = pref.lastNotifiedAt;
      final lastNotifiedAqi = pref.lastNotifiedAqi;
      final cooldownElapsed =
          lastNotifiedAt == null || now.difference(lastNotifiedAt) >= _cooldown;
      final categoryIncreased =
          lastNotifiedAqi == null || data.aqiIndex > lastNotifiedAqi;

      if (!cooldownElapsed && !categoryIncreased) return;

      shouldNotify = true;
      locationName = pref.locationName;
      title = 'AQI Alert: ${data.aqiCategory}';
      message = data.healthAdvice;

      final type = data.aqiIndex >= 4 ? 'airQualityAlert' : 'healthAdvice';
      final notificationDocId = historyRef.doc().id;
      final payload = {
        'type': type,
        'title': title,
        'message': message,
        'aqi': data.aqiIndex,
        'category': data.aqiCategory,
        'threshold': pref.threshold,
        'locationName': pref.locationName,
        'latitude': pref.latitude,
        'longitude': pref.longitude,
        'healthAdvice': data.healthAdvice,
        'pollutants': {
          'pm25': data.pm25,
          'pm10': data.pm10,
          'co': data.co,
          'no2': data.no2,
          'so2': data.so2,
          'o3': data.o3,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'alertId': alertSnap.id,
        // Backward-compatibility fields for older parsers
        'aqiIndex': data.aqiIndex,
        'location': pref.locationName,
        'triggeredThreshold': pref.threshold,
        'timestamp': FieldValue.serverTimestamp(),
      };

      transaction.set(historyRef.doc(notificationDocId), payload);
      transaction.update(alertRef, {
        'lastNotifiedAqi': data.aqiIndex,
        'lastNotifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return AlertTriggerDecision(
      shouldNotify: shouldNotify,
      title: title ?? '',
      message: message ?? '',
      locationName: locationName ?? '',
    );
  }

  Stream<int> getUnreadCount() {
    final userId = _userId;
    if (userId == null) return Stream.value(0);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationHistory')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationHistory')
        .doc(id)
        .update({'isRead': true});
  }
}
