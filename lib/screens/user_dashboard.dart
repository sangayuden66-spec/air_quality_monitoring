import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../core/models/air_quality_model.dart';
import '../core/services/air_quality_service.dart';
import '../core/services/notification_service.dart';
import '../features/alerts/services/alert_preference_service.dart';

class UserDashboard extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onViewAllReports;

  const UserDashboard({
    super.key, 
    required this.location, 
    this.onViewAllReports
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final AirQualityService _aqiService = AirQualityService();
  final AlertPreferenceService _prefService = AlertPreferenceService();
  final NotificationService _notificationService = NotificationService();

  AirQualityModel? _data;
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(UserDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _aqiService.fetchCurrentAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );
      
      setState(() {
        _data = data;
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });

      // Requirement #8: Check threshold and trigger notification
      _checkAlertThreshold(data);
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAlertThreshold(AirQualityModel currentData) async {
    // Get user preferences (Requirement #7 & #8)
    _prefService.getAlertPreference().first.then((pref) {
      if (pref != null && pref.enabled && currentData.aqi >= pref.threshold) {
        _notificationService.showAqiAlert(
          aqi: currentData.aqi,
          threshold: pref.threshold,
          location: pref.locationName,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            TextButton(onPressed: _fetchData, child: const Text('Refresh')),
          ],
        ),
      );
    }

    if (_data == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AqiHeroCard(data: _data!, lastUpdated: _lastUpdated),
            const SizedBox(height: 16),
            _PollutantGrid(data: _data!),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AqiHeroCard extends StatelessWidget {
  final AirQualityModel data;
  final DateTime? lastUpdated;

  const _AqiHeroCard({required this.data, this.lastUpdated});

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return const Color(0xFF7F1D1D);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAqiColor(data.aqi);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Selected Location', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            '${data.latitude.toStringAsFixed(3)}, ${data.longitude.toStringAsFixed(3)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('US AQI', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(
            '${data.aqi}',
            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1),
          ),
          Text(
            data.aqiCategory,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 12),
            Text(
              'Updated: ${DateFormat('hh:mm a').format(lastUpdated!)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ]
        ],
      ),
    );
  }
}

class _PollutantGrid extends StatelessWidget {
  final AirQualityModel data;
  const _PollutantGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final pollutants = [
      ('PM2.5', data.pm25, 'µg/m³'),
      ('PM10', data.pm10, 'µg/m³'),
      ('CO', data.co, 'µg/m³'),
      ('NO₂', data.no2, 'µg/m³'),
      ('SO₂', data.so2, 'µg/m³'),
      ('O₃', data.o3, 'µg/m³'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: pollutants.length,
      itemBuilder: (context, index) {
        final p = pollutants[index];
        return Card(
          elevation: 0,
          color: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.$1, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  p.$2.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(p.$3, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }
}
