import 'package:flutter/material.dart';
import '../../../core/models/report_item.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/user_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../services/admin_home_service.dart';
import 'admin_home_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: _selectedIndex == 0
          ? const AdminHomeScreen()
          : _selectedIndex == 1
          ? const AdminUsersScreen()
          : _selectedIndex == 2
          ? const AdminReportsScreen()
          : const AdminSettingsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _selectedIndex = 0);
            return;
          }
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppThemeColors.primary,
        unselectedItemColor: AppThemeColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_gmailerrorred_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final AdminHomeService _service = AdminHomeService();
  String _filter = 'all';
  bool _isUpdating = false;

  Future<void> _toggleVisibility(ReportItem report) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    final shouldBeVisible = report.visibility == 'hidden';
    try {
      await _service.setReportVisibility(
        reportId: report.id,
        visible: shouldBeVisible,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shouldBeVisible
                ? 'Report is now visible to users.'
                : 'Report has been hidden.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update report: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _reviewReport(ReportItem report, bool approved) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await _service.setReportModeration(
        reportId: report.id,
        approved: approved,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Report approved and visible.'
                : 'Report rejected and hidden.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to review report: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportItem>>(
      stream: _service.watchReports(),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const <ReportItem>[];
        final visibleReports = reports
            .where((r) => r.visibility != 'hidden')
            .toList();
        final hiddenReports = reports
            .where((r) => r.visibility == 'hidden')
            .toList();
        final filteredReports = switch (_filter) {
          'visible' => visibleReports,
          'hidden' => hiddenReports,
          _ => reports,
        };

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Manage Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Admin Access',
                        style: TextStyle(
                          color: Color(0xFF3563E9),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _ReportFilterChip(
                      label: 'All',
                      count: reports.length,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _ReportFilterChip(
                      label: 'Visible',
                      count: visibleReports.length,
                      selected: _filter == 'visible',
                      onTap: () => setState(() => _filter = 'visible'),
                    ),
                    const SizedBox(width: 8),
                    _ReportFilterChip(
                      label: 'Hidden',
                      count: hiddenReports.length,
                      selected: _filter == 'hidden',
                      onTap: () => setState(() => _filter = 'hidden'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: filteredReports
                        .map(
                          (report) => _ReportCard(
                            report: report,
                            onReview: (approved) =>
                                _reviewReport(report, approved),
                            onToggleVisibility: () => _toggleVisibility(report),
                            disabled: _isUpdating,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ReportFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? Colors.white : AppThemeColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportItem report;
  final Future<void> Function(bool approved) onReview;
  final Future<void> Function() onToggleVisibility;
  final bool disabled;

  const _ReportCard({
    required this.report,
    required this.onReview,
    required this.onToggleVisibility,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = report.visibility != 'hidden';
    final statusColor = isVisible
        ? const Color(0xFF16A34A)
        : const Color(0xFFCA8A04);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFDDEBFF),
                child: Text(
                  report.initials.isNotEmpty ? report.initials : '?',
                  style: const TextStyle(
                    color: Color(0xFF1F3C88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.user,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F8EE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isVisible ? 'Visible' : 'Hidden',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppThemeColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.timeAgo,
                          style: const TextStyle(
                            color: AppThemeColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.severity.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF3563E9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.text,
            style: const TextStyle(
              color: AppThemeColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 6),
              Text(
                '${report.confirm} confirmations',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${report.deny} denials',
                style: const TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.moderationStatus,
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled
                      ? null
                      : () => onReview(report.moderationStatus != 'approved'),
                  icon: Icon(
                    report.moderationStatus == 'approved'
                        ? Icons.cancel_outlined
                        : Icons.verified_outlined,
                    size: 16,
                  ),
                  label: Text(
                    report.moderationStatus == 'approved'
                        ? 'Reject'
                        : 'Approve',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemeColors.primary,
                    side: const BorderSide(color: AppThemeColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: disabled ? null : onToggleVisibility,
                  icon: const Icon(Icons.hide_source_outlined, size: 16),
                  label: Text(isVisible ? 'Hide' : 'Show'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE67E22),
                    side: const BorderSide(color: Color(0xFFE67E22)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminHomeService _service = AdminHomeService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  UserModel? _selectedUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _service.watchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? const <UserModel>[];
        final filteredUsers = _filterUsers(users, _query);
        final selectedUser = filteredUsers.isNotEmpty
            ? (filteredUsers.contains(_selectedUser)
                  ? _selectedUser
                  : filteredUsers.first)
            : users.isNotEmpty
            ? users.first
            : null;

        if (_selectedUser == null && selectedUser != null) {
          _selectedUser = selectedUser;
        }

        final totalUsers = users.length;
        final activeUsers = users.where((u) => u.status == 'active').length;
        final disabledUsers = users.where((u) => u.status == 'disabled').length;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Manage Users',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Admin Access',
                        style: TextStyle(
                          color: Color(0xFF3563E9),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: AppThemeColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _query = value.trim()),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search users by name, email, or role...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: AppThemeColors.textSecondary,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _UsersStatTile(
                        label: 'Total Users',
                        value: totalUsers.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _UsersStatTile(
                        label: 'Active',
                        value: activeUsers.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _UsersStatTile(
                        label: 'Disabled',
                        value: disabledUsers.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 820;
                      if (!isWide) {
                        return ListView(
                          children: filteredUsers
                              .map(
                                (user) => _UserCard(
                                  user: user,
                                  isSelected: _selectedUser == user,
                                  onTap: () =>
                                      setState(() => _selectedUser = user),
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: ListView(
                              children: filteredUsers
                                  .map(
                                    (user) => _UserCard(
                                      user: user,
                                      isSelected: _selectedUser == user,
                                      onTap: () =>
                                          setState(() => _selectedUser = user),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: _UserDetailCard(user: selectedUser),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users, String query) {
    if (query.isEmpty) return users;
    final q = query.toLowerCase();
    return users.where((u) {
      final displayName = (u.displayName ?? '').toLowerCase();
      final email = (u.email).toLowerCase();
      final role = (u.role).toLowerCase();
      return displayName.contains(q) || email.contains(q) || role.contains(q);
    }).toList();
  }
}

class _UsersStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _UsersStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppThemeColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email.split('@').first;
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((v) => v[0])
              .join()
              .toUpperCase();
    final statusLabel = user.status == 'disabled' ? 'disabled' : 'active';
    final roleLabel = user.role.toLowerCase();
    final isAdmin = roleLabel == 'admin';
    final isIT = roleLabel == 'it';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7F9FF) : AppThemeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppThemeColors.primary
                : const Color(0xFFE1E7F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF1F3C88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusLabel == 'disabled'
                                  ? const Color(0xFFF3F4F6)
                                  : const Color(0xFFE7F7EE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusLabel == 'disabled'
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF149F5C),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
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
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFF1E8FF)
                        : isIT
                        ? const Color(0xFFDBF4FF)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(
                      color: isAdmin
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF2563EB),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Joined: ${_formatDate(user.createdAt)}',
                  style: const TextStyle(
                    color: AppThemeColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Role'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeColors.primary,
                      side: const BorderSide(color: AppThemeColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      user.status == 'disabled'
                          ? Icons.check_circle_outline
                          : Icons.block_outlined,
                      size: 16,
                    ),
                    label: Text(
                      user.status == 'disabled' ? 'Enable' : 'Disable',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.status == 'disabled'
                          ? Colors.green
                          : Colors.red,
                      side: BorderSide(
                        color: user.status == 'disabled'
                            ? Colors.green
                            : Colors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _UserDetailCard extends StatelessWidget {
  final UserModel? user;

  const _UserDetailCard({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('No user selected'));
    }

    final initials =
        (user!.displayName?.trim().isNotEmpty == true
                ? user!.displayName!
                : user!.email)
            .split(RegExp(r'\s+'))
            .map((part) => part[0])
            .take(2)
            .join()
            .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF1F3C88),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.displayName?.trim().isNotEmpty == true
                          ? user!.displayName!
                          : user!.email.split('@').first,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user!.email,
                      style: const TextStyle(
                        color: AppThemeColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: user!.status == 'disabled'
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFFE7F7EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user!.status == 'disabled' ? 'disabled' : 'active',
                  style: TextStyle(
                    color: user!.status == 'disabled'
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF149F5C),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: user!.role == 'admin'
                      ? const Color(0xFFF1E8FF)
                      : user!.role == 'it'
                      ? const Color(0xFFDBF4FF)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user!.role,
                  style: TextStyle(
                    color: user!.role == 'admin'
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(label: 'Joined', value: _formatDate(user!.createdAt)),
          _InfoRow(
            label: 'Last active',
            value: _formatDate(user!.lastActiveAt),
          ),
          _InfoRow(label: 'Role', value: user!.role),
          _InfoRow(
            label: 'Notifications',
            value: user!.notificationsEnabled ? 'Enabled' : 'Disabled',
          ),
          const Spacer(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Role'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppThemeColors.primary,
                    side: const BorderSide(color: AppThemeColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    user!.status == 'disabled'
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                    size: 16,
                  ),
                  label: Text(
                    user!.status == 'disabled' ? 'Enable' : 'Disable',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user!.status == 'disabled'
                        ? Colors.green
                        : Colors.red,
                    side: BorderSide(
                      color: user!.status == 'disabled'
                          ? Colors.green
                          : Colors.red,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppThemeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access the admin dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _userService.getUserData(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final name = user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!
                : 'John Doe';
            final email = user?.email ?? 'john.doe@example.com';
            final initials = name.trim().isEmpty
                ? 'JD'
                : name
                      .trim()
                      .split(RegExp(r'\s+'))
                      .where((segment) => segment.isNotEmpty)
                      .take(2)
                      .map((segment) => segment[0])
                      .join()
                      .toUpperCase();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Manage your account',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4C60F5), Color(0xFF8F46FF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Premium Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('ADMIN'),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF1D9BF0),
                      iconBackground: const Color(0xFFEAF3FF),
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () => _showComingSoon('Profile editing'),
                    ),
                    _SettingsRow(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF00A383),
                      iconBackground: const Color(0xFFEAFBF4),
                      title: 'Location',
                      subtitle: 'New York, USA',
                      onTap: () => _showComingSoon('Location settings'),
                    ),
                    _SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFF2D7EF7),
                      iconBackground: const Color(0xFFEAF3FF),
                      title: 'Notifications',
                      subtitle: 'Manage alert preferences',
                      badge: '3 new',
                      badgeColor: Colors.white,
                      badgeBackground: const Color(0xFFEF4444),
                      onTap: () => _showComingSoon('Notifications'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionLabel('SECURITY'),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFF18A957),
                      iconBackground: const Color(0xFFE8F7EE),
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () => _showComingSoon('Password change'),
                    ),
                    _SettingsRow(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF18A957),
                      iconBackground: const Color(0xFFE8F7EE),
                      title: 'Privacy Settings',
                      subtitle: 'Control your data sharing',
                      onTap: () => _showComingSoon('Privacy settings'),
                    ),
                    _SettingsRow(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF18A957),
                      iconBackground: const Color(0xFFE8F7EE),
                      title: 'Email Preferences',
                      subtitle: 'Manage email notifications',
                      onTap: () => _showComingSoon('Email preferences'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionLabel('GENERAL'),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFFAD63D6),
                      iconBackground: const Color(0xFFF6ECFF),
                      title: 'Dark Mode',
                      subtitle: 'Coming soon',
                      onTap: () => _showComingSoon('Dark mode'),
                    ),
                    _SettingsRow(
                      icon: Icons.language_outlined,
                      iconColor: const Color(0xFF5A6BFF),
                      iconBackground: const Color(0xFFEAF1FF),
                      title: 'Language',
                      subtitle: 'English (US)',
                      onTap: () => _showComingSoon('Language settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionLabel('SUPPORT'),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.support_agent_outlined,
                      iconColor: const Color(0xFFE67E22),
                      iconBackground: const Color(0xFFFFF1E8),
                      title: 'Contact Support',
                      subtitle: 'Get help from our team',
                      onTap: () => _showComingSoon('Support'),
                    ),
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFFE67E22),
                      iconBackground: const Color(0xFFFFF1E8),
                      title: 'Terms & Privacy',
                      subtitle: 'Read our policies',
                      onTap: () => _showComingSoon('Terms & Privacy'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'AirSense v1.0.0\n© 2026 All rights reserved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemeColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppThemeColors.textSecondary,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[children[i]],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBackground;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.badgeBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppThemeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground ?? const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: badgeColor ?? AppThemeColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppThemeColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
