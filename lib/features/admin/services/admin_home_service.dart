import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/report_item.dart';
import '../../../core/models/user_model.dart';

class AdminHomeService {
  AdminHomeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<UserModel>> watchUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['uid'] = (data['uid'] as String?) ?? doc.id;
                data['role'] = (data['role'] as String?) ?? 'user';
                data['status'] = (data['status'] as String?) ?? 'active';
                return UserModel.fromMap(data);
              })
              .toList(growable: false);
        });
  }

  Future<void> updateUserRole({required String uid, required String role}) async {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'user' &&
        normalizedRole != 'it' &&
        normalizedRole != 'admin') {
      throw ArgumentError.value(role, 'role', 'Role must be user, it, or admin');
    }
    await _firestore.collection('users').doc(uid).set({
      'role': normalizedRole,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserStatus({required String uid, required bool disabled}) async {
    await _firestore.collection('users').doc(uid).set({
      'status': disabled ? 'disabled' : 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ReportItem>> watchReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReportItem.fromFirestore(doc))
              .toList(growable: false);
        });
  }

  Future<void> setReportVisibility({
    required String reportId,
    required bool visible,
  }) async {
    final status = visible ? 'verified' : 'hidden';
    final moderationStatus = visible ? 'approved' : 'rejected';
    await _firestore.collection('reports').doc(reportId).set({
      'visibility': visible ? 'visible' : 'hidden',
      'status': status,
      'moderationStatus': moderationStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setReportModeration({
    required String reportId,
    required bool approved,
  }) async {
    await _firestore.collection('reports').doc(reportId).set({
      'moderationStatus': approved ? 'approved' : 'rejected',
      'status': approved ? 'verified' : 'hidden',
      'visibility': approved ? 'visible' : 'hidden',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
