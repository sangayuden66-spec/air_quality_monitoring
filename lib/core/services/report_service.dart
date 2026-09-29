import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/report_item.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');

  /// Fetches a stream of active/visible reports for regular users
  Stream<List<ReportItem>> getReportsStream() {
    return _reportsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReportItem.fromFirestore(doc))
              .where((report) =>
                  report.visibility == 'visible' &&
                  report.status != 'hidden' &&
                  report.moderationStatus != 'rejected')
              .toList();
        });
  }

  /// Submits a new report with timeout and user name fallback
  Future<void> submitReport({
    required String location,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in. Please restart the app.');

    try {
      // 1. Get user name from Firestore profile (fallback to Auth or 'Anonymous')
      String name = 'User';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (userDoc.exists) {
          name = userDoc.data()?['displayName'] ?? 'User';
        } else {
          name = user.displayName ?? 'User';
        }
      } catch (e) {
        name = user.displayName ?? 'User';
      }

      // 2. Prepare initials
      final initials = name.trim().isEmpty
          ? '?'
          : name
                .split(' ')
                .where((s) => s.isNotEmpty)
                .map((s) => s[0])
                .take(2)
                .join()
                .toUpperCase();

      final newReport = ReportItem(
        id: '',
        userId: user.uid,
        user: name,
        initials: initials,
        location: location,
        text: text,
        createdAt: DateTime.now(),
        confirmedBy: [],
        deniedBy: [],
        status: 'pending',
        visibility: 'visible',
        moderationStatus: 'pending',
        severity: 'medium',
      );

      // 3. Add to Firestore with timeout
      await _reportsCollection
          .add(newReport.toMap())
          .timeout(const Duration(seconds: 10));
      debugPrint('Firestore: Report submitted successfully');
    } catch (e) {
      debugPrint('Firestore Error: $e');
      if (e.toString().contains('permission-denied')) {
        throw Exception(
          'Database permission denied. Check your Firestore rules.',
        );
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Submission timed out. Please check your internet.');
      }
      rethrow;
    }
  }

  /// Confirms (upvotes) a report. Toggles if already confirmed.
  Future<void> confirmReport(ReportItem report) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isConfirmed = report.confirmedBy.contains(user.uid);

    try {
      if (isConfirmed) {
        await _reportsCollection.doc(report.id).update({
          'confirmedBy': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await _reportsCollection.doc(report.id).update({
          'confirmedBy': FieldValue.arrayUnion([user.uid]),
          'deniedBy': FieldValue.arrayRemove([user.uid]),
        });
      }
    } catch (e) {
      debugPrint('Error confirming report: $e');
      rethrow;
    }
  }

  /// Denies (downvotes) a report. Toggles if already denied.
  Future<void> denyReport(ReportItem report) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isDenied = report.deniedBy.contains(user.uid);

    try {
      if (isDenied) {
        await _reportsCollection.doc(report.id).update({
          'deniedBy': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await _reportsCollection.doc(report.id).update({
          'deniedBy': FieldValue.arrayUnion([user.uid]),
          'confirmedBy': FieldValue.arrayRemove([user.uid]),
        });
      }
    } catch (e) {
      debugPrint('Error denying report: $e');
      rethrow;
    }
  }
}
