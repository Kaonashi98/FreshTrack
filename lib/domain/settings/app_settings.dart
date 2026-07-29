enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    required this.themePreference,
    required this.notificationDaysBefore,
    required this.notificationHour,
    required this.notificationMinute,
  });

  static const defaults = AppSettings(
    themePreference: AppThemePreference.dark,
    notificationDaysBefore: 0,
    notificationHour: 9,
    notificationMinute: 0,
  );

  final AppThemePreference themePreference;
  final int notificationDaysBefore;
  final int notificationHour;
  final int notificationMinute;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    int? notificationDaysBefore,
    int? notificationHour,
    int? notificationMinute,
  }) => AppSettings(
    themePreference: themePreference ?? this.themePreference,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    notificationHour: notificationHour ?? this.notificationHour,
    notificationMinute: notificationMinute ?? this.notificationMinute,
  );
}
