import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/privacy_preferences.dart';

class PrivacyPreferencesService {
  PrivacyPreferencesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<PrivacyPreferences> watchPreferences() {
    final uid = _uid;
    if (uid == null) return Stream.value(PrivacyPreferences.defaults);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('privacy')
        .doc('preferences')
        .snapshots()
        .map((doc) => PrivacyPreferences.fromMap(doc.data()));
  }

  Future<void> savePreferences(PrivacyPreferences preferences) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('privacy')
        .doc('preferences')
        .set({
          ...preferences.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
