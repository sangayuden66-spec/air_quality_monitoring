import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/notification_history_item.dart';
import '../services/notification_history_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

enum _AlertFilterTab { all, alerts }

class _AlertsScreenState extends State<AlertsScreen> {
  final NotificationHistoryService _historyService =
      NotificationHistoryService();
  _AlertFilterTab _selectedTab = _AlertFilterTab.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: StreamBuilder<List<NotificationHistoryItem>>(
        stream: _historyService.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Unable to load notifications right now.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final history = snapshot.data ?? [];
          final unreadCount = history.where((item) => !item.isRead).length;
          final filteredItems = _filterItems(history);

          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  color: AppThemeColors.surface,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                ),
                              ),
                              Text(
                                '$unreadCount unread notifications',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _FilterChip(
                              label: 'All',
                              badge: unreadCount,
                              selected: _selectedTab == _AlertFilterTab.all,
                              onTap: () => setState(
                                () => _selectedTab = _AlertFilterTab.all,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _FilterChip(
                              label: 'Alerts',
                              selected: _selectedTab == _AlertFilterTab.alerts,
                              onTap: () => setState(
                                () => _selectedTab = _AlertFilterTab.alerts,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: AppThemeColors.background,
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No notifications',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredItems.length,
                          padding: const EdgeInsets.all(14),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _HistoryListItem(
                              item: item,
                              service: _historyService,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<NotificationHistoryItem> _filterItems(
    List<NotificationHistoryItem> items,
  ) {
    bool isSummary(NotificationHistoryItem item) {
      final type = item.type.toLowerCase();
      if (type == 'summary') return true;
      return item.category.toLowerCase().contains('summary');
    }

    switch (_selectedTab) {
      case _AlertFilterTab.all:
        return items;
      case _AlertFilterTab.alerts:
        return items.where((item) => !isSummary(item)).toList();
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? badge;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF235DC0)
        : const Color(0xFFD8DEE8);
    final bgColor = selected ? AppThemeColors.primary : AppThemeColors.surface;
    final textColor = selected ? Colors.white : AppThemeColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 2.2 : 1),
          boxShadow: [
            if (selected)
              const BoxShadow(
                color: Color(0x4D0B5E58),
                blurRadius: 10,
                offset: Offset(0, 3),
              )
            else
              const BoxShadow(
                color: Color(0x12000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFE8ECF4),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: selected
                          ? AppThemeColors.primary
                          : const Color(0xFF374151),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final NotificationHistoryItem item;
  final NotificationHistoryService service;

  const _HistoryListItem({required this.item, required this.service});

  ({IconData icon, Color iconColor, Color iconBg, String title}) _meta() {
    final type = item.type.toLowerCase();
    final isHealth =
        type == 'health' ||
        type == 'healthadvice' ||
        item.category.toLowerCase().contains('health');
    final isSummary =
        type == 'summary' || item.category.toLowerCase().contains('summary');

    if (isHealth) {
      return (
        icon: Icons.favorite_border_rounded,
        iconColor: const Color(0xFFEC4899),
        iconBg: const Color(0xFFFCE7F3),
        title: 'Health Advice',
      );
    }
    if (isSummary) {
      return (
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFDBEAFE),
        title: 'Daily Summary',
      );
    }
    if (item.aqi >= 4) {
      return (
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFF6B00),
        iconBg: const Color(0xFFFFEDD5),
        title: 'High Pollution Warning',
      );
    }
    return (
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFFF6B00),
      iconBg: const Color(0xFFFFEDD5),
      title: 'Air Quality Alert',
    );
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd $hh:$min';
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    ({IconData icon, Color iconColor, Color iconBg, String title}) meta,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: meta.iconBg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(meta.icon, color: meta.iconColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          meta.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _detailRow('AQI', '${item.aqi} (${item.category})'),
                  _detailRow('Location', item.locationName),
                  _detailRow('Threshold', item.threshold.toString()),
                  _detailRow('Time', _formatTimestamp(item.createdAt)),
                  _detailRow(
                    'Advice',
                    item.healthAdvice.isNotEmpty
                        ? item.healthAdvice
                        : item.message,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pollutants',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    'PM2.5',
                    (item.pollutants['pm25'] ?? 0.0).toStringAsFixed(2),
                  ),
                  _detailRow(
                    'PM10',
                    (item.pollutants['pm10'] ?? 0.0).toStringAsFixed(2),
                  ),
                  _detailRow(
                    'CO',
                    (item.pollutants['co'] ?? 0.0).toStringAsFixed(2),
                  ),
                  _detailRow(
                    'NO2',
                    (item.pollutants['no2'] ?? 0.0).toStringAsFixed(2),
                  ),
                  _detailRow(
                    'SO2',
                    (item.pollutants['so2'] ?? 0.0).toStringAsFixed(2),
                  ),
                  _detailRow(
                    'O3',
                    (item.pollutants['o3'] ?? 0.0).toStringAsFixed(2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? AppThemeColors.surface : const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D111827),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await service.markAsRead(item.id);
          if (!context.mounted) return;
          _showDetails(context, meta);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: meta.iconBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(meta.icon, color: meta.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          meta.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AQI ${item.aqi} (${item.category}) - ${item.locationName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.healthAdvice.isNotEmpty
                        ? item.healthAdvice
                        : item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _timeAgo(item.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
