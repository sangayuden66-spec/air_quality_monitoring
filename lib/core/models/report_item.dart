class ReportItem {
  final String user;
  final String initials;
  final String location;
  final String text;
  final String time;
  final int confirm;
  final int deny;
  final String status; // pending | verified | hidden

  const ReportItem({
    required this.user,
    required this.initials,
    required this.location,
    required this.text,
    required this.time,
    required this.confirm,
    required this.deny,
    required this.status,
  });

  static List<ReportItem> mockList() => const [
        ReportItem(
          user: 'Yubaraj Thakulla',
          initials: 'YT',
          location: 'Canberra',
          text: 'The air feels really fresh today! Perfect for outdoor activities.',
          time: '5 min ago',
          confirm: 12,
          deny: 1,
          status: 'verified',
        ),
        ReportItem(
          user: 'Sangay Yuden',
          initials: 'SY',
          location: 'Sydney',
          text: 'Heavy traffic causing noticeable smog. Advise staying indoors if sensitive.',
          time: '15 min ago',
          confirm: 8,
          deny: 2,
          status: 'verified',
        ),
      ];
}
