import 'package:flutter/material.dart';
import '../models/air_quality_alert.dart';
import '../services/alert_service.dart';
import '../widgets/alert_card.dart';
import 'notification_preferences_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertService _alertService = AlertService();
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: true, // Shows the back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreamBuilder<int>(
                  stream: _alertService.getUnreadCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count unread notifications',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildFilterTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<AirQualityAlert>>(
              stream: _alertService.getAlertsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final alerts = snapshot.data ?? [];
                final filteredAlerts = _filterAlerts(alerts);

                if (filteredAlerts.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredAlerts.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return AlertCard(
                      alert: alert,
                      onTap: () {
                        _alertService.markAsRead(alert.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('All', 0, showBadge: true),
          const SizedBox(width: 8),
          _buildTab('Alerts', 1),
          const SizedBox(width: 8),
          _buildTab('Health', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, {bool showBadge = false}) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F1115) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F1115) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 6),
                StreamBuilder<int>(
                  stream: _alertService.getUnreadCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    );
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  List<AirQualityAlert> _filterAlerts(List<AirQualityAlert> alerts) {
    if (_selectedTabIndex == 0) return alerts;
    if (_selectedTabIndex == 1) {
      return alerts.where((a) => a.type == AlertType.alert).toList();
    }
    if (_selectedTabIndex == 2) {
      return alerts.where((a) => a.type == AlertType.health).toList();
    }
    return alerts;
  }
}
