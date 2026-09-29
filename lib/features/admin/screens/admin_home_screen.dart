import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/report_item.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_home_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    super.key,
    this.onViewAllReports,
    this.onViewAllUsers,
  });

  final VoidCallback? onViewAllReports;
  final VoidCallback? onViewAllUsers;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminHomeService _service = AdminHomeService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Brand Palette: Blue, Black, Green
  static const Color kDeepBlue = Color(0xFF001A3F); // From logo
  static const Color kCyanBlue = Color(0xFF00B2FF); // From logo
  static const Color kLogoGreen = Color(0xFF00E676); // From logo
  static const Color kPureBlack = Color(0xFF000000);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: _service.watchUsers(),
          builder: (context, usersSnapshot) {
            return StreamBuilder<List<ReportItem>>(
              stream: _service.watchReports(),
              builder: (context, reportsSnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _service.watchAdminNotifications(),
                  builder: (context, notifySnapshot) {
                    if (usersSnapshot.connectionState == ConnectionState.waiting ||
                        reportsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kCyanBlue));
                    }

                    final users = usersSnapshot.data ?? const <UserModel>[];
                    final reports = reportsSnapshot.data ?? const <ReportItem>[];
                    final notifications = notifySnapshot.data ?? const [];

                    final visibleReports = reports
                        .where((r) => r.visibility != 'hidden')
                        .toList(growable: false);
                    final pendingReports = reports
                        .where((r) => r.moderationStatus == 'pending')
                        .toList(growable: false);

                    final filteredPending = _filterPendingReports(pendingReports, users, _query);
                    final filteredRecentUsers = _filterRecentUsers(users, _query);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _Header(),
                        const SizedBox(height: 16),
                        if (notifications.isNotEmpty) ...[
                          _EscalationSection(
                            notifications: notifications,
                            onMarkRead: (id) => _service.markNotificationAsRead(id),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _SearchBar(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: 16),
                        _StatsGrid(
                          totalUsers: users.length,
                          activeReports: visibleReports.length,
                          pendingReviews: pendingReports.length,
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: 'Pending Moderation',
                          onViewAll: widget.onViewAllReports,
                        ),
                        const SizedBox(height: 12),
                        if (filteredPending.isEmpty)
                          const _EmptyState(text: 'All reports have been reviewed.')
                        else
                          ...filteredPending.take(3).map((report) => _ReportPreviewTile(
                                report: report,
                                reporterName: _reporterName(report, users),
                              )),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: 'User Management',
                          onViewAll: widget.onViewAllUsers,
                        ),
                        const SizedBox(height: 12),
                        _RecentUsersSection(users: filteredRecentUsers.take(4).toList()),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<ReportItem> _filterPendingReports(List<ReportItem> reports, List<UserModel> users, String query) {
    if (query.isEmpty) return reports;
    final q = query.toLowerCase();
    return reports.where((r) => r.location.toLowerCase().contains(q) || r.text.toLowerCase().contains(q)).toList();
  }

  List<UserModel> _filterRecentUsers(List<UserModel> users, String query) {
    if (query.isEmpty) return users;
    final q = query.toLowerCase();
    return users.where((u) => (u.displayName ?? '').toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
  }

  String _reporterName(ReportItem report, List<UserModel> users) {
    final user = users.cast<UserModel?>().firstWhere(
      (u) => u?.uid == report.userId, 
      orElse: () => null
    );
    if (user == null) return 'Unknown';
    return (user.displayName?.isNotEmpty == true) ? user.displayName! : user.email;
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF001A3F), // Deep Navy from Logo
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00B2FF).withOpacity(0.3)),
          ),
          child: const Text(
            'Admin Portal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppThemeColors.border),
          ),
          child: const Center(
            child: Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF001A3F)),
          ),
        ),
      ],
    );
  }
}

class _EscalationSection extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Function(String) onMarkRead;

  const _EscalationSection({required this.notifications, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.priority_high_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Priority Escalations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${notifications.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...notifications.take(3).map((n) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n['title'] ?? 'Escalation',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001A3F)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n['message'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppThemeColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By: ${n['createdByName'] ?? 'IT Staff'}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00B2FF)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => onMarkRead(n['id']),
                tooltip: 'Mark as read',
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Color(0xFF001A3F)),
          hintText: 'Search database, users, reports...',
          hintStyle: TextStyle(color: AppThemeColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalUsers;
  final int activeReports;
  final int pendingReviews;

  const _StatsGrid({
    required this.totalUsers,
    required this.activeReports,
    required this.pendingReviews,
  });

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
          icon: Icons.group_rounded,
          iconColor: const Color(0xFF00B2FF), // Cyan Blue
          iconBackground: const Color(0xFF00B2FF).withOpacity(0.1),
          label: 'Total Users',
          value: totalUsers.toString(),
        ),
        _StatCard(
          icon: Icons.fact_check_rounded,
          iconColor: const Color(0xFF00E676), // Logo Green
          iconBackground: const Color(0xFF00E676).withOpacity(0.1),
          label: 'Live Reports',
          value: activeReports.toString(),
        ),
        _StatCard(
          icon: Icons.rule_rounded,
          iconColor: const Color(0xFFEA580C),
          iconBackground: const Color(0xFFFFF1E6),
          label: 'In Review',
          value: pendingReviews.toString(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF00B2FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportPreviewTile extends StatelessWidget {
  final ReportItem report;
  final String reporterName;

  const _ReportPreviewTile({required this.report, required this.reporterName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reporterName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              _Badge(text: report.moderationStatus, color: const Color(0xFF00B2FF)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppThemeColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                report.location,
                style: const TextStyle(color: AppThemeColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(report.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            DateFormat('h:mm a').format(report.createdAt),
            style: const TextStyle(fontSize: 11, color: AppThemeColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersSection extends StatelessWidget {
  final List<UserModel> users;

  const _RecentUsersSection({required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        children: users.map((user) {
          final name = user.displayName?.trim().isNotEmpty == true 
              ? user.displayName!.trim() 
              : user.email.split('@').first;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF001A3F),
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Color(0xFF00B2FF), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(user.email, style: const TextStyle(fontSize: 11, color: AppThemeColors.textSecondary)),
                    ],
                  ),
                ),
                _Badge(text: user.role, color: user.role == 'admin' ? const Color(0xFF00B2FF) : Colors.grey),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(text, style: const TextStyle(color: AppThemeColors.textSecondary)),
    ));
  }
}
