class LanguagePreference {
  final String languageCode;

  const LanguagePreference({required this.languageCode});

  static const LanguagePreference defaults = LanguagePreference(
    languageCode: 'en_US',
  );

  Map<String, dynamic> toMap() => {'languageCode': languageCode};

  factory LanguagePreference.fromMap(Map<String, dynamic>? map) {
    final code = map?['languageCode'];
    if (code is String && code.trim().isNotEmpty) {
      return LanguagePreference(languageCode: code.trim());
    }
    return defaults;
  }
}
