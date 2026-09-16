import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Find quick answers below.',
                    style: TextStyle(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...const [
            _FaqTile(
              question: 'How are air quality alerts triggered?',
              answer:
                  'Alerts are triggered when the AQI at your selected location meets or exceeds your threshold in Notification Preferences.',
            ),
            _FaqTile(
              question: 'How do I change my alert location?',
              answer:
                  'Open Notification Preferences, select Alert Location, and choose your place on the map before saving.',
            ),
            _FaqTile(
              question: 'Why am I not receiving notifications?',
              answer:
                  'Check that alerts are enabled in Notification Preferences and that app notifications are allowed in your phone settings.',
            ),
            _FaqTile(
              question: 'Can I update my profile information?',
              answer:
                  'Yes. Use Edit Profile in Settings to update your display name.',
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Support hours: Mon–Fri, 9:00 AM–6:00 PM',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppThemeStyles.cardDecoration(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: AppThemeColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
