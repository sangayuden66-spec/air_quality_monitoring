import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/report_card.dart';
import 'submit_report_sheet.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    this.locationFilter,
  });

  final String currentUserId;
  final String currentUserName;
  final String? locationFilter;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _reportService = ReportService();
  final Set<String> _votedReportIds = {};

  Future<void> _vote(String reportId, String type) async {
    try {
      await _reportService.voteOnReport(
        reportId: reportId,
        userId: widget.currentUserId,
        type: type,
      );
      setState(() => _votedReportIds.add(reportId));
    } on ReportValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubmitReportSheet(
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        defaultLocation: widget.locationFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.locationFilter == null
        ? _reportService.watchReports()
        : _reportService.watchReportsByLocation(widget.locationFilter!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Reports'),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Report>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No reports yet. Be the first to share an air quality update.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ReportCard(
                report: report,
                hasVoted: _votedReportIds.contains(report.id) ||
                    report.userId == widget.currentUserId,
                onConfirm: () => _vote(report.id, 'confirm'),
                onDeny: () => _vote(report.id, 'deny'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSubmitSheet,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Share report'),
      ),
    );
  }
}