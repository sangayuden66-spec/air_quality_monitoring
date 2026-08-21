import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/alert_preference_service.dart';
import '../../../screens/map_screen.dart';

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
    if (_alertLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location on the map first.'),
        ),
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
      appBar: AppBar(
        title: const Text('Alert Preferences'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.teal,
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
                const Divider(),
                ListTile(
                  title: const Text('AQI Threshold'),
                  subtitle: Text(
                    'Notify me when AQI index is at least ${_threshold.toInt()}',
                  ),
                  trailing: Text(
                    _getAqiLabel(_threshold.toInt()),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Slider(
                  value: _threshold,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _getAqiLabel(_threshold.round()),
                  onChanged: _enabled
                      ? (val) => setState(() => _threshold = val)
                      : null,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Alert Location'),
                  subtitle: Text(
                    _alertLocation == null
                        ? 'No location selected'
                        : 'Lat: ${_alertLocation!.latitude.toStringAsFixed(3)}, Lng: ${_alertLocation!.longitude.toStringAsFixed(3)}',
                  ),
                  trailing: const Icon(Icons.map),
                  onTap: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() => _alertLocation = result);
                    }
                  },
                ),
                if (_alertLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      initialValue: _locationName,
                      decoration: const InputDecoration(
                        labelText: 'Location Name (e.g. Home)',
                      ),
                      onChanged: (val) => _locationName = val,
                    ),
                  ),
                const SizedBox(height: 40),
                const Text(
                  'Note: The app will check air quality for this location whenever you open or refresh the dashboard.',
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

  String _getAqiLabel(int value) {
    switch (value) {
      case 1:
        return '1 Good';
      case 2:
        return '2 Fair';
      case 3:
        return '3 Moderate';
      case 4:
        return '4 Poor';
      case 5:
        return '5 Very Poor';
      default:
        return '$value';
    }
  }
}
