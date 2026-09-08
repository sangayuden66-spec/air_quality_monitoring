import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/privacy_preferences.dart';
import '../services/privacy_preferences_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final PrivacyPreferencesService _service = PrivacyPreferencesService();
  bool _isUpdating = false;

  Future<void> _updatePreferences(
    PrivacyPreferences current,
    PrivacyPreferences Function(PrivacyPreferences) change,
  ) async {
    if (_isUpdating) return;
    final next = change(current);
    setState(() => _isUpdating = true);
    try {
      await _service.savePreferences(next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update privacy settings: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: StreamBuilder<PrivacyPreferences>(
        stream: _service.watchPreferences(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final preferences = snapshot.data ?? PrivacyPreferences.defaults;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: AppThemeStyles.cardDecoration(),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Usage Analytics'),
                      subtitle: const Text(
                        'Share anonymous usage to help improve the app.',
                      ),
                      value: preferences.usageAnalytics,
                      onChanged: _isUpdating
                          ? null
                          : (value) => _updatePreferences(
                              preferences,
                              (p) => p.copyWith(usageAnalytics: value),
                            ),
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Crash Reports'),
                      subtitle: const Text(
                        'Send diagnostics when the app crashes.',
                      ),
                      value: preferences.crashReports,
                      onChanged: _isUpdating
                          ? null
                          : (value) => _updatePreferences(
                              preferences,
                              (p) => p.copyWith(crashReports: value),
                            ),
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Personalized Recommendations'),
                      subtitle: const Text(
                        'Use your activity to tailor health and AQI tips.',
                      ),
                      value: preferences.personalizedRecommendations,
                      onChanged: _isUpdating
                          ? null
                          : (value) => _updatePreferences(
                              preferences,
                              (p) => p.copyWith(
                                personalizedRecommendations: value,
                              ),
                            ),
                    ),
                    const Divider(height: 0),
                    SwitchListTile(
                      title: const Text('Share Anonymized Air Data'),
                      subtitle: const Text(
                        'Contribute anonymous local readings for trend insights.',
                      ),
                      value: preferences.shareAnonymizedAirData,
                      onChanged: _isUpdating
                          ? null
                          : (value) => _updatePreferences(
                              preferences,
                              (p) => p.copyWith(
                                shareAnonymizedAirData: value,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
