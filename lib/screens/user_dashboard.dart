import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// Data models (mock for now — will come from Firestore in a later step)
/// ---------------------------------------------------------------------
class AirQualityReading {
  final String locationName;
  final int aqi;
  final double pm25;
  final double pm10;
  final int co;
  final int humidity;

  const AirQualityReading({
    required this.locationName,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.co,
    required this.humidity,
  });

  static AirQualityReading mock() => const AirQualityReading(
    locationName: 'Canberra, Australia',
    aqi: 68,
    pm25: 23.4,
    pm10: 45.8,
    co: 412,
    humidity: 65,
  );
}

class ReportItem {
  final String user;
  final String initials;
  final String location;
  final String text;
  final String time;
  final int confirm;
  final int deny;
  final String status; // pending | verified | hidden

  const ReportItem({
    required this.user,
    required this.initials,
    required this.location,
    required this.text,
    required this.time,
    required this.confirm,
    required this.deny,
    required this.status,
  });

  static List<ReportItem> mockList() => const [
    ReportItem(
      user: 'Yubaraj Thakulla',
      initials: 'YT',
      location: 'Canberra',
      text: 'The air feels really fresh today! Perfect for outdoor activities.',
      time: '5 min ago',
      confirm: 12,
      deny: 1,
      status: 'verified',
    ),
    ReportItem(
      user: 'Sangay Yuden',
      initials: 'SY',
      location: 'Sydney',
      text: 'Heavy traffic causing noticeable smog. Advise staying indoors if sensitive.',
      time: '15 min ago',
      confirm: 8,
      deny: 2,
      status: 'verified',
    ),
  ];
}

/// ---------------------------------------------------------------------
/// AQI categorisation — same thresholds/bands as the rest of the system
/// ---------------------------------------------------------------------
class AqiCategory {
  final String label;
  final String advice;
  final Color color;
  const AqiCategory(this.label, this.advice, this.color);
}

AqiCategory categorizeAqi(int aqi) {
  if (aqi <= 50) {
    return const AqiCategory('Good', 'Air quality is satisfactory. Enjoy outdoor activities.', Color(0xFF22C55E));
  }
  if (aqi <= 100) {
    return const AqiCategory('Moderate', 'Safe for most people. Sensitive groups should take care.', Color(0xFFF5A623));
  }
  if (aqi <= 150) {
    return const AqiCategory('Unhealthy for Sensitive Groups', 'Sensitive groups should limit prolonged outdoor exertion.', Color(0xFFF97316));
  }
  if (aqi <= 200) {
    return const AqiCategory('Unhealthy', 'Consider wearing a mask outdoors. Limit exposure.', Color(0xFFEF4444));
  }
  if (aqi <= 300) {
    return const AqiCategory('Very Unhealthy', 'Avoid outdoor activity. Stay indoors if possible.', Color(0xFF8B5CF6));
  }
  return const AqiCategory('Hazardous', 'Health warning: everyone should avoid outdoor exposure.', Color(0xFF7F1D1D));
}

/// ---------------------------------------------------------------------
/// Screen
/// ---------------------------------------------------------------------
class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key, this.onViewAllReports});

  /// Optional: wire this to switch your bottom nav to the Reports tab.
  final VoidCallback? onViewAllReports;

  @override
  Widget build(BuildContext context) {
    final reading = AirQualityReading.mock();
    final reports = ReportItem.mockList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AqiHeroCard(reading: reading),
            const SizedBox(height: 16),
            _PollutantGrid(reading: reading),
            const SizedBox(height: 16),
            _LiveReportsCard(reports: reports, onViewAll: onViewAllReports),
          ],
        ),
      ),
    );
  }
}

class _AqiHeroCard extends StatelessWidget {
  const _AqiHeroCard({required this.reading});
  final AirQualityReading reading;

  @override
  Widget build(BuildContext context) {
    final cat = categorizeAqi(reading.aqi);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: cat.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(reading.locationName,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Air Quality Index',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${reading.aqi}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1)),
          Text(cat.label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(cat.advice,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PollutantGrid extends StatelessWidget {
  const _PollutantGrid({required this.reading});
  final AirQualityReading reading;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('PM2.5 (µg/m³)', reading.pm25.toStringAsFixed(1)),
      ('PM10 (µg/m³)', reading.pm10.toStringAsFixed(1)),
      ('CO (ppm)', '${reading.co}'),
      ('Humidity', '${reading.humidity}%'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: tiles
          .map((t) => _PollutantTile(label: t.$1, value: t.$2))
          .toList(),
    );
  }
}

class _PollutantTile extends StatelessWidget {
  const _PollutantTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _LiveReportsCard extends StatelessWidget {
  const _LiveReportsCard({required this.reports, this.onViewAll});
  final List<ReportItem> reports;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Live Reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              if (onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('View all', style: TextStyle(fontSize: 12))),
            ],
          ),
          for (final r in reports) _ReportTile(report: r),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});
  final ReportItem report;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFF5B6EF0),
            child: Text(report.initials, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(report.user, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(report.time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Text(report.location, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(report.text, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}