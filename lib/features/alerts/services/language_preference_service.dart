import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/language_preference.dart';

class LanguagePreferenceService {
  LanguagePreferenceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Stream<LanguagePreference> watchPreference() {
    final uid = _uid;
    if (uid == null) return Stream.value(LanguagePreference.defaults);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('settings')
        .snapshots()
        .map((doc) => LanguagePreference.fromMap(doc.data()));
  }

  Future<void> savePreference(LanguagePreference preference) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('settings')
        .set({
          ...preference.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
