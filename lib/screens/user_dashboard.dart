import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/models/air_quality_model.dart';
import '../core/services/air_quality_service.dart';
import '../core/services/notification_service.dart';
import '../features/alerts/services/alert_service.dart';
import '../core/models/report_item.dart';
import '../core/services/report_service.dart';
import '../core/theme/app_theme.dart';

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
  final NotificationService _notificationService = NotificationService();
  final AlertService _alertService = AlertService();

  AirQualityModel? _data;
  List<AirQualityModel> _historyData = [];
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch current AQI
      final current = await _aqiService.fetchCurrentAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );

      // 2. Fetch last 24 hours of history for the graph
      final now = DateTime.now();
      final history = await _aqiService.fetchAirQualityHistory(
        widget.location.latitude,
        widget.location.longitude,
        now.subtract(const Duration(hours: 24)),
        now,
      );

      if (!mounted) return;
      setState(() {
        _data = current;
        _historyData = history
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });

      await _checkAlertThreshold(current);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAlertThreshold(AirQualityModel currentData) async {
    final decision = await _alertService.processTriggeredAlert(
      data: currentData,
    );
    if (!decision.shouldNotify) return;

    try {
      await _notificationService.showAqiAlert(
        aqi: currentData.aqi,
        category: currentData.aqiCategory,
        advice: currentData.healthAdvice,
        location: decision.locationName,
      );
    } catch (e) {
      debugPrint('Local notification display failed: $e');
    }
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
      child: Container(
        color: AppThemeColors.background,
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

              _HistoryChart(data: _historyData),
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
          const Text(
            'Current Location',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            '${data.latitude.toStringAsFixed(3)}, ${data.longitude.toStringAsFixed(3)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'US AQI',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            '${data.aqi}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            data.aqiCategory,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 14, color: Colors.white70),
              SizedBox(width: 6),
              Text(
                'Alerts are available in Notifications',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (lastUpdated != null) ...[
            const SizedBox(height: 12),
            Text(
              'Updated: ${DateFormat('hh:mm a').format(lastUpdated!)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
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
          color: AppThemeColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppThemeColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.$1,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  p.$2.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  p.$3,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
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
                Text(
                  'Your Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
            color: AppThemeColors.surface,
            border: Border.all(color: AppThemeColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: location,
                    zoom: 12,
                  ),
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  circles: {
                    Circle(
                      circleId: const CircleId('aqi_area'),
                      center: location,
                      radius: 2000,
                      fillColor: AppThemeColors.primary.withValues(alpha: 0.1),
                      strokeColor: AppThemeColors.primary.withValues(
                        alpha: 0.3,
                      ),
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
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$aqi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.air,
                          size: 14,
                          color: AppThemeColors.primary,
                        ),
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
}

class _HistoryChart extends StatelessWidget {
  final List<AirQualityModel> data;
  const _HistoryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = [...data]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '24-Hour History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
          decoration: BoxDecoration(
            color: AppThemeColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppThemeColors.border),
          ),
          child: sorted.isEmpty
              ? const Center(child: Text('Fetching history...'))
              : LineChart(
                  (() {
                    final start = sorted.first.timestamp;
                    final spots = sorted
                        .map(
                          (entry) => FlSpot(
                            entry.timestamp.difference(start).inMinutes / 60.0,
                            entry.aqi.toDouble(),
                          ),
                        )
                        .toList();
                    final xMax = spots.last.x < 1 ? 1.0 : spots.last.x;
                    final minAqi = sorted
                        .map((e) => e.aqi)
                        .reduce((a, b) => a < b ? a : b);
                    final maxAqi = sorted
                        .map((e) => e.aqi)
                        .reduce((a, b) => a > b ? a : b);
                    final minY = ((minAqi ~/ 25) * 25 - 10)
                        .clamp(0, 500)
                        .toDouble();
                    final rawMaxY = ((maxAqi / 25).ceil() * 25 + 10)
                        .clamp(0, 500)
                        .toDouble();
                    final maxY = rawMaxY <= minY ? minY + 25 : rawMaxY;

                    return LineChartData(
                      minX: 0,
                      maxX: xMax,
                      minY: minY,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: 50,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 6,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value > xMax) {
                                return const SizedBox.shrink();
                              }
                              final time = start.add(
                                Duration(minutes: (value * 60).round()),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('ha').format(time).toLowerCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppThemeColors.primary,
                          barWidth: 3,
                          dotData: FlDotData(show: spots.length <= 2),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppThemeColors.primary.withValues(alpha: 0.2),
                                AppThemeColors.primary.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    );
                  })(),
                ),
        ),
        const SizedBox(height: 12),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ChartLegend(color: Colors.green, label: 'Good'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.yellow, label: 'Fair'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.orange, label: 'Moderate'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.red, label: 'Poor'),
              SizedBox(width: 12),
              _ChartLegend(color: Colors.purple, label: 'Very Poor'),
            ],
          ),
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
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
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
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Live Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                child: Center(
                  child: Text(
                    'No reports available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return Column(
              children: snapshot.data!
                  .take(3)
                  .map((report) => _ReportCard(report: report))
                  .toList(),
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
        color: AppThemeColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppThemeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  report.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.user,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${report.confirm}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      report.location,
                      style: const TextStyle(
                        color: AppThemeColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                report.timeAgo,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
