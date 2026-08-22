import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/report_item.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_home_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminHomeService _service = AdminHomeService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<UserModel>>(
        stream: _service.watchUsers(),
        builder: (context, usersSnapshot) {
          return StreamBuilder<List<ReportItem>>(
            stream: _service.watchReports(),
            builder: (context, reportsSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting ||
                  reportsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final usersError = usersSnapshot.error?.toString();
              final reportsError = reportsSnapshot.error?.toString();
              if (usersError != null || reportsError != null) {
                final errorMessage =
                    usersError ?? reportsError ?? 'Unknown error';
                final isPermissionError = errorMessage.toLowerCase().contains(
                  'permission-denied',
                );
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPermissionError
                              ? Icons.lock_outline
                              : Icons.error_outline,
                          size: 40,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPermissionError
                              ? 'You do not have permission to view admin data.'
                              : 'Failed to load admin data: $errorMessage',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final users = usersSnapshot.data ?? const <UserModel>[];
              final reports = reportsSnapshot.data ?? const <ReportItem>[];

              if (users.isEmpty && reports.isEmpty) {
                return const Center(child: Text('No admin data found yet.'));
              }

              final visibleReports = reports
                  .where((r) => r.visibility != 'hidden')
                  .toList(growable: false);
              final pendingReports = reports
                  .where((r) => r.moderationStatus == 'pending')
                  .toList(growable: false);

              final filteredPending = _filterPendingReports(
                pendingReports,
                users,
                _query,
              );
              final filteredRecentUsers = _filterRecentUsers(users, _query);

              return Container(
                color: AppThemeColors.background,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Admin Access',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Overview of users and report moderation',
                      style: TextStyle(color: AppThemeColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search users, reports and locations',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Users',
                            value: users.length.toString(),
                            icon: Icons.people_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'Visible Reports',
                            value: visibleReports.length.toString(),
                            icon: Icons.visibility_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'Pending Reviews',
                            value: pendingReports.length.toString(),
                            icon: Icons.pending_actions_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Pending Reports',
                      subtitle: 'Preview of reports requiring moderation',
                      child: filteredPending.isEmpty
                          ? const Text('No pending reports found.')
                          : Column(
                              children: filteredPending
                                  .take(4)
                                  .map(
                                    (report) => _PendingReportTile(
                                      report: report,
                                      reporterName: _reporterName(
                                        report,
                                        users,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Recent Users',
                      subtitle: 'Latest registered users',
                      child: filteredRecentUsers.isEmpty
                          ? const Text('No users match your search.')
                          : Column(
                              children: filteredRecentUsers
                                  .take(4)
                                  .map((user) => _RecentUserTile(user: user))
                                  .toList(growable: false),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<ReportItem> _filterPendingReports(
    List<ReportItem> reports,
    List<UserModel> users,
    String query,
  ) {
    if (query.isEmpty) return reports;
    final q = query.toLowerCase();
    final usersById = {for (final user in users) user.uid: user};
    return reports
        .where((report) {
          final user = usersById[report.userId];
          final userName = _displayNameOrEmail(user).toLowerCase();
          return report.location.toLowerCase().contains(q) ||
              report.text.toLowerCase().contains(q) ||
              report.severity.toLowerCase().contains(q) ||
              report.status.toLowerCase().contains(q) ||
              userName.contains(q);
        })
        .toList(growable: false);
  }

  List<UserModel> _filterRecentUsers(List<UserModel> users, String query) {
    if (query.isEmpty) return users;
    final q = query.toLowerCase();
    return users
        .where((user) {
          final display = _displayNameOrEmail(user).toLowerCase();
          return display.contains(q) || user.email.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String _displayNameOrEmail(UserModel? user) {
    if (user == null) return 'Unknown user';
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return user.email;
  }

  String _reporterName(ReportItem report, List<UserModel> users) {
    final fromReport = report.user.trim();
    if (fromReport.isNotEmpty &&
        fromReport.toLowerCase() != 'unknown' &&
        fromReport != report.userId) {
      return fromReport;
    }
    final user = users.cast<UserModel?>().firstWhere(
      (entry) => entry?.uid == report.userId,
      orElse: () => null,
    );
    return _displayNameOrEmail(user);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppThemeColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppThemeColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PendingReportTile extends StatelessWidget {
  const _PendingReportTile({required this.report, required this.reporterName});

  final ReportItem report;
  final String reporterName;

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat(
      'MMM d, h:mm a',
    ).format(report.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeColors.surface,
          border: Border.all(color: AppThemeColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reporterName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _pill(report.severity.toUpperCase()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              report.location,
              style: const TextStyle(
                color: AppThemeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              report.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppThemeColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Status: ${report.status} • $timestamp',
              style: const TextStyle(
                color: AppThemeColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1D4ED8),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RecentUserTile extends StatelessWidget {
  const _RecentUserTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : user.email;
    final joined = user.createdAt != null
        ? DateFormat('MMM d, yyyy').format(user.createdAt!.toLocal())
        : 'Unknown join date';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppThemeColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  user.email,
                  style: const TextStyle(color: AppThemeColors.textSecondary),
                ),
                Text(
                  'Joined: $joined',
                  style: const TextStyle(
                    color: AppThemeColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
