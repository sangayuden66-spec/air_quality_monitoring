import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_history_item.dart';
import '../services/notification_history_service.dart';
import 'notification_preferences_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final NotificationHistoryService _historyService = NotificationHistoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPreferencesScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationHistoryItem>>(
        stream: _historyService.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No alerts triggered yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: history.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryListItem(item: item, service: _historyService);
            },
          );
        },
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final NotificationHistoryItem item;
  final NotificationHistoryService service;

  const _HistoryListItem({required this.item, required this.service});

  Color _getCategoryColor(int index) {
    switch (index) {
      case 1: return Colors.green;
      case 2: return Colors.yellow.shade700;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return const Color(0xFF7F1D1D);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : Colors.teal.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? Colors.grey.shade200 : Colors.teal.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.aqiIndex).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    color: _getCategoryColor(item.aqiIndex),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM d, h:mm a').format(item.timestamp),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AQI Level ${item.aqiIndex} in ${item.location}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            item.healthAdvice,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const Text(
            'General guidance only. Follow local health and emergency-service advice.',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          if (!item.isRead)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => service.markAsRead(item.id),
                child: const Text('Mark as read', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
