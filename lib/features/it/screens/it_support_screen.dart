import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/support_ticket.dart';
import '../services/it_support_service.dart';

enum _TicketFilter { all, open, inProgress, resolved }

extension on _TicketFilter {
  String get label {
    switch (this) {
      case _TicketFilter.all:
        return 'All';
      case _TicketFilter.open:
        return 'Open';
      case _TicketFilter.inProgress:
        return 'In Progress';
      case _TicketFilter.resolved:
        return 'Resolved';
    }
  }

  TicketStatus? get status {
    switch (this) {
      case _TicketFilter.all:
        return null;
      case _TicketFilter.open:
        return TicketStatus.open;
      case _TicketFilter.inProgress:
        return TicketStatus.inProgress;
      case _TicketFilter.resolved:
        return TicketStatus.resolved;
    }
  }
}

class ItSupportScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ItSupportScreen({super.key, this.onBack});

  @override
  State<ItSupportScreen> createState() => _ItSupportScreenState();
}

class _ItSupportScreenState extends State<ItSupportScreen> {
  final ItSupportService _service = ItSupportService();
  final TextEditingController _searchController = TextEditingController();
  _TicketFilter _filter = _TicketFilter.all;
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
      if (_filter.status != null && t.status != _filter.status) return false;
      if (_query.isEmpty) return true;
      return t.requesterName.toLowerCase().contains(_query) ||
          t.description.toLowerCase().contains(_query) ||
          t.category.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack ??
                            () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back,
                        color: AppThemeColors.textPrimary),
                  ),
                  const Icon(Icons.help_outline_rounded,
                      color: AppThemeColors.textPrimary),
                  const SizedBox(width: 8),
                  const Text(
                    'Technical Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    hintStyle: TextStyle(color: AppThemeColors.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _TicketFilter.values
                    .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: f.label,
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<SupportTicket>>(
                stream: _service.watchAllTickets(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tickets = _applyFilters(snapshot.data!);
                  if (tickets.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tickets match this filter.',
                        style: TextStyle(color: AppThemeColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      return _TicketCard(
                        number: index + 1,
                        ticket: tickets[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
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
            color: selected ? AppThemeColors.textPrimary : AppThemeColors.border,
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

  const _TicketCard({required this.number, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppThemeStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '#$number - ${ticket.requesterName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ticket.priorityBackground,
                  border: Border.all(color: ticket.priorityColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ticket.priorityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ticket.priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(ticket.description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 13, color: AppThemeColors.textSecondary),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ticket.isFilledStatusBadge
                      ? AppThemeColors.textPrimary
                      : const Color(0xFFEEF0F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ticket.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
    );
  }
}