import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report.dart';

class ReportService {
  ReportService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  CollectionReference<Map<String, dynamic>> get _confirmations =>
      _db.collection('report_confirmations');

  Future<void> submitReport({
    required String userId,
    required String userName,
    required String locationName,
    required String pollutantType,
    required String description,
  }) async {
    final errors = validateReport(
      locationName: locationName,
      pollutantType: pollutantType,
      description: description,
    );
    if (errors.isNotEmpty) {
      throw ReportValidationException(errors.first);
    }

    final report = Report(
      id: '',
      userId: userId,
      userName: userName,
      locationName: locationName.trim(),
      pollutantType: pollutantType,
      description: description.trim(),
      status: 'pending',
      confirmCount: 0,
      denyCount: 0,
      submittedAt: DateTime.now(),
    );

    await _reports.add(report.toMap());
  }

  Stream<List<Report>> watchReports({int limit = 50}) {
    return _reports
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Report>> watchReportsByLocation(String locationName) {
    return _reports
        .where('locationName', isEqualTo: locationName)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Report.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<Report?> getReportById(String reportId) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists) return null;
    return Report.fromMap(doc.id, doc.data()!);
  }

  Future<void> voteOnReport({
    required String reportId,
    required String userId,
    required String type,
  }) async {
    if (type != 'confirm' && type != 'deny') {
      throw ReportValidationException('Vote type must be confirm or deny.');
    }

    final existingVote = await _confirmations
        .where('reportId', isEqualTo: reportId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existingVote.docs.isNotEmpty) {
      throw ReportValidationException(
          'You have already responded to this report.');
    }

    await _db.runTransaction((transaction) async {
      final reportRef = _reports.doc(reportId);
      final reportSnap = await transaction.get(reportRef);
      if (!reportSnap.exists) {
        throw ReportValidationException('This report no longer exists.');
      }

      final confirmationRef = _confirmations.doc();
      transaction.set(
        confirmationRef,
        ReportConfirmation(
          id: confirmationRef.id,
          reportId: reportId,
          userId: userId,
          type: type,
          confirmedAt: DateTime.now(),
        ).toMap(),
      );

      final field = type == 'confirm' ? 'confirmCount' : 'denyCount';
      transaction.update(reportRef, {
        field: FieldValue.increment(1),
      });
    });
  }

  Future<bool> hasUserVoted(String reportId, String userId) async {
    final existing = await _confirmations
        .where('reportId', isEqualTo: reportId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return existing.docs.isNotEmpty;
  }

  static const List<String> pollutantTypes = [
    'Smoke',
    'Dust',
    'Chemical Odour',
    'Vehicle Exhaust',
    'Other',
  ];

  List<String> validateReport({
    required String locationName,
    required String pollutantType,
    required String description,
  }) {
    final errors = <String>[];

    if (locationName.trim().isEmpty) {
      errors.add('Please provide a location for this report.');
    }

    if (!pollutantTypes.contains(pollutantType)) {
      errors.add('Please select a valid pollutant type.');
    }

    final desc = description.trim();
    if (desc.isEmpty) {
      errors.add('Please describe what you observed.');
    } else if (desc.length < 10) {
      errors.add('Description is too short (minimum 10 characters).');
    } else if (desc.length > 500) {
      errors.add('Description is too long (maximum 500 characters).');
    }

    return errors;
  }
}

class ReportValidationException implements Exception {
  final String message;
  ReportValidationException(this.message);

  @override
  String toString() => message;
}