import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertPreference {
  final String id;
  final bool enabled;
  final int threshold; // 1 to 5 (OpenWeather scale)
  final double latitude;
  final double longitude;
  final String locationName;
  final int? lastNotifiedAqi;
  final DateTime? lastNotifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AlertPreference({
    required this.id,
    required this.enabled,
    required this.threshold,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.lastNotifiedAqi,
    this.lastNotifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'threshold': threshold,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'lastNotifiedAqi': lastNotifiedAqi,
      'lastNotifiedAt': lastNotifiedAt != null
          ? Timestamp.fromDate(lastNotifiedAt!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AlertPreference.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    int threshold = (data['threshold'] as num?)?.toInt() ?? 3;

    // Migration: If the threshold is from the old 0-500 scale, reset it to default (Moderate)
    if (threshold > 5) threshold = 3;

    return AlertPreference(
      id: doc.id,
      enabled: data['enabled'] ?? true,
      threshold: threshold,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: data['locationName'] ?? 'Selected Location',
      lastNotifiedAqi: (data['lastNotifiedAqi'] as num?)?.toInt(),
      lastNotifiedAt: (data['lastNotifiedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AlertPreferenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> saveAlertPreference(AlertPreference pref) async {
    if (_uid == null) throw Exception('User not authenticated');

    if (pref.threshold < 1 || pref.threshold > 5) {
      throw Exception('Threshold must be between 1 and 5');
    }

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('alerts')
        .doc('default_alert');

    await docRef.set(pref.toMap(), SetOptions(merge: true));
  }

  Stream<AlertPreference?> getAlertPreference() {
    if (_uid == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('alerts')
        .doc('default_alert')
        .snapshots()
        .map((doc) => doc.exists ? AlertPreference.fromFirestore(doc) : null);
  }

  Future<void> syncLocationWithSelection({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    if (_uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('alerts')
        .doc('default_alert');
    final existing = await docRef.get();

    final resolvedName =
        locationName ??
        'Lat ${latitude.toStringAsFixed(3)}, Lng ${longitude.toStringAsFixed(3)}';

    if (!existing.exists) {
      await docRef.set({
        'enabled': true,
        'threshold': 3,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': resolvedName,
        'lastNotifiedAqi': null,
        'lastNotifiedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final data =
        existing.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final prevLat = (data['latitude'] as num?)?.toDouble();
    final prevLon = (data['longitude'] as num?)?.toDouble();
    final locationChanged =
        prevLat == null ||
        prevLon == null ||
        (prevLat - latitude).abs() > 0.0001 ||
        (prevLon - longitude).abs() > 0.0001;

    await docRef.set({
      'latitude': latitude,
      'longitude': longitude,
      'locationName': resolvedName,
      if (locationChanged) 'lastNotifiedAqi': null,
      if (locationChanged) 'lastNotifiedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
