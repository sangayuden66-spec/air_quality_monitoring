import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/support_ticket_service.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  static const int _maxDescriptionLength = 500;
  final SupportTicketService _service = SupportTicketService();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<_CategoryOption> _categories = const [
    _CategoryOption(
      label: 'Technical Issue',
      icon: Icons.bug_report_outlined,
      iconColor: Color(0xFFDC2626),
      background: Color(0xFFFFF1F2),
    ),
    _CategoryOption(
      label: 'Data Accuracy',
      icon: Icons.error_outline_rounded,
      iconColor: Color(0xFFEA580C),
      background: Color(0xFFFFF7ED),
    ),
    _CategoryOption(
      label: 'Feature Request',
      icon: Icons.lightbulb_outline_rounded,
      iconColor: Color(0xFF2563EB),
      background: Color(0xFFEFF6FF),
    ),
    _CategoryOption(
      label: 'General Inquiry',
      icon: Icons.help_outline_rounded,
      iconColor: Color(0xFF7C3AED),
      background: Color(0xFFF5F3FF),
    ),
  ];

  String _selectedCategory = 'Technical Issue';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (_submitting) return;
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a subject.')));
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide issue details.')),
      );
      return;
    }
    if (description.length > _maxDescriptionLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description cannot exceed 500 characters.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.submitTicket(
        category: _selectedCategory,
        subject: subject,
        description: description,
      );
      if (!mounted) return;
      _subjectController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket submitted. IT team has been notified.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit ticket: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _statusLabel(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();
    if (status == 'resolved') return 'Resolved';
    if (status == 'in-progress' || status == 'inprogress') return 'In Progress';
    return 'Open';
  }

  ({Color bg, Color text}) _statusColors(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();
    if (status == 'resolved') {
      return (bg: const Color(0xFFE8F7EE), text: const Color(0xFF15803D));
    }
    if (status == 'in-progress' || status == 'inprogress') {
      return (bg: const Color(0xFFEFF6FF), text: const Color(0xFF1D4ED8));
    }
    return (bg: const Color(0xFFFFF7ED), text: const Color(0xFFB45309));
  }

  String _timeAgo(DateTime createdAt) {
    final delta = DateTime.now().difference(createdAt);
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hours ago';
    return '${delta.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Report a Problem',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppThemeColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'We\'re here to help',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF60A5FA)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Describe your issue in detail and our support team will assist you as soon as possible.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppThemeColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Category *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _categories.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.5,
                        ),
                    itemBuilder: (context, index) {
                      final option = _categories[index];
                      final selected = option.label == _selectedCategory;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedCategory = option.label),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: option.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppThemeColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option.icon,
                                color: option.iconColor,
                                size: 22,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Subject *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      hintText: 'Brief description of the issue',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Description *',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: _maxDescriptionLength,
                    decoration: const InputDecoration(
                      hintText:
                          'Please provide detailed information about your issue...',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Text(
                    '${_descriptionController.text.length}/$_maxDescriptionLength characters',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppThemeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppThemeStyles.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submitTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined, size: 18),
                        label: Text(
                          _submitting ? 'Submitting...' : 'Submit Ticket',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By submitting, you agree to our support terms',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Recent Tickets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<UserSupportTicket>>(
                    stream: _service.watchMyRecentTickets(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppThemeStyles.cardDecoration(),
                          child: Text(
                            'Could not load recent tickets: ${snapshot.error}',
                            style: const TextStyle(
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      final tickets =
                          snapshot.data ?? const <UserSupportTicket>[];
                      if (tickets.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppThemeStyles.cardDecoration(),
                          child: const Text(
                            'No tickets yet. Submit your first support request above.',
                            style: TextStyle(
                              color: AppThemeColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: tickets.map((ticket) {
                          final colors = _statusColors(ticket.status);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: AppThemeStyles.cardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ticket.subject,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.bg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _statusLabel(ticket.status),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: colors.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ticket.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemeColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppThemeColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _timeAgo(ticket.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppThemeColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
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

class _CategoryOption {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;

  const _CategoryOption({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.background,
  });
}
