import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/air_quality_model.dart';
import '../models/air_quality_alert.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Fetches real-time alert history from the notificationHistory collection
  Stream<List<AirQualityAlert>> getAlertsStream() {
    final userId = _userId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notificationHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AirQualityAlert.fromFirestore(doc))
          .toList();
    });
  }

  /// Saves a triggered alert record to Firestore for the user's history.
  Future<void> saveTriggeredAlert({
    required AirQualityModel data,
    required String locationName,
    required int threshold,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final historyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notificationHistory');

      // Prevent duplicate logs for the same level within 15 minutes
      final recent = await historyRef
          .where('location', isEqualTo: locationName)
          .where('aqiIndex', isEqualTo: data.aqiIndex)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 15))))
          .limit(1)
          .get();

      if (recent.docs.isEmpty) {
        await historyRef.add({
          'aqi': data.aqi,
          'aqiIndex': data.aqiIndex,
          'category': data.aqiCategory,
          'healthAdvice': data.healthAdvice,
          'location': locationName,
          'triggeredThreshold': threshold,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'alert',
          'pollutants': {
            'pm25': data.pm25,
            'pm10': data.pm10,
            'co': data.co,
            'no2': data.no2,
            'so2': data.so2,
            'o3': data.o3,
          },
        });
      }
    } catch (e) {
      print('Error logging alert history: $e');
    }
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
