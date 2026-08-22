import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SystemAlertSeverity { warning, info }

class SystemAlertItem {
  final String id;
  final String message;
  final DateTime createdAt;
  final SystemAlertSeverity severity;

  const SystemAlertItem({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.severity,
  });

  factory SystemAlertItem.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();
    return SystemAlertItem(
      id: doc.id,
      message: (data['message'] as String?) ?? '',
      createdAt:
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      severity: (data['severity']?.toString().toLowerCase() == 'info')
          ? SystemAlertSeverity.info
          : SystemAlertSeverity.warning,
    );
  }

  Color get background {
    switch (severity) {
      case SystemAlertSeverity.warning:
        return const Color(0xFFFFF3E0);
      case SystemAlertSeverity.info:
        return const Color(0xFFE7F0FE);
    }
  }

  Color get border {
    switch (severity) {
      case SystemAlertSeverity.warning:
        return const Color(0xFFFCD9A8);
      case SystemAlertSeverity.info:
        return const Color(0xFFBFDBFE);
    }
  }

  String get timeAgo {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return '${duration.inDays} days ago';
  }
}