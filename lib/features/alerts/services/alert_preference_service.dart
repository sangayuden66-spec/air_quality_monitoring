import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertPreference {
  final String id;
  final int threshold;
  final bool enabled;
  final String locationName;
  final double latitude;
  final double longitude;

  AlertPreference({
    required this.id,
    required this.threshold,
    required this.enabled,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'threshold': threshold,
      'enabled': enabled,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AlertPreference.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertPreference(
      id: doc.id,
      threshold: data['threshold'] ?? 100,
      enabled: data['enabled'] ?? true,
      locationName: data['locationName'] ?? 'Selected Location',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
    );
  }
}

class AlertPreferenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Saves or updates an alert preference for the current user.
  Future<void> saveAlertPreference(AlertPreference pref) async {
    if (_uid == null) return;
    
    final docRef = _firestore.collection('users').doc(_uid).collection('alerts').doc('default_alert');
    
    await docRef.set({
      ...pref.toMap(),
      if (pref.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams the user's current alert preference.
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
}
