enum AppThemePreference { system, light, dark }

enum AppLanguagePreference { system, italian, english }

extension AppLanguagePreferenceLocale on AppLanguagePreference {
  String? get languageCode => switch (this) {
    AppLanguagePreference.system => null,
    AppLanguagePreference.italian => 'it',
    AppLanguagePreference.english => 'en',
  };
}

extension AppThemePreferenceLabel on AppThemePreference {
  String get label => switch (this) {
    AppThemePreference.system => 'Sistema',
    AppThemePreference.light => 'Chiaro',
    AppThemePreference.dark => 'Scuro',
  };
}

class AppSettings {
  const AppSettings({
    required this.themePreference,
    required this.languagePreference,
    required this.notificationDaysBefore,
    required this.notificationHour,
    required this.notificationMinute,
    this.preferExactNotificationTime = false,
  });

  static const defaults = AppSettings(
    themePreference: AppThemePreference.dark,
    languagePreference: AppLanguagePreference.system,
    notificationDaysBefore: 0,
    notificationHour: 9,
    notificationMinute: 0,
    preferExactNotificationTime: false,
  );

  final AppThemePreference themePreference;
  final AppLanguagePreference languagePreference;
  final int notificationDaysBefore;
  final int notificationHour;
  final int notificationMinute;
  final bool preferExactNotificationTime;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppLanguagePreference? languagePreference,
    int? notificationDaysBefore,
    int? notificationHour,
    int? notificationMinute,
    bool? preferExactNotificationTime,
  }) => AppSettings(
    themePreference: themePreference ?? this.themePreference,
    languagePreference: languagePreference ?? this.languagePreference,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    notificationHour: notificationHour ?? this.notificationHour,
    notificationMinute: notificationMinute ?? this.notificationMinute,
    preferExactNotificationTime:
        preferExactNotificationTime ?? this.preferExactNotificationTime,
  );
}
