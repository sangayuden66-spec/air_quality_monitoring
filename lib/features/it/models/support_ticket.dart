import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TicketPriority { low, medium, high }

enum TicketStatus { open, inProgress, resolved }

class SupportTicket {
  final String id;
  final String requesterName;
  final String requesterEmail;
  final String subject;
  final String category;
  final String description;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.requesterName,
    required this.requesterEmail,
    required this.subject,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicket.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SupportTicket(
      id: doc.id,
      requesterName: (data['requesterName'] as String?) ?? 'Unknown',
      requesterEmail: (data['requesterEmail'] as String?) ?? '',
      subject: (data['subject'] as String?) ?? 'No subject',
      category: (data['category'] as String?) ?? 'General',
      description: (data['description'] as String?) ?? '',
      priority: _parsePriority(data['priority']),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static TicketPriority _parsePriority(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'high':
        return TicketPriority.high;
      case 'medium':
        return TicketPriority.medium;
      default:
        return TicketPriority.low;
    }
  }

  static TicketStatus _parseStatus(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'in-progress':
      case 'inprogress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      default:
        return TicketStatus.open;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF0F9D75);
      case TicketPriority.medium:
        return const Color(0xFFB45309);
      case TicketPriority.high:
        return const Color(0xFFDC2626);
    }
  }

  Color get priorityBackground {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFFE8F8F1);
      case TicketPriority.medium:
        return const Color(0xFFFFF3E0);
      case TicketPriority.high:
        return const Color(0xFFFDEDED);
    }
  }

  String get statusLabel {
    switch (status) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in-progress';
      case TicketStatus.resolved:
        return 'resolved';
    }
  }

  bool get isFilledStatusBadge => status == TicketStatus.inProgress;

  String get statusDisplayLabel {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }

  String get timeAgo {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inMinutes < 60) return '${duration.inMinutes} min ago';
    if (duration.inHours < 24) return '${duration.inHours} hours ago';
    return '${duration.inDays} days ago';
  }
}
