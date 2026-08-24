import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/it_dashboard_snapshot.dart';
import '../models/support_ticket.dart';
import '../models/system_task.dart';
import '../models/system_alert_item.dart';
import '../services/it_home_service.dart';
import '../services/it_support_service.dart';

class ItHomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllTickets;

  const ItHomeScreen({super.key, this.onViewAllTickets});

  @override
  State<ItHomeScreen> createState() => _ItHomeScreenState();
}

class _ItHomeScreenState extends State<ItHomeScreen> {
  final ItHomeService _service = ItHomeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: StreamBuilder<ItDashboardSnapshot>(
          stream: _service.watchDashboard(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _Header(onOpenSupport: widget.onViewAllTickets),
                const SizedBox(height: 16),
                _SearchBar(),
                const SizedBox(height: 16),
                _StatsGrid(data: data),
                const SizedBox(height: 20),
                _QuickActions(),
                const SizedBox(height: 20),
                _SupportTicketsSection(
                  tickets: data.tickets,
                  onViewAll: widget.onViewAllTickets,
                ),
                const SizedBox(height: 20),
                _SystemTasksSection(tasks: data.tasks),
                const SizedBox(height: 20),
                _SystemAlertsSection(alerts: data.alerts),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onOpenSupport;
  final ItSupportService _supportService = ItSupportService();

  _Header({this.onOpenSupport});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'IT Access',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        InkWell(
          onTap: onOpenSupport,
          customBorder: const CircleBorder(),
          child: StreamBuilder<int>(
            stream: _supportService.watchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppThemeColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppThemeColors.border),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppThemeColors.textPrimary,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        enabled: false,
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: AppThemeColors.textSecondary),
          hintText: 'Search tickets, users, system logs...',
          hintStyle: TextStyle(color: AppThemeColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final ItDashboardSnapshot data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _StatCard(
          icon: Icons.dns_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBackground: const Color(0xFFE7F8EF),
          badgeText: data.uptimeDeltaLabel,
          badgeFilled: true,
          label: 'System Uptime',
          value: '${data.systemUptimePercent}%',
        ),
        _StatCard(
          icon: Icons.help_outline_rounded,
          iconColor: const Color(0xFFEA580C),
          iconBackground: const Color(0xFFFFF1E6),
          badgeText: data.openTicketsDeltaLabel,
          badgeFilled: false,
          label: 'Open Tickets',
          value: '${data.openTicketsCount}',
        ),
        _StatCard(
          icon: Icons.monitor_heart_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBackground: const Color(0xFFE7F8EF),
          badgeText: data.systemHealthBadge,
          badgeFilled: true,
          label: 'System Health',
          value: data.systemHealthLabel,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String badgeText;
  final bool badgeFilled;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.badgeText,
    required this.badgeFilled,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              _Pill(text: badgeText, filled: badgeFilled),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppThemeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool filled;
  final Color? textColor;
  final Color? background;

  const _Pill({
    required this.text,
    required this.filled,
    this.textColor,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            background ??
            (filled ? AppThemeColors.textPrimary : const Color(0xFFEEF0F4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color:
              textColor ?? (filled ? Colors.white : AppThemeColors.textPrimary),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.settings_outlined, 'System Config'),
      (Icons.storage_rounded, 'Database'),
      (Icons.shield_outlined, 'Security'),
      (Icons.build_outlined, 'Maintenance'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: actions
                .map((a) => _QuickActionTile(icon: a.$1, label: a.$2))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemeColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppThemeColors.textPrimary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppThemeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketsSection extends StatelessWidget {
  final List<SupportTicket> tickets;
  final VoidCallback? onViewAll;

  const _SupportTicketsSection({required this.tickets, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: AppThemeColors.textPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Support Tickets',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppThemeColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final ticket in tickets) _TicketCard(ticket: ticket),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                ticket.requesterName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              _Pill(
                text: ticket.priorityLabel,
                filled: false,
                textColor: ticket.priorityColor,
                background: ticket.priorityBackground,
              ),
              const SizedBox(width: 6),
              _Pill(
                text: ticket.statusLabel,
                filled: ticket.isFilledStatusBadge,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ticket.category,
            style: const TextStyle(
              fontSize: 12,
              color: AppThemeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(ticket.description, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppThemeColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                ticket.timeAgo,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppThemeColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemTasksSection extends StatelessWidget {
  final List<SystemTask> tasks;

  const _SystemTasksSection({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_outlined, color: AppThemeColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'System Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final task in tasks) _TaskRow(task: task),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final SystemTask task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(task.icon, color: task.iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  task.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _Pill(text: task.statusLabel, filled: task.isFilledStatusBadge),
        ],
      ),
    );
  }
}

class _SystemAlertsSection extends StatelessWidget {
  final List<SystemAlertItem> alerts;

  const _SystemAlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppThemeColors.textPrimary,
              ),
              SizedBox(width: 8),
              Text(
                'System Alerts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final alert in alerts) _AlertBox(alert: alert),
        ],
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  final SystemAlertItem alert;

  const _AlertBox({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.background,
        border: Border.all(color: alert.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.message,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            alert.timeAgo,
            style: const TextStyle(
              fontSize: 11,
              color: AppThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
