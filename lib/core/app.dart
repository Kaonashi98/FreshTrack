import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:freshtrack/core/router/app_router.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/notifications/notification_coordinator.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/app_background.dart';

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
    return NotificationCoordinator(
      child: MaterialApp.router(
        title: 'FreshTrack',
        locale: const Locale('it', 'IT'),
        supportedLocales: const [Locale('it', 'IT')],
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
    );
  }
}
