import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SystemTaskStatus { scheduled, pending, completed }

class SystemTask {
  final String id;
  final String title;
  final String subtitle;
  final SystemTaskStatus status;

  const SystemTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  factory SystemTask.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();
    return SystemTask(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      status: _parseStatus(data['status']),
    );
  }

  static SystemTaskStatus _parseStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'completed':
        return SystemTaskStatus.completed;
      case 'pending':
        return SystemTaskStatus.pending;
      default:
        return SystemTaskStatus.scheduled;
    }
  }

  IconData get icon {
    switch (status) {
      case SystemTaskStatus.scheduled:
        return Icons.access_time_rounded;
      case SystemTaskStatus.pending:
        return Icons.warning_amber_rounded;
      case SystemTaskStatus.completed:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color get iconColor {
    switch (status) {
      case SystemTaskStatus.scheduled:
        return const Color(0xFF2D7EF7);
      case SystemTaskStatus.pending:
        return const Color(0xFFEA580C);
      case SystemTaskStatus.completed:
        return const Color(0xFF16A34A);
    }
  }

  String get statusLabel {
    switch (status) {
      case SystemTaskStatus.scheduled:
        return 'scheduled';
      case SystemTaskStatus.pending:
        return 'pending';
      case SystemTaskStatus.completed:
        return 'completed';
    }
  }

  bool get isFilledStatusBadge => status == SystemTaskStatus.completed;
}