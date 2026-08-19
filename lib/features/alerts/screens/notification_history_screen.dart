import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_history_item.dart';
import '../services/notification_history_service.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = NotificationHistoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<NotificationHistoryItem>>(
        stream: historyService.getHistoryStream(),
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
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No alert history found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryCard(item: item, service: historyService);
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final NotificationHistoryItem item;
  final NotificationHistoryService service;

  const _HistoryCard({required this.item, required this.service});

  Color _getCategoryColor(int index) {
    switch (index) {
      case 1: return Colors.green;
      case 2: return Colors.yellow.shade700;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: item.isRead ? Colors.grey.shade200 : Colors.teal.shade200),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => service.markAsRead(item.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(item.aqiIndex).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: _getCategoryColor(item.aqiIndex),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(item.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'AQI Level: ${item.aqiIndex} in ${item.location}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                item.healthAdvice,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const Text(
                'General guidance only. Follow local health and emergency-service advice.',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
