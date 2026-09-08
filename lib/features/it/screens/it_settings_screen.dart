import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/user_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/it_settings_preferences.dart';
import '../services/it_settings_service.dart';

class ItSettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ItSettingsScreen({super.key, this.onBack});

  @override
  State<ItSettingsScreen> createState() => _ItSettingsScreenState();
}

class _ItSettingsScreenState extends State<ItSettingsScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ItSettingsService _settingsService = ItSettingsService();
  bool _isUpdatingTheme = false;

  Future<void> _updatePrefs(
    ItSettingsPreferences current,
    ItSettingsPreferences Function(ItSettingsPreferences) change,
  ) async {
    await _settingsService.savePreferences(change(current));
  }

  Future<void> _toggleThemeMode(bool isDark) async {
    if (_isUpdatingTheme) return;

    setState(() => _isUpdatingTheme = true);
    try {
      await _userService.updateThemeMode(isDark: isDark);
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage('Failed to update dark mode: $error');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingTheme = false);
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access the IT dashboard.',
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

  void _showComingSoon(String feature) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$feature isn\'t available yet.')),
        );
    });
  }

  void _showSnackBarMessage(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _showEditProfileDialog(UserModel? user) async {
    if (user == null) {
      _showSnackBarMessage('Unable to load your profile right now.');
      return;
    }

    final currentName =
        user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : '';
    final nameController = TextEditingController(text: currentName);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || shouldSave != true) return;

    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBarMessage('Display name cannot be empty.');
      return;
    }

    try {
      await _userService.updateDisplayName(newName);
      if (!mounted) return;
      _showSnackBarMessage('Profile updated successfully.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBarMessage('Failed to update profile: $error');
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? validationError;

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
              if (validationError != null) ...[
                const SizedBox(height: 10),
                Text(
                  validationError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  setDialogState(
                    () => validationError = 'Please fill in all password fields.',
                  );
                  return;
                }
                if (newPassword.length < 6) {
                  setDialogState(
                    () => validationError =
                        'New password must be at least 6 characters.',
                  );
                  return;
                }
                if (newPassword != confirmPassword) {
                  setDialogState(
                    () => validationError =
                        'New password and confirmation do not match.',
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || shouldChange != true) return;

    try {
      await _authService.changePassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );
      if (!mounted) return;
      _showSnackBarMessage('Password changed successfully.');
    } catch (error) {
      if (!mounted) return;
      final errorText = error.toString().toLowerCase();
      final message = errorText.contains('wrong-password') ||
              errorText.contains('invalid-credential')
          ? 'Current password is incorrect.'
          : 'Failed to change password: $error';
      _showSnackBarMessage(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'IT Staff Account',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<UserModel?>(
                stream: _userService.getUserData(),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  return StreamBuilder<ItSettingsPreferences>(
                    stream: _settingsService.watchPreferences(),
                    builder: (context, prefsSnap) {
                      final prefs =
                          prefsSnap.data ?? ItSettingsPreferences.defaults;
                      final isDarkMode =
                          (user?.themeMode ?? 'light') == 'dark';
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _ProfileCard(user: user),
                          const SizedBox(height: 20),
                          const _SectionLabel('Account'),
                          const SizedBox(height: 8),
                          _CardGroup(
                            children: [
                              _SettingsRow(
                                icon: Icons.person_outline,
                                title: 'Edit Profile',
                                subtitle: 'Update name and contact info',
                                onTap: () => _showEditProfileDialog(user),
                              ),
                              _SettingsRow(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                subtitle: 'Update your password',
                                onTap: _showChangePasswordDialog,
                              ),
                              _SettingsRow(
                                icon: Icons.mail_outline,
                                title: 'Email Address',
                                subtitle: user?.email ?? '—',
                                onTap: () =>
                                    _showComingSoon('Editing your email'),
                              ),
                              _SettingsRow(
                                icon: Icons.phone_iphone_outlined,
                                title: 'Two-Factor Auth',
                                subtitle: 'Enabled via authenticator app',
                                badge: 'Coming soon',
                                badgeColor: AppThemeColors.textSecondary,
                                badgeBackground: const Color(0xFFEEF0F4),
                                onTap: () => _showComingSoon(
                                  'Two-factor authentication',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel('Notifications'),
                          const SizedBox(height: 8),
                          _CardGroup(
                            children: [
                              _ToggleRow(
                                icon: Icons.notifications_active_rounded,
                                iconColor: const Color(0xFF7C3AED),
                                iconBackground: const Color(0xFFF1EBFB),
                                title: 'Critical System Alerts',
                                subtitle: 'Server down, API failures',
                                value: prefs.criticalSystemAlerts,
                                onChanged: (v) => _updatePrefs(
                                  prefs,
                                  (p) => p.copyWith(criticalSystemAlerts: v),
                                ),
                              ),
                              _ToggleRow(
                                icon: Icons.notifications_active_rounded,
                                iconColor: const Color(0xFF7C3AED),
                                iconBackground: const Color(0xFFF1EBFB),
                                title: 'Maintenance Reminders',
                                subtitle: 'Upcoming scheduled tasks',
                                value: prefs.maintenanceReminders,
                                onChanged: (v) => _updatePrefs(
                                  prefs,
                                  (p) => p.copyWith(maintenanceReminders: v),
                                ),
                              ),
                              _ToggleRow(
                                icon: Icons.mail_outline,
                                iconColor: const Color(0xFF7C3AED),
                                iconBackground: const Color(0xFFF1EBFB),
                                title: 'Daily Email Digest',
                                subtitle: 'Summary of system health',
                                value: prefs.dailyEmailDigest,
                                onChanged: (v) => _updatePrefs(
                                  prefs,
                                  (p) => p.copyWith(dailyEmailDigest: v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel('Display'),
                          const SizedBox(height: 8),
                          _CardGroup(
                            children: [
                              _ToggleRow(
                                icon: Icons.dark_mode_outlined,
                                iconColor: AppThemeColors.textSecondary,
                                iconBackground: const Color(0xFFEEF0F4),
                                title: 'Dark Mode',
                                subtitle: isDarkMode ? 'Enabled' : 'Disabled',
                                value: isDarkMode,
                                onChanged:
                                    _isUpdatingTheme ? null : _toggleThemeMode,
                                dimmed: false,
                              ),
                              _ToggleRow(
                                icon: Icons.desktop_windows_outlined,
                                iconColor: AppThemeColors.textSecondary,
                                iconBackground: const Color(0xFFEEF0F4),
                                title: 'Compact View',
                                subtitle: 'Denser data tables and lists',
                                value: prefs.compactView,
                                onChanged: (v) => _updatePrefs(
                                  prefs,
                                  (p) => p.copyWith(compactView: v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel('About'),
                          const SizedBox(height: 8),
                          _CardGroup(
                            children: [
                              _SettingsRow(
                                icon: Icons.info_outline_rounded,
                                iconColor: const Color(0xFF2D7EF7),
                                iconBackground: const Color(0xFFE7F0FE),
                                title: 'App Version',
                                subtitle: 'AirSense v1.0.0 (IT Build)',
                                onTap: () => showAboutDialog(
                                  context: context,
                                  applicationName: 'AirSense',
                                  applicationVersion: 'v1.0.0 (IT Build)',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _confirmLogout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
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
                              '© 2026 ACT Government · IT Staff Portal',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppThemeColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel? user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'IT Staff';
    final email = user?.email ?? '—';
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(' ')
              .where((s) => s.isNotEmpty)
              .map((s) => s[0])
              .take(2)
              .join()
              .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppThemeStyles.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'IT Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBackground;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    this.iconBackground,
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
                color: iconBackground ?? const Color(0xFFE7F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFF2D7EF7),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
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
                  color: badgeBackground ?? const Color(0xFFE7F8EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? const Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(width: 6),
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

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool dimmed;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: dimmed
                        ? AppThemeColors.textSecondary
                        : AppThemeColors.textPrimary,
                  ),
                ),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppThemeColors.textPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5EAF3),
          ),
        ],
      ),
    );
  }
}
