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
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: AppThemeColors.textPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search users, reports, locations...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
                            trend: '+12.5%',
                            trendColor: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: 'Active Reports',
                            value: visibleReports.length.toString(),
                            icon: Icons.chat_bubble_outline,
                            trend: '+8.2%',
                            trendColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Pending Reviews',
                            value: pendingReports.length.toString(),
                            icon: Icons.warning_amber_rounded,
                            trend: '-5.1%',
                            trendColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Pending Reports',
                      viewAll: true,
                      child: filteredPending.isEmpty
                          ? const Text('No pending reports found.')
                          : Column(
                              children: filteredPending
                                  .take(3)
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
                    _RecentUsersCard(users: filteredRecentUsers.take(4).toList()),
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
    required this.trend,
    required this.trendColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final Color trendColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EAF6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppThemeColors.textPrimary, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppThemeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.viewAll = false,
  });

  final String title;
  final Widget child;
  final bool viewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (viewAll)
                const Text(
                  'View All',
                  style: TextStyle(
                    color: AppThemeColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
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
    final timestamp = DateFormat('MMM d, h:mm a').format(report.createdAt.toLocal());
    final isPending = report.moderationStatus == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppThemeColors.surface,
          border: Border.all(color: AppThemeColors.border),
          borderRadius: BorderRadius.circular(14),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFFE6F9EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPending ? 'pending' : 'approved',
                    style: TextStyle(
                      color: isPending
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF16A34A),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: AppThemeColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(
                      color: AppThemeColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppThemeColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timestamp,
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
}

class _RecentUsersCard extends StatelessWidget {
  const _RecentUsersCard({required this.users});

  final List<UserModel> users;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Recent Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const Text(
                'View All',
                style: TextStyle(
                  color: AppThemeColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (users.isEmpty)
            const Text('No users found.')
          else ...[
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Email',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Join',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...users.map((user) {
              final displayName = user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : user.email.split('@').first;
              final joinedText = user.createdAt != null
                  ? '${DateTime.now().difference(user.createdAt!).inHours}h ago'
                  : '—';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: Text(
                        (displayName.isEmpty ? user.email : displayName)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF1F3C88),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        user.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppThemeColors.textSecondary),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        joinedText,
                        style: const TextStyle(
                          color: AppThemeColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

