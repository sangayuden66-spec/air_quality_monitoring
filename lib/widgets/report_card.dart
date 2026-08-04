import 'package:flutter/material.dart';
import '../models/report.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    required this.hasVoted,
    required this.onConfirm,
    required this.onDeny,
  });

  final Report report;
  final bool hasVoted;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _pollutantColor(BuildContext context) {
    switch (report.pollutantType) {
      case 'Smoke':
        return Colors.red.shade100;
      case 'Dust':
        return Colors.orange.shade100;
      case 'Chemical Odour':
        return Colors.purple.shade100;
      default:
        return Colors.blueGrey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    report.userName.isNotEmpty
                        ? report.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.userName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      Text(report.locationName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                if (report.isVerified)
                  const Icon(Icons.verified, color: Colors.teal, size: 18),
                const SizedBox(width: 4),
                Text(_timeAgo(report.submittedAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _pollutantColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(report.pollutantType,
                  style: const TextStyle(fontSize: 11)),
            ),
            const SizedBox(height: 8),
            Text(report.description),
            const SizedBox(height: 10),
            Row(
              children: [
                _VoteButton(
                  icon: Icons.check_circle_outline,
                  label: '${report.confirmCount} Confirm',
                  color: Colors.green,
                  enabled: !hasVoted,
                  onTap: onConfirm,
                ),
                const SizedBox(width: 10),
                _VoteButton(
                  icon: Icons.cancel_outlined,
                  label: '${report.denyCount} Deny',
                  color: Colors.red,
                  enabled: !hasVoted,
                  onTap: onDeny,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 16, color: enabled ? color : Colors.grey),
      label: Text(label,
          style: TextStyle(color: enabled ? color : Colors.grey, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: enabled ? color.withOpacity(0.4) : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}