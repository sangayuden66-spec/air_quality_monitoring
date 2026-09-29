import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../services/alert_preference_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final AlertPreferenceService _prefService = AlertPreferenceService();

  bool _isLoading = true;
  bool _enabled = true;
  double _threshold = 3;
  LatLng? _alertLocation;
  String _locationName = 'Current Location';

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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await _prefService.saveAlertPreference(
        AlertPreference(
          id: 'default_alert',
          threshold: _threshold.toInt(),
          enabled: _enabled,
          locationName: _locationName,
          latitude: _alertLocation?.latitude ?? 0.0,
          longitude: _alertLocation?.longitude ?? 0.0,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alert settings saved!')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Alert Preferences'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: AppThemeColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable AQI Alerts'),
                  subtitle: const Text(
                    'Get notified when AQI exceeds your limit',
                  ),
                  value: _enabled,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Note: The app will check air quality based on your settings whenever you open or refresh the dashboard.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
