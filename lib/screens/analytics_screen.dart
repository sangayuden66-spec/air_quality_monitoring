import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../core/models/air_quality_model.dart';
import '../core/services/air_quality_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final LatLng location;
  final VoidCallback? onBackToHome;

  const AnalyticsScreen({
    super.key,
    required this.location,
    this.onBackToHome,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AirQualityService _aqiService = AirQualityService();
  bool _isLoading = true;
  String? _error;
  AirQualityModel? _current;
  List<AirQualityModel> _forecast = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(AnalyticsScreen oldWidget) {
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
      final current = await _aqiService.fetchCurrentAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );
      final forecast = await _aqiService.fetchForecastAirQuality(
        widget.location.latitude,
        widget.location.longitude,
      );

      if (!mounted) return;
      setState(() {
        _current = current;
        _forecast = forecast..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 44),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_current == null) {
      return const Center(child: Text('No analytics data available.'));
    }

    final current = _current!;
    final upcoming = _forecast.where((f) => f.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1)))).toList();
    final next3h = upcoming.where((f) => f.timestamp.isBefore(DateTime.now().add(const Duration(hours: 3, minutes: 30)))).toList();
    final predicted = next3h.isNotEmpty ? next3h.last : (upcoming.isNotEmpty ? upcoming.first : current);
    final hourly = (upcoming.isNotEmpty ? upcoming : [current]).take(7).toList();
    final daily = _buildDailyForecast(current, upcoming);
    final insights = _buildInsights(current, predicted);
    final comparisons = _buildComparisons(current, upcoming);
    final confidence = _buildForecastConfidence(upcoming);

    return Container(
      color: const Color(0xFFF5F7FB),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 18),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 14, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBackToHome,
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                    ),
                    const Expanded(
                      child: Column(
                        children: [
                          Text('Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                          Text('AQI Predictions & Trends', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              _PredictionCard(current: current, predicted: predicted),
              const SizedBox(height: 18),
              const _SectionTitle(icon: Icons.schedule, title: '12-Hour Forecast'),
              _HourlyForecastCard(items: hourly),
              const SizedBox(height: 18),
              const _SectionTitle(icon: Icons.calendar_today_outlined, title: '7-Day Forecast'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(children: daily.map((item) => _DayForecastCard(item: item)).toList()),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(icon: Icons.tips_and_updates_outlined, title: 'Key Insights'),
              const SizedBox(height: 8),
              ...insights.map((it) => _InsightCard(item: it)),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Historical Comparison', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: comparisons.map((e) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _HistoryCard(item: e)))).toList()
                  ..removeLast()),
              ),
              const SizedBox(height: 10),
              _ConfidenceCard(percent: confidence),
            ],
          ),
        ),
      ),
    );
  }

  List<_DailyForecastData> _buildDailyForecast(AirQualityModel current, List<AirQualityModel> forecast) {
    final byDay = <String, List<AirQualityModel>>{};
    final all = [current, ...forecast];
    for (final item in all) {
      final key = DateFormat('yyyy-MM-dd').format(item.timestamp);
      byDay.putIfAbsent(key, () => []).add(item);
    }
    final keys = byDay.keys.toList()..sort();
    return keys.take(7).map((key) {
      final dayItems = byDay[key]!;
      final low = dayItems.map((e) => e.aqi).reduce((a, b) => a < b ? a : b);
      final high = dayItems.map((e) => e.aqi).reduce((a, b) => a > b ? a : b);
      final avg = (dayItems.map((e) => e.aqi).reduce((a, b) => a + b) / dayItems.length).round();
      final avgIndex = (dayItems.map((e) => e.aqiIndex).reduce((a, b) => a + b) / dayItems.length).round().clamp(1, 5);
      final date = dayItems.first.timestamp;
      return _DailyForecastData(
        dayLabel: _labelForDate(date),
        quality: _categoryFromIndex(avgIndex),
        low: low,
        high: high,
        current: avg,
      );
    }).toList();
  }

  List<_InsightData> _buildInsights(AirQualityModel current, AirQualityModel predicted) {
    final delta = predicted.aqi - current.aqi;
    final trendTitle = delta >= 0 ? 'Gradual Increase Expected' : 'Air Quality Improvement Ahead';
    final trendText = delta >= 0
        ? 'AQI may rise by $delta points in the next 3 hours.'
        : 'AQI may improve by ${delta.abs()} points in the next 3 hours.';

    final pmText = current.pm25 >= 35
        ? 'PM2.5 is elevated (${current.pm25.toStringAsFixed(1)} µg/m³). Consider reducing outdoor exposure.'
        : 'PM2.5 is currently moderate (${current.pm25.toStringAsFixed(1)} µg/m³).';

    final dominant = {
      'PM2.5': current.pm25,
      'PM10': current.pm10,
      'CO': current.co,
      'NO₂': current.no2,
      'SO₂': current.so2,
      'O₃': current.o3,
    }.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return [
      _InsightData(
        icon: delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        iconColor: delta >= 0 ? const Color(0xFFFF7A00) : const Color(0xFF10B981),
        iconBg: delta >= 0 ? const Color(0xFFFFF4E9) : const Color(0xFFE9FBF1),
        title: trendTitle,
        subtitle: trendText,
      ),
      _InsightData(
        icon: Icons.masks_rounded,
        iconColor: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFEFF6FF),
        title: 'Particle Exposure Insight',
        subtitle: pmText,
      ),
      _InsightData(
        icon: Icons.air_rounded,
        iconColor: const Color(0xFF0EA5E9),
        iconBg: const Color(0xFFE6F9FF),
        title: 'Dominant Pollutant',
        subtitle: '${dominant.key} currently has the highest concentration (${dominant.value.toStringAsFixed(1)}).',
      ),
    ];
  }

  List<_ComparisonData> _buildComparisons(AirQualityModel current, List<AirQualityModel> forecast) {
    int avgWithin(Duration d) {
      final cutoff = DateTime.now().add(d);
      final items = forecast.where((e) => e.timestamp.isBefore(cutoff)).toList();
      if (items.isEmpty) return current.aqi;
      return (items.map((e) => e.aqi).reduce((a, b) => a + b) / items.length).round();
    }

    final v24 = avgWithin(const Duration(hours: 24));
    final v48 = avgWithin(const Duration(hours: 48));
    final v72 = avgWithin(const Duration(hours: 72));

    String deltaText(int value) {
      final diff = value - current.aqi;
      if (diff == 0) return '↔ 0';
      return diff > 0 ? '↗ $diff' : '↘ ${diff.abs()}';
    }

    return [
      _ComparisonData(title: 'Next 24h', value: v24, delta: deltaText(v24), isPositive: v24 <= current.aqi),
      _ComparisonData(title: 'Next 48h', value: v48, delta: deltaText(v48), isPositive: v48 <= current.aqi),
      _ComparisonData(title: 'Next 72h', value: v72, delta: deltaText(v72), isPositive: v72 <= current.aqi),
    ];
  }

  int _buildForecastConfidence(List<AirQualityModel> forecast) {
    if (forecast.length < 2) return 80;
    final values = forecast.take(12).map((e) => e.aqi.toDouble()).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final volatility = variance.sqrtClamped();
    final confidence = (98 - (volatility * 1.2)).round().clamp(70, 98);
    return confidence;
  }

  String _categoryFromIndex(int idx) {
    switch (idx) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Hazardous';
      default:
        return 'Unknown';
    }
  }

  String _labelForDate(DateTime date) {
    final now = DateTime.now();
    final d1 = DateTime(now.year, now.month, now.day);
    final d2 = DateTime(date.year, date.month, date.day);
    final diff = d2.difference(d1).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('EEE').format(date);
  }
}

extension on num {
  double sqrtClamped() {
    if (this <= 0) return 0;
    double x = toDouble();
    double r = x;
    for (int i = 0; i < 10; i++) {
      r = 0.5 * (r + x / r);
    }
    return r;
  }
}

class _PredictionCard extends StatelessWidget {
  final AirQualityModel current;
  final AirQualityModel predicted;

  const _PredictionCard({required this.current, required this.predicted});

  @override
  Widget build(BuildContext context) {
    final delta = predicted.aqi - current.aqi;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7EF7), Color(0xFF8A2BE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text('Next 3 Hours Prediction', style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PredictionPill(label: 'Current', value: current.aqi),
              const SizedBox(width: 10),
              Icon(delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              _PredictionPill(label: 'Predicted', value: predicted.aqi),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            delta >= 0 ? '↑ $delta point increasing' : '↓ ${delta.abs()} point decreasing',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HourlyForecastCard extends StatelessWidget {
  final List<AirQualityModel> items;

  const _HourlyForecastCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final label = index == 0 ? 'Now' : DateFormat('ha').format(item.timestamp).toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5B400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.aqi}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF374151)),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PredictionPill extends StatelessWidget {
  final String label;
  final int value;

  const _PredictionPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFF5B400),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 28),
          ),
        ),
      ],
    );
  }
}

class _DailyForecastData {
  final String dayLabel;
  final String quality;
  final int low;
  final int high;
  final int current;

  const _DailyForecastData({
    required this.dayLabel,
    required this.quality,
    required this.low,
    required this.high,
    required this.current,
  });
}

class _DayForecastCard extends StatelessWidget {
  final _DailyForecastData item;

  const _DayForecastCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isGood = item.quality.toLowerCase() == 'good' || item.quality.toLowerCase() == 'fair';
    final barColor = isGood ? const Color(0xFF10B981) : const Color(0xFFF5B400);
    final normalized = item.high == item.low ? 0.6 : ((item.current - item.low) / (item.high - item.low)).clamp(0.12, 0.95);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.dayLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Text(item.quality, style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: normalized,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Low: ${item.low}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    const Spacer(),
                    Text('High: ${item.high}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 52,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            alignment: Alignment.center,
            child: Text('${item.current}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _InsightData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _InsightData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}

class _InsightCard extends StatelessWidget {
  final _InsightData item;

  const _InsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, size: 18, color: item.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonData {
  final String title;
  final int value;
  final String delta;
  final bool isPositive;

  const _ComparisonData({
    required this.title,
    required this.value,
    required this.delta,
    required this.isPositive,
  });
}

class _HistoryCard extends StatelessWidget {
  final _ComparisonData item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text('${item.value}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFFF5B400))),
          const SizedBox(height: 2),
          Text(
            item.delta,
            style: TextStyle(
              fontSize: 12,
              color: item.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  final int percent;

  const _ConfidenceCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDF3E7)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.show_chart_rounded, size: 16, color: Colors.white),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forecast Confidence', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Model confidence based on forecast consistency', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFBFEBDD),
              color: const Color(0xFF10B981),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0D111827),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );
}
