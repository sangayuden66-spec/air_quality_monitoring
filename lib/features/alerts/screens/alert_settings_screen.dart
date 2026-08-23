import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';

class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'John Doe';
    final email = user?.email ?? 'john.doe@example.com';
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    final sections = [
      _SectionHeader('Profile'),
      _SettingsCard(children: [
        _SettingsTile(icon: Icons.person_outline_rounded, iconColor: const Color(0xFF1D9BF0), iconBg: const Color(0xFFEAF3FF), title: 'Edit Profile', subtitle: 'Update your personal information', onTap: () {}),
        _SettingsTile(icon: Icons.location_on_outlined, iconColor: const Color(0xFF1D9BF0), iconBg: const Color(0xFFEAF3FF), title: 'Location', subtitle: 'Home', onTap: () {}),
        _SettingsTile(icon: Icons.notifications_none_rounded, iconColor: const Color(0xFF1D9BF0), iconBg: const Color(0xFFEAF3FF), title: 'Notifications', subtitle: 'Manage alert preferences', trailingBadge: '3 new', onTap: () {}),
      ]),
      const SizedBox(height: 20),
      _SectionHeader('Security'),
      _SettingsCard(children: [
        _SettingsTile(icon: Icons.lock_outline, iconColor: const Color(0xFF18A957), iconBg: const Color(0xFFE8F7EE), title: 'Change Password', subtitle: 'Update your password', onTap: () {}),
        _SettingsTile(icon: Icons.privacy_tip_outlined, iconColor: const Color(0xFF18A957), iconBg: const Color(0xFFE8F7EE), title: 'Privacy Settings', subtitle: 'Control your data sharing', onTap: () {}),
        _SettingsTile(icon: Icons.email_outlined, iconColor: const Color(0xFF18A957), iconBg: const Color(0xFFE8F7EE), title: 'Email Preferences', subtitle: 'Manage email notifications', onTap: () {}),
      ]),
      const SizedBox(height: 20),
      _SectionHeader('General'),
      _SettingsCard(children: [
        _SettingsTile(icon: Icons.dark_mode_outlined, iconColor: const Color(0xFFAD63D6), iconBg: const Color(0xFFF6ECFF), title: 'Dark Mode', subtitle: 'Coming soon', onTap: () {}),
        _SettingsTile(icon: Icons.language_outlined, iconColor: const Color(0xFF5A6BFF), iconBg: const Color(0xFFEAF1FF), title: 'Language', subtitle: 'English (US)', onTap: () {}),
      ]),
      const SizedBox(height: 20),
      _SectionHeader('Support'),
      _SettingsCard(children: [
        _SettingsTile(icon: Icons.help_center_outlined, iconColor: const Color(0xFFE67E22), iconBg: const Color(0xFFFFF1E8), title: 'Help Center', subtitle: 'Browse FAQs and guides', onTap: () {}),
        _SettingsTile(icon: Icons.support_agent_outlined, iconColor: const Color(0xFFE67E22), iconBg: const Color(0xFFFFF1E8), title: 'Contact Support', subtitle: 'Get help from our team', onTap: () {}),
        _SettingsTile(icon: Icons.description_outlined, iconColor: const Color(0xFFE67E22), iconBg: const Color(0xFFFFF1E8), title: 'Terms & Privacy', subtitle: 'Read our policies', onTap: () {}),
      ]),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 18),
      const _AlertThresholdCard(),
      const SizedBox(height: 16),
      const Center(
        child: Text(
          'Air Quality Monitor v1.0.0\n© 2026 All rights reserved',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppThemeColors.textSecondary, height: 1.5),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      Text('Manage your account', style: TextStyle(fontSize: 13, color: AppThemeColors.textSecondary)),
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
                      initials.isEmpty ? 'JD' : initials,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Premium Member', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...sections,
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppThemeColors.textSecondary),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingBadge;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
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
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppThemeColors.textSecondary)),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18)),
                child: Text(trailingBadge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppThemeColors.primary)),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppThemeColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _AlertThresholdCard extends StatefulWidget {
  const _AlertThresholdCard();

  @override
  State<_AlertThresholdCard> createState() => _AlertThresholdCardState();
}

class _AlertThresholdCardState extends State<_AlertThresholdCard> {
  double _threshold = 2;

  String get _label {
    if (_threshold <= 1) return 'Good';
    if (_threshold <= 2) return 'Fair';
    if (_threshold <= 3) return 'Moderate';
    if (_threshold <= 4) return 'Poor';
    return 'Very Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ALERTS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppThemeColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alert Threshold',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '$_threshold - $_label',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppThemeColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Control when AQI alerts are triggered',
            style: TextStyle(fontSize: 12, color: AppThemeColors.textSecondary),
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: const Color(0xFFD6E4FF),
              thumbColor: const Color(0xFF3B82F6),
              overlayColor: const Color(0xFF3B82F6).withValues(alpha: 0.18),
              trackHeight: 4,
            ),
            child: Slider(
              value: _threshold,
              min: 1,
              max: 5,
              divisions: 4,
              label: _threshold.round().toString(),
              onChanged: (value) => setState(() => _threshold = value),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Threshold', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
