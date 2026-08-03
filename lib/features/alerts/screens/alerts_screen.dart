import 'package:flutter/material.dart';
import '../models/air_quality_alert.dart';
import '../services/alert_service.dart';
import '../widgets/alert_card.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
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
        centerTitle: false,
        actions: const [SizedBox(width: 16)],
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
                  return const Center(child: Text('No notifications found'));
                }

                return ListView.builder(
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return AlertCard(
                      alert: alert,
                      onTap: () {
                        // Handle tap
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Just for UI look
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
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
