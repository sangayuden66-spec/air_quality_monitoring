import 'package:flutter/material.dart';
import '../services/alert_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final AlertService _alertService = AlertService();
  bool _isLoading = true;

  bool _alertsEnabled = true;
  double _minAQIThreshold = 100;
  bool _sensitiveGroupAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _alertService.getPreferences();
      if (prefs != null) {
        setState(() {
          _alertsEnabled = prefs['enabled'] ?? true;
          _minAQIThreshold = (prefs['threshold'] ?? 100).toDouble();
          _sensitiveGroupAlerts = prefs['sensitiveGroupAlerts'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load preferences')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);
    try {
      await _alertService.savePreferences(
        enabled: _alertsEnabled,
        threshold: _minAQIThreshold.toInt(),
        sensitiveGroupAlerts: _sensitiveGroupAlerts,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preferences')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable Air Quality Alerts'),
                  subtitle: const Text('Receive notifications when air quality changes'),
                  value: _alertsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _alertsEnabled = value;
                    });
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum AQI Threshold: ${_minAQIThreshold.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text(
                        'You will only be alerted when AQI exceeds this value.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Slider(
                        value: _minAQIThreshold,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        label: _minAQIThreshold.toInt().toString(),
                        onChanged: _alertsEnabled
                            ? (value) {
                                setState(() {
                                  _minAQIThreshold = value;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Sensitive Group Alerts'),
                  subtitle: const Text(
                      'Get extra warnings if you are in a sensitive health group'),
                  value: _sensitiveGroupAlerts,
                  onChanged: _alertsEnabled
                      ? (value) {
                          setState(() {
                            _sensitiveGroupAlerts = value;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _savePreferences,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Preferences'),
                ),
              ],
            ),
    );
  }
}
