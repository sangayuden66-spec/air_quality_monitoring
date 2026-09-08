import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsAndPrivacyScreen extends StatelessWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: const [
          _PolicySection(
            title: 'Terms of Use',
            content:
                'By using AirSense, you agree to use the app responsibly and in compliance with local regulations. Air quality data is provided for informational purposes and should not replace professional medical or safety advice.',
          ),
          SizedBox(height: 12),
          _PolicySection(
            title: 'Data We Collect',
            content:
                'We store account details, alert preferences, and app settings required to provide core features. Depending on your privacy choices, anonymous analytics and crash diagnostics may also be collected.',
          ),
          SizedBox(height: 12),
          _PolicySection(
            title: 'How We Use Data',
            content:
                'Your data is used to deliver AQI alerts, personalize your in-app experience, and improve reliability. We do not sell your personal information.',
          ),
          SizedBox(height: 12),
          _PolicySection(
            title: 'Your Controls',
            content:
                'You can manage data-sharing permissions in Privacy Settings and adjust notification behavior in Notification Preferences at any time.',
          ),
          SizedBox(height: 12),
          _PolicySection(
            title: 'Contact',
            content:
                'If you have policy questions, open Contact Support from Settings and submit a request.',
          ),
          SizedBox(height: 16),
          Text(
            'Last updated: September 2026',
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

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppThemeStyles.cardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppThemeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
