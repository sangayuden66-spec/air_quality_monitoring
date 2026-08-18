import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/models/air_quality_model.dart';
import '../core/services/air_quality_service.dart';
import '../core/services/notification_service.dart';
import '../features/alerts/services/alert_preference_service.dart';
import '../features/alerts/services/alert_service.dart';
import '../features/alerts/models/air_quality_alert.dart';
import '../core/models/report_item.dart';
import '../core/services/report_service.dart';

class UserDashboard extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onViewAllReports;
  final VoidCallback? onViewMap;

  const UserDashboard({
    super.key, 
    required this.location, 
    this.onViewAllReports,
    this.onViewMap,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final AirQualityService _aqiService = AirQualityService();
  final AlertPreferenceService _prefService = AlertPreferenceService();
  final NotificationService _notificationService = NotificationService();
  final AlertService _alertService = AlertService();

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

      _checkAlertThreshold(data);
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAlertThreshold(AirQualityModel currentData) async {
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
            
            _LocationPreview(
              location: widget.location, 
              aqi: _data!.aqi,
              onViewFull: widget.onViewMap,
            ),
            const SizedBox(height: 24),
            
            _HistoryChart(),
            const SizedBox(height: 24),
            
            _AlertsSection(alertService: _alertService),
            const SizedBox(height: 24),
            
            _ReportsSection(onViewAll: widget.onViewAllReports),
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Data'),
            ),
            const SizedBox(height: 16),
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

class _LocationPreview extends StatelessWidget {
  final LatLng location;
  final int aqi;
  final VoidCallback? onViewFull;

  const _LocationPreview({
    required this.location, 
    required this.aqi,
    this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20),
                SizedBox(width: 8),
                Text('Your Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(onPressed: onViewFull, child: const Text('View Full')),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade100,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: location, zoom: 12),
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  circles: {
                    Circle(
                      circleId: const CircleId('aqi_area'),
                      center: location,
                      radius: 2000,
                      fillColor: Colors.teal.withOpacity(0.1),
                      strokeColor: Colors.teal.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  },
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$aqi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Icon(Icons.air, size: 14, color: Colors.teal),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Based on GPS', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildAqiDot(Colors.green),
                        _buildAqiDot(Colors.yellow.shade700),
                        _buildAqiDot(Colors.orange),
                        _buildAqiDot(Colors.red),
                        const SizedBox(width: 4),
                        const Text('AQI Scale', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAqiDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('24-Hour History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 6 == 0) {
                        return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10, color: Colors.grey));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 45), FlSpot(4, 52), FlSpot(8, 48),
                    FlSpot(12, 68), FlSpot(16, 62), FlSpot(20, 55), FlSpot(24, 42),
                  ],
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.teal.withOpacity(0.2), Colors.teal.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ChartLegend(color: Colors.green, label: 'Good'),
            _ChartLegend(color: Colors.yellow, label: 'Moderate'),
            _ChartLegend(color: Colors.orange, label: 'Unhealthy'),
          ],
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final AlertService alertService;
  const _AlertsSection({required this.alertService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            StreamBuilder<int>(
              stream: alertService.getUnreadCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('$count new', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AirQualityAlert>>(
          stream: alertService.getAlertsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No active alerts for your area.'),
                ),
              );
            }
            return Column(
              children: snapshot.data!.take(2).map((alert) => _AlertCard(alert: alert)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AirQualityAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  '${DateTime.now().difference(alert.createdAt).inMinutes}m ago',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  final VoidCallback? onViewAll;
  const _ReportsSection({this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final ReportService reportService = ReportService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 20),
                SizedBox(width: 8),
                Text('Live Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(onPressed: onViewAll, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReportItem>>(
          stream: reportService.getReportsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No reports available', style: TextStyle(color: Colors.grey))),
              );
            }
            return Column(
              children: snapshot.data!.take(3).map((report) => _ReportCard(report: report)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportItem report;
  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade600,
                child: Text(report.initials, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(report.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 10),
                              const SizedBox(width: 2),
                              Text('${report.confirm}', style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(report.location, style: const TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                ),
              ),
              Text(report.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.text, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }
}
