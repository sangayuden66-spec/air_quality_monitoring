import 'support_ticket.dart';
import 'system_task.dart';
import 'system_alert_item.dart';

class ItDashboardSnapshot {
  final double systemUptimePercent;
  final String uptimeDeltaLabel; // e.g. "+0.2%"
  final int openTicketsCount;
  final String openTicketsDeltaLabel; // e.g. "-3"
  final String systemHealthLabel; // e.g. "Good"
  final String systemHealthBadge; // e.g. "Stable"
  final List<SupportTicket> tickets;
  final List<SystemTask> tasks;
  final List<SystemAlertItem> alerts;

  const ItDashboardSnapshot({
    required this.systemUptimePercent,
    required this.uptimeDeltaLabel,
    required this.openTicketsCount,
    required this.openTicketsDeltaLabel,
    required this.systemHealthLabel,
    required this.systemHealthBadge,
    required this.tickets,
    required this.tasks,
    required this.alerts,
  });
}