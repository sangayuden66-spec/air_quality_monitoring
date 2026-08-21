import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/alert_preference_service.dart';
import '../../../screens/map_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/fcm_service.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  final AlertPreferenceService _prefService = AlertPreferenceService();
  final AuthService _authService = AuthService();
  final FcmService _fcmService = FcmService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  bool _enabled = true;
  double _threshold = 3;
  LatLng? _alertLocation;
  String _locationName = 'My Alert Location';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final pref = await _prefService.getAlertPreference().first;
      if (pref != null) {
        setState(() {
          _enabled = pref.enabled;
          _threshold = pref.threshold.toDouble();
          _alertLocation = LatLng(pref.latitude, pref.longitude);
          _locationName = pref.locationName;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_alertLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _prefService.saveAlertPreference(
        AlertPreference(
          id: 'default_alert',
          threshold: _threshold.toInt(),
          enabled: _enabled,
          locationName: _locationName,
          latitude: _alertLocation!.latitude,
          longitude: _alertLocation!.longitude,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved! Monitoring active.'), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
    if (result != null) {
      setState(() => _alertLocation = result);
    }
  }

  Future<void> _openAlertPreferencesSheet() async {
    bool localEnabled = _enabled;
    double localThreshold = _threshold;
    LatLng? localLocation = _alertLocation;
    String localName = _locationName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert Preferences',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable AQI Alerts'),
                    subtitle: const Text('Receive notification alerts in this app'),
                    value: localEnabled,
                    activeThumbColor: Colors.teal,
                    onChanged: (val) => setSheetState(() => localEnabled = val),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Alert Threshold: ${_getAqiLabel(localThreshold.toInt())}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: localThreshold,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _getAqiLabel(localThreshold.toInt()),
                    onChanged: localEnabled ? (val) => setSheetState(() => localThreshold = val) : null,
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB)),
                    title: const Text('Monitoring Location'),
                    subtitle: Text(
                      localLocation == null
                          ? 'Select location on map'
                          : '${localLocation!.latitude.toStringAsFixed(3)}, ${localLocation!.longitude.toStringAsFixed(3)}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final LatLng? result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                      if (result != null) {
                        setSheetState(() {
                          localLocation = result;
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: TextEditingController(text: localName),
                    decoration: const InputDecoration(
                      labelText: 'Location name',
                      hintText: 'e.g. Home',
                    ),
                    onChanged: (val) => localName = val.trim().isEmpty ? 'My Alert Location' : val.trim(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _enabled = localEnabled;
                                _threshold = localThreshold;
                                _alertLocation = localLocation;
                                _locationName = localName;
                              });
                              await _save();
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Preferences'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getAqiLabel(int val) {
    switch (val) {
      case 1: return '1 - Good';
      case 2: return '2 - Fair';
      case 3: return '3 - Moderate';
      case 4: return '4 - Poor';
      case 5: return '5 - Very Poor';
      default: return 'Select Index';
    }
  }

  void _handleLogout() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // 1. Clean up FCM token before signing out
      await _fcmService.deleteToken();
      // 2. Sign out
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseAuth.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName!.trim() : 'User';
    final email = user?.email ?? 'No email';
    final initials = displayName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                      ),
                      const Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Settings',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                            ),
                            Text(
                              'Manage your account',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D7EF7), Color(0xFF8A2BE2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          initials.isEmpty ? 'U' : initials,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white70, fontSize: 19),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Member',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'PROFILE',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit profile coming soon')),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Location',
                      subtitle: _locationName,
                      onTap: () async {
                        await _pickLocation();
                        if (mounted && _alertLocation != null) {
                          await _save();
                        }
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                      title: 'Notifications',
                      subtitle: 'Threshold ${_getAqiLabel(_threshold.toInt())}',
                      trailingBadge: !_enabled ? 'Off' : null,
                      onTap: _openAlertPreferencesSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'ALERTS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5EAF3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F111827),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alert Threshold',
                            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              _getAqiLabel(_threshold.toInt()),
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Control when AQI alerts are triggered',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                      Slider(
                        value: _threshold,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _getAqiLabel(_threshold.toInt()),
                        onChanged: _enabled ? (val) => setState(() => _threshold = val) : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _openAlertPreferencesSheet,
                              child: const Text('More Alert Options'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save Threshold'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SECURITY',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFE8FBF3),
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Change password coming soon')),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFE8FBF3),
                      title: 'Privacy Settings',
                      subtitle: 'Control your data sharing',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Privacy settings coming soon')),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFE8FBF3),
                      title: 'Email Preferences',
                      subtitle: 'Manage email notifications',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email preferences coming soon')),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xFFDC2626),
                      iconBg: const Color(0xFFFEECEC),
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      onTap: _handleLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'GENERAL',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFFA855F7),
                      iconBg: const Color(0xFFF5EDFF),
                      title: 'Dark Mode',
                      subtitle: 'Coming soon',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dark mode coming soon')),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.language_outlined,
                      iconColor: const Color(0xFFA855F7),
                      iconBg: const Color(0xFFF5EDFF),
                      title: 'Language',
                      subtitle: 'English (US)',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language options coming soon')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Alert threshold and monitoring location are kept from your previous settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            )),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          if (index.isEven) return children[index ~/ 2];
          return const Divider(height: 1, color: Color(0xFFEDEFF4));
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final VoidCallback onTap;

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
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingBadge != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                trailingBadge!,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}
