import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/support_ticket.dart';
import '../services/it_support_service.dart';

enum _StatusFilter { all, open, inProgress, resolved, pendingAdmin }

extension on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All Statuses';
      case _StatusFilter.open:
        return 'Open';
      case _StatusFilter.inProgress:
        return 'In Progress';
      case _StatusFilter.resolved:
        return 'Resolved';
      case _StatusFilter.pendingAdmin:
        return 'Pending Admin';
    }
  }

  TicketStatus? get status {
    switch (this) {
      case _StatusFilter.all:
        return null;
      case _StatusFilter.open:
        return TicketStatus.open;
      case _StatusFilter.inProgress:
        return TicketStatus.inProgress;
      case _StatusFilter.resolved:
        return TicketStatus.resolved;
      case _StatusFilter.pendingAdmin:
        return TicketStatus.pendingAdmin;
    }
  }
}

enum _CategoryFilter {
  all,
  technicalIssue,
  dataAccuracy,
  featureRequest,
  generalInquiry
}

extension on _CategoryFilter {
  String get label {
    switch (this) {
      case _CategoryFilter.all:
        return 'All Categories';
      case _CategoryFilter.technicalIssue:
        return 'Technical Issue';
      case _CategoryFilter.dataAccuracy:
        return 'Data Accuracy';
      case _CategoryFilter.featureRequest:
        return 'Feature Request';
      case _CategoryFilter.generalInquiry:
        return 'General Inquiry';
    }
  }

  String? get value {
    switch (this) {
      case _CategoryFilter.all:
        return null;
      default:
        return label;
    }
  }

  IconData get icon {
    switch (this) {
      case _CategoryFilter.technicalIssue:
        return Icons.bug_report_outlined;
      case _CategoryFilter.dataAccuracy:
        return Icons.error_outline_rounded;
      case _CategoryFilter.featureRequest:
        return Icons.lightbulb_outline_rounded;
      case _CategoryFilter.generalInquiry:
        return Icons.help_outline_rounded;
      case _CategoryFilter.all:
        return Icons.grid_view_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _CategoryFilter.technicalIssue:
        return const Color(0xFFDC2626);
      case _CategoryFilter.dataAccuracy:
        return const Color(0xFFD97706);
      case _CategoryFilter.featureRequest:
        return const Color(0xFF2563EB);
      case _CategoryFilter.generalInquiry:
        return const Color(0xFF7C3AED);
      case _CategoryFilter.all:
        return AppThemeColors.textPrimary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case _CategoryFilter.technicalIssue:
        return const Color(0xFFFEF2F2);
      case _CategoryFilter.dataAccuracy:
        return const Color(0xFFFFFBEB);
      case _CategoryFilter.featureRequest:
        return const Color(0xFFEFF6FF);
      case _CategoryFilter.generalInquiry:
        return const Color(0xFFF5F3FF);
      case _CategoryFilter.all:
        return const Color(0xFFF3F4F6);
    }
  }
}

class ItSupportScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final bool isActive;

  const ItSupportScreen({super.key, this.onBack, this.isActive = false});

  @override
  State<ItSupportScreen> createState() => _ItSupportScreenState();
}

class _ItSupportScreenState extends State<ItSupportScreen> {
  final ItSupportService _service = ItSupportService();

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      Future.microtask(() => _service.markAllNotificationsAsRead());
    }
  }

  @override
  void didUpdateWidget(covariant ItSupportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _service.markAllNotificationsAsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppThemeColors.textPrimary,
                    ),
                  ),
                  const Icon(
                    Icons.support_agent_rounded,
                    color: AppThemeColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Technical Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: _CategoryFilter.values.map((f) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryTicketsScreen(
                                    category: f,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: f.backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: f.color.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: f.color.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(f.icon, color: f.color, size: 24),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    f.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppThemeColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTicketsScreen extends StatefulWidget {
  final _CategoryFilter category;
  const CategoryTicketsScreen({super.key, required this.category});

  @override
  State<CategoryTicketsScreen> createState() => _CategoryTicketsScreenState();
}

class _CategoryTicketsScreenState extends State<CategoryTicketsScreen> {
  final ItSupportService _service = ItSupportService();
  final TextEditingController _searchController = TextEditingController();
  _StatusFilter _statusFilter = _StatusFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SupportTicket> _applyFilters(List<SupportTicket> tickets) {
    return tickets.where((t) {
      // Status Filter
      if (_statusFilter.status != null && t.status != _statusFilter.status) {
        return false;
      }
      // Category Filter (Always filtered by the category passed to this screen)
      if (widget.category.value != null && t.category != widget.category.value) {
        return false;
      }
      // Search Query
      if (_query.isEmpty) return true;
      
      final ticketNum = (tickets.indexOf(t) + 1).toString();
      return t.requesterName.toLowerCase().contains(_query) ||
          t.subject.toLowerCase().contains(_query) ||
          t.description.toLowerCase().contains(_query) ||
          t.category.toLowerCase().contains(_query) ||
          ticketNum == _query ||
          '#$ticketNum' == _query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppThemeColors.textPrimary),
        ),
        title: Text(
          widget.category.label,
          style: const TextStyle(
            color: AppThemeColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: AppThemeColors.textSecondary),
                  hintText: 'Search tickets...',
                  hintStyle: TextStyle(color: AppThemeColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _StatusFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StatusFilterChip(
                        label: f.label,
                        selected: _statusFilter == f,
                        onTap: () => setState(() => _statusFilter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<SupportTicket>>(
              stream: _service.watchAllTickets(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tickets = snapshot.data!;
                final filtered = _applyFilters(tickets);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppThemeColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No tickets found in this category.',
                          style: TextStyle(color: AppThemeColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ticket = filtered[index];
                    final displayIndex = tickets.indexOf(ticket) + 1;
                    return _TicketCard(
                      number: displayIndex,
                      ticket: ticket,
                      service: _service,
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
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppThemeColors.textPrimary : AppThemeColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppThemeColors.textPrimary
                : AppThemeColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppThemeColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final int number;
  final SupportTicket ticket;
  final ItSupportService service;

  const _TicketCard({
    required this.number,
    required this.ticket,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _TicketDetailsSheet(
            number: number,
            ticket: ticket,
            service: service,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: AppThemeStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$number - ${ticket.requesterName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ticket.priorityBackground,
                    border: Border.all(
                      color: ticket.priorityColor.withOpacity(0.4),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.priorityLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ticket.priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppThemeColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ticket.category,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppThemeColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppThemeColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ticket.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppThemeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ticket.isFilledStatusBadge
                        ? AppThemeColors.textPrimary
                        : const Color(0xFFEEF0F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.statusDisplayLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ticket.isFilledStatusBadge
                          ? Colors.white
                          : AppThemeColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailsSheet extends StatefulWidget {
  final int number;
  final SupportTicket ticket;
  final ItSupportService service;

  const _TicketDetailsSheet({
    required this.number,
    required this.ticket,
    required this.service,
  });

  @override
  State<_TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends State<_TicketDetailsSheet> {
  late final TextEditingController _responseController;
  late final TextEditingController _resolutionController;
  late bool _requiresAdminAttention;
  late TicketStatus _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(text: widget.ticket.itResponse ?? '');
    _resolutionController = TextEditingController(text: widget.ticket.resolution ?? '');
    _requiresAdminAttention = widget.ticket.requiresAdminAttention;
    _selectedStatus = widget.ticket.status;
  }

  @override
  void dispose() {
    _responseController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
           '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _assignToMe() async {
    setState(() => _isSaving = true);
    try {
      await widget.service.assignTicketToMe(widget.ticket.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket assigned to you.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSave() async {
    final response = _responseController.text.trim();
    final resolution = _resolutionController.text.trim();
    final bool isResolving = _selectedStatus == TicketStatus.resolved;

    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an IT response.')),
      );
      return;
    }

    if (isResolving && resolution.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resolution details are required to resolve.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.service.updateTicketProgress(
        ticketId: widget.ticket.id,
        itResponse: response,
        resolution: isResolving ? resolution : null,
        status: _selectedStatus,
        requiresAdminAttention: _requiresAdminAttention,
      );
      
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      
      messenger.showSnackBar(
        SnackBar(content: Text(isResolving ? 'Ticket marked as resolved.' : 'Ticket updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAssigned = widget.ticket.assignedTo != null;
    final bool isResolved = widget.ticket.status == TicketStatus.resolved;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket #${widget.number}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!isAssigned && !isResolved)
                    TextButton.icon(
                      onPressed: _isSaving ? null : _assignToMe,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Assign to Me'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: AppThemeStyles.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Subject', value: widget.ticket.subject),
                    _DetailRow(label: 'User', value: widget.ticket.requesterName),
                    _DetailRow(label: 'Category', value: widget.ticket.category),
                    _DetailRow(label: 'Priority', value: widget.ticket.priorityLabel.toUpperCase()),
                    _DetailRow(label: 'Status', value: widget.ticket.statusDisplayLabel),
                    _DetailRow(label: 'Created', value: _formatDateTime(widget.ticket.createdAt)),
                    _DetailRow(label: 'Last Updated', value: _formatDateTime(widget.ticket.updatedAt)),
                    if (isAssigned)
                      _DetailRow(label: 'Assigned To', value: widget.ticket.assignedToName ?? 'Staff'),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppThemeColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.ticket.description, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isResolved) ...[
                const Text(
                  'IT Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppThemeStyles.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Change Status',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppThemeColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TicketStatus>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: TicketStatus.values.map((status) {
                          String label = '';
                          switch(status) {
                            case TicketStatus.open: label = 'Open'; break;
                            case TicketStatus.inProgress: label = 'In Progress'; break;
                            case TicketStatus.resolved: label = 'Resolved'; break;
                            case TicketStatus.pendingAdmin: label = 'Pending Admin'; break;
                          }
                          return DropdownMenuItem(value: status, child: Text(label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                              if (val == TicketStatus.pendingAdmin) {
                                _requiresAdminAttention = true;
                              } else {
                                _requiresAdminAttention = false;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _responseController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'IT Response (Visible to User)',
                          hintText: 'Describe the current status or investigation...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedStatus == TicketStatus.resolved) ...[
                        TextField(
                          controller: _resolutionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Resolution Details',
                            hintText: 'What was done to solve the issue?',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_selectedStatus != TicketStatus.resolved)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Requires Admin Attention', style: TextStyle(fontSize: 14)),
                          value: _requiresAdminAttention,
                          onChanged: (val) {
                            setState(() {
                              _requiresAdminAttention = val ?? false;
                              if (_requiresAdminAttention && _selectedStatus != TicketStatus.pendingAdmin) {
                                _selectedStatus = TicketStatus.pendingAdmin;
                              } else if (!_requiresAdminAttention && _selectedStatus == TicketStatus.pendingAdmin) {
                                _selectedStatus = TicketStatus.inProgress;
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _selectedStatus == TicketStatus.resolved ? 'Resolve Ticket' : 'Save Update',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Resolution Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: AppThemeStyles.cardDecoration().copyWith(
                    color: const Color(0xFFF0FDF4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(label: 'Resolved By', value: widget.ticket.assignedToName ?? 'Staff'),
                      if (widget.ticket.resolvedAt != null)
                        _DetailRow(label: 'Resolved At', value: _formatDateTime(widget.ticket.resolvedAt!)),
                      const Divider(),
                      const Text(
                        'Final Resolution',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.ticket.resolution ?? 'No resolution recorded.'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppThemeColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppThemeColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
