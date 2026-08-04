import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String userId;
  final String userName;
  final String locationName;
  final String pollutantType;
  final String description;
  final String status; // pending | verified | rejected
  final int confirmCount;
  final int denyCount;
  final DateTime submittedAt;

  const Report({
    required this.id,
    required this.userId,
    required this.userName,
    required this.locationName,
    required this.pollutantType,
    required this.description,
    required this.status,
    required this.confirmCount,
    required this.denyCount,
    required this.submittedAt,
  });

  bool get isVerified => confirmCount >= 5 && confirmCount > denyCount * 2;

  factory Report.fromMap(String id, Map<String, dynamic> data) {
    return Report(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      locationName: data['locationName'] as String? ?? 'Unknown location',
      pollutantType: data['pollutantType'] as String? ?? 'Other',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      confirmCount: (data['confirmCount'] as num?)?.toInt() ?? 0,
      denyCount: (data['denyCount'] as num?)?.toInt() ?? 0,
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'locationName': locationName,
      'pollutantType': pollutantType,
      'description': description,
      'status': status,
      'confirmCount': confirmCount,
      'denyCount': denyCount,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }
}

class ReportConfirmation {
  final String id;
  final String reportId;
  final String userId;
  final String type; // confirm | deny
  final DateTime confirmedAt;

  const ReportConfirmation({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.type,
    required this.confirmedAt,
  });

  factory ReportConfirmation.fromMap(String id, Map<String, dynamic> data) {
    return ReportConfirmation(
      id: id,
      reportId: data['reportId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? 'confirm',
      confirmedAt:
          (data['confirmedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'userId': userId,
      'type': type,
      'confirmedAt': Timestamp.fromDate(confirmedAt),
    };
  }
}