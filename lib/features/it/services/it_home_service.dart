import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/it_dashboard_snapshot.dart';
import '../models/support_ticket.dart';
import '../models/system_task.dart';
import '../models/system_alert_item.dart';

/// Feeds [ItHomeScreen] with live Firestore data.
///
/// Expected Firestore layout (create these — see it_feature/README.md for
/// the security rules to add and sample documents to seed):
///   supportTickets/{ticketId}  - requesterName, category, description,
///                                 priority (low|medium|high),
///                                 status (open|in-progress|resolved),
///                                 createdAt (Timestamp)
///   systemTasks/{taskId}       - title, subtitle,
///                                 status (scheduled|pending|completed),
///                                 createdAt (Timestamp, for ordering)
///   systemAlerts/{alertId}     - message, severity (warning|info),
///                                 createdAt (Timestamp)
///   systemStatus/current       - uptimePercent (number), uptimeDelta (string),
///                                 openTicketsDelta (string), healthLabel
///                                 (string), healthBadge (string)
class ItHomeService {
  ItHomeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Combines the four Firestore sources into one live [ItDashboardSnapshot]
  /// stream — the widget only ever depends on this one stream/type.
  Stream<ItDashboardSnapshot> watchDashboard() {
    late final StreamController<ItDashboardSnapshot> controller;

    DocumentSnapshot<Map<String, dynamic>>? statusDoc;
    List<SupportTicket> tickets = const [];
    List<SystemTask> tasks = const [];
    List<SystemAlertItem> alerts = const [];

    void emit() {
      if (controller.isClosed) return;
      final statusData = statusDoc?.data() ?? const <String, dynamic>{};
      controller.add(
        ItDashboardSnapshot(
          systemUptimePercent:
          (statusData['uptimePercent'] as num?)?.toDouble() ?? 0,
          uptimeDeltaLabel: (statusData['uptimeDelta'] as String?) ?? '',
          openTicketsCount:
          tickets.where((t) => t.status != TicketStatus.resolved).length,
          openTicketsDeltaLabel:
          (statusData['openTicketsDelta'] as String?) ?? '',
          systemHealthLabel:
          (statusData['healthLabel'] as String?) ?? 'Unknown',
          systemHealthBadge: (statusData['healthBadge'] as String?) ?? '',
          tickets: tickets,
          tasks: tasks,
          alerts: alerts,
        ),
      );
    }

    final subs = <StreamSubscription>[];

    controller = StreamController<ItDashboardSnapshot>.broadcast(
      onListen: () {
        subs.add(
          _firestore
              .doc('systemStatus/current')
              .snapshots()
              .listen((doc) {
            statusDoc = doc;
            emit();
          }),
        );

        subs.add(
          _firestore
              .collection('supportTickets')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .snapshots()
              .listen((snap) {
            tickets = snap.docs.map((doc) => SupportTicket.fromFirestore(doc)).toList();
            emit();
          }),
        );

        subs.add(
          _firestore
              .collection('systemTasks')
              .orderBy('createdAt', descending: true)
              .snapshots()
              .listen((snap) {
            tasks = snap.docs.map((doc) => SystemTask.fromFirestore(doc)).toList();
            emit();
          }),
        );

        subs.add(
          _firestore
              .collection('systemAlerts')
              .orderBy('createdAt', descending: true)
              .snapshots()
              .listen((snap) {
            alerts = snap.docs.map((doc) => SystemAlertItem.fromFirestore(doc)).toList();
            emit();
          }),
        );
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        subs.clear();
      },
    );

    return controller.stream;
  }
}