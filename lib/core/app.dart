import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:freshtrack/core/router/app_router.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/notifications/notification_coordinator.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/app_background.dart';
import 'package:freshtrack/shared/widgets/current_date_scope.dart';

Locale resolveFreshTrackLocale(List<Locale>? locales) {
  final usesItalian =
      locales != null &&
      locales.isNotEmpty &&
      locales.first.languageCode.toLowerCase() == 'it';
  return usesItalian ? const Locale('it') : const Locale('en');
}

class FreshTrackApp extends ConsumerWidget {
  const FreshTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).value ?? AppSettings.defaults;
    final themeMode = switch (settings.themePreference) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
    return DayBoundary(
      child: NotificationCoordinator(
        child: MaterialApp.router(
          title: 'FreshTrack',
          locale: switch (settings.languagePreference) {
            AppLanguagePreference.system => null,
            AppLanguagePreference.italian => const Locale('it'),
            AppLanguagePreference.english => const Locale('en'),
          },
          supportedLocales: const [Locale('it'), Locale('en')],
          localeListResolutionCallback: (locales, supportedLocales) =>
              switch (settings.languagePreference) {
                AppLanguagePreference.system => resolveFreshTrackLocale(
                  locales,
                ),
                AppLanguagePreference.italian => const Locale('it'),
                AppLanguagePreference.english => const Locale('en'),
              },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) =>
              AppBackground(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
