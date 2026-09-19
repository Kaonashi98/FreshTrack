import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(appSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Aspetto', 'Appearance'))),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _SettingsError(onRetry: () => ref.invalidate(appSettingsProvider)),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(
              context.tr('Tema dell’app', 'App theme'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Segui il telefono oppure scegli un aspetto fisso.',
                'Follow your phone or choose a fixed appearance.',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(8),
              child: RadioGroup<AppThemePreference>(
                groupValue: settings.themePreference,
                onChanged: (value) async {
                  if (value != null) {
                    try {
                      await ref
                          .read(appSettingsProvider.notifier)
                          .setThemePreference(value);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                'Tema non salvato. Riprova.',
                                'Theme not saved. Try again.',
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                child: Column(
                  key: const Key('theme-selector'),
                  children: [
                    for (final option in AppThemePreference.values)
                      RadioListTile<AppThemePreference>(
                        value: option,
                        secondary: Icon(_themeIcon(option)),
                        title: Text(_themeLabel(context, option)),
                        subtitle: Text(_themeDescription(context, option)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.tr('Lingua', 'Language'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Segui la lingua del telefono oppure scegli italiano o inglese.',
                'Follow your phone language or choose Italian or English.',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface(
              padding: const EdgeInsets.all(8),
              child: RadioGroup<AppLanguagePreference>(
                groupValue: settings.languagePreference,
                onChanged: (value) async {
                  if (value == null) return;
                  try {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .setLanguagePreference(value);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr(
                              'Lingua non salvata. Riprova.',
                              'Language not saved. Try again.',
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Column(
                  key: const Key('language-selector'),
                  children: [
                    for (final option in AppLanguagePreference.values)
                      RadioListTile<AppLanguagePreference>(
                        value: option,
                        secondary: Icon(_languageIcon(option)),
                        title: Text(_languageLabel(context, option)),
                        subtitle: Text(_languageDescription(context, option)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _themeIcon(AppThemePreference value) => switch (value) {
    AppThemePreference.system => Icons.brightness_auto_rounded,
    AppThemePreference.light => Icons.light_mode_rounded,
    AppThemePreference.dark => Icons.dark_mode_rounded,
  };

  static String _themeLabel(BuildContext context, AppThemePreference value) =>
      switch (value) {
        AppThemePreference.system => context.tr('Sistema', 'System'),
        AppThemePreference.light => context.tr('Chiaro', 'Light'),
        AppThemePreference.dark => context.tr('Scuro', 'Dark'),
      };

  static String _themeDescription(
    BuildContext context,
    AppThemePreference value,
  ) => switch (value) {
    AppThemePreference.system => context.tr(
      'Si adatta alle impostazioni del telefono',
      'Matches your phone settings',
    ),
    AppThemePreference.light => context.tr(
      'Sfondo chiaro, anche di sera',
      'Light background, even at night',
    ),
    AppThemePreference.dark => context.tr(
      'Sfondo scuro, anche di giorno',
      'Dark background, even during the day',
    ),
  };

  static IconData _languageIcon(AppLanguagePreference value) => switch (value) {
    AppLanguagePreference.system => Icons.language_rounded,
    AppLanguagePreference.italian => Icons.flag_outlined,
    AppLanguagePreference.english => Icons.translate_rounded,
  };

  static String _languageLabel(
    BuildContext context,
    AppLanguagePreference value,
  ) => switch (value) {
    AppLanguagePreference.system => context.tr('Sistema', 'System'),
    AppLanguagePreference.italian => 'Italiano',
    AppLanguagePreference.english => 'English',
  };

  static String _languageDescription(
    BuildContext context,
    AppLanguagePreference value,
  ) => switch (value) {
    AppLanguagePreference.system => context.tr(
      'Italiano se il telefono è in italiano, altrimenti inglese',
      'Italian when your phone is in Italian, otherwise English',
    ),
    AppLanguagePreference.italian => context.tr(
      'Usa sempre l’italiano',
      'Always use Italian',
    ),
    AppLanguagePreference.english => context.tr(
      'Usa sempre l’inglese',
      'Always use English',
    ),
  };
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.tonal(
      onPressed: onRetry,
      child: Text(context.tr('Riprova', 'Try again')),
    ),
  );
}
