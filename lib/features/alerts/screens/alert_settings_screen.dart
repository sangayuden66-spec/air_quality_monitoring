import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/alert_preference_service.dart';
import '../../../screens/map_screen.dart';
import '../../auth/services/auth_service.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  final AlertPreferenceService _prefService = AlertPreferenceService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  bool _enabled = true;
  double _threshold = 100;
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
          const SnackBar(content: Text('Alert settings saved successfully!')),
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
      await _authService.signOut();
      if (mounted) {
        // Pop back to the root (which will now show the login screen via AuthWrapper)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _save,
              child: const Text('SAVE', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'NOTIFICATIONS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Enable AQI Alerts'),
                  subtitle: const Text('Receive a local notification when AQI exceeds limit'),
                  value: _enabled,
                  activeColor: Colors.teal,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
                const Divider(),
                ListTile(
                  title: const Text('AQI Threshold'),
                  subtitle: Text('Notify when US AQI is above ${_threshold.toInt()}'),
                  trailing: Text('${_threshold.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Slider(
                  value: _threshold,
                  min: 0,
                  max: 500,
                  divisions: 50,
                  label: _threshold.round().toString(),
                  onChanged: _enabled ? (val) => setState(() => _threshold = val) : null,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Alert Location'),
                  subtitle: Text(_alertLocation == null 
                      ? 'No location selected' 
                      : 'Lat: ${_alertLocation!.latitude.toStringAsFixed(3)}, Lng: ${_alertLocation!.longitude.toStringAsFixed(3)}'),
                  trailing: const Icon(Icons.map_outlined, color: Colors.teal),
                  onTap: () async {
                    final LatLng? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
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
                        labelText: 'Location Description',
                        hintText: 'e.g. Home, Office, or School',
                      ),
                      onChanged: (val) => _locationName = val,
                    ),
                  ),
                const SizedBox(height: 40),
                const Text(
                  'ACCOUNT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
