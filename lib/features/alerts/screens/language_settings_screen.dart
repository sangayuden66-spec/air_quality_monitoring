import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/language_preference.dart';
import '../services/language_preference_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final LanguagePreferenceService _service = LanguagePreferenceService();
  bool _isUpdating = false;

  static const List<({String code, String label})> _languageOptions = [
    (code: 'en_US', label: 'English (US)'),
    (code: 'en_GB', label: 'English (UK)'),
    (code: 'ne_NP', label: 'Nepali'),
    (code: 'hi_IN', label: 'Hindi'),
  ];

  Future<void> _updateLanguage(String code) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await _service.savePreference(LanguagePreference(languageCode: code));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Language saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update language: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Language')),
      body: StreamBuilder<LanguagePreference>(
        stream: _service.watchPreference(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final selectedCode =
              snapshot.data?.languageCode ?? LanguagePreference.defaults.languageCode;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                decoration: AppThemeStyles.cardDecoration(),
                child: Column(
                  children: _languageOptions.map((option) {
                    final isSelected = selectedCode == option.code;
                    return ListTile(
                      enabled: !_isUpdating,
                      onTap: _isUpdating || isSelected
                          ? null
                          : () => _updateLanguage(option.code),
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected
                            ? AppThemeColors.primary
                            : AppThemeColors.textSecondary,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Selected language is saved to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemeColors.textSecondary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
