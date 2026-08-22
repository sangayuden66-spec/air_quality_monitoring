import 'package:flutter/material.dart';
import '../core/models/report_item.dart';
import '../core/services/report_service.dart';
import '../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  void _showSubmitDialog() {
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while submitting
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Air Quality Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _locationController,
                enabled: !isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Location (e.g. Woden)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                enabled: !isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'What are you seeing/feeling?',
                ),
                maxLines: 3,
              ),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final loc = _locationController.text.trim();
                      final msg = _textController.text.trim();

                      if (loc.isEmpty || msg.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        // Attempt to submit with a timeout handled in the service
                        await _reportService.submitReport(
                          location: loc,
                          text: msg,
                        );

                        if (mounted) {
                          _locationController.clear();
                          _textController.clear();
                          Navigator.pop(dialogContext); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted successfully!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Submission failed: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ReportItem>>(
        stream: _reportService.getReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading reports: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No reports yet. Be the first to share!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppThemeColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F111827),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF5B6EF0),
                      child: Text(
                        report.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                report.user,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                report.timeAgo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            report.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppThemeColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.text,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildAction(
                                icon: Icons.check_circle_outline,
                                count: report.confirm.toString(),
                                label: 'Confirm',
                                textColor: const Color(0xFF0F9D75),
                                backgroundColor: const Color(0xFFE8F8F1),
                                onTap: () =>
                                    _reportService.confirmReport(report.id),
                              ),
                              const SizedBox(width: 16),
                              _buildAction(
                                icon: Icons.cancel_outlined,
                                count: report.deny.toString(),
                                label: 'Deny',
                                textColor: const Color(0xFFDC2626),
                                backgroundColor: const Color(0xFFFDEDED),
                                onTap: () =>
                                    _reportService.denyReport(report.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSubmitDialog,
        backgroundColor: AppThemeColors.primary,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String count,
    required String label,
    required Color textColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            Text(
              '$count  $label',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
