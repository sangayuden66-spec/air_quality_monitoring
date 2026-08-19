import 'package:flutter/material.dart';
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
  
  bool _isLoading = true;
  bool _enabled = true;
  double _threshold = 3; // Default to 3 (Moderate)
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
                  'ALERTS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                SwitchListTile(
                  title: const Text('Background Monitoring'),
                  subtitle: const Text('Receive alerts when air quality drops'),
                  value: _enabled,
                  activeColor: Colors.teal,
                  onChanged: (val) => setState(() => _enabled = val),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Alert Threshold'),
                  subtitle: Text('Notify when index reaches: ${_getAqiLabel(_threshold.toInt())}'),
                ),
                Slider(
                  value: _threshold,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _getAqiLabel(_threshold.toInt()),
                  onChanged: _enabled ? (val) => setState(() => _threshold = val) : null,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Monitoring Location'),
                  subtitle: Text(_alertLocation == null 
                      ? 'Select location on map' 
                      : 'Lat: ${_alertLocation!.latitude.toStringAsFixed(3)}, Lng: ${_alertLocation!.longitude.toStringAsFixed(3)}'),
                  trailing: const Icon(Icons.location_searching, color: Colors.teal),
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
                const SizedBox(height: 40),
                const Text(
                  'ACCOUNT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                ListTile(
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  onTap: _handleLogout,
                ),
                const SizedBox(height: 20),
                const Text(
                  'AQI data provided by OpenWeather. Notifications are sent when local quality exceeds your limit.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
