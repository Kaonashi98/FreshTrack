import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(appSettingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final privacyCard = GlassSurface(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: scheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(
                'L’inventario resta sul dispositivo. Scegli tu quando creare un backup.',
                'Your inventory stays on your device. You decide when to create a backup.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
    return CustomScrollView(
      key: const Key('settings-scroll'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.paddingOf(context).bottom + 44,
          ),
          sliver: SliverList.list(
            children: [
              Text(
                context.tr('Impostazioni', 'Settings'),
                style: AppTheme.pageTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'FreshTrack, come piace a te.',
                  'FreshTrack, your way.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 26),
              _SettingsSectionLabel(
                context.tr('LA TUA ESPERIENZA', 'YOUR EXPERIENCE'),
              ),
              const SizedBox(height: 10),
              GlassSurface(
                child: Column(
                  children: [
                    _SettingsDestination(
                      key: const Key('appearance-settings'),
                      icon: Icons.palette_outlined,
                      title: context.tr('Aspetto', 'Appearance'),
                      subtitle: settingsState.maybeWhen(
                        data: (settings) =>
                            '${_themeLabel(context, settings.themePreference)} · ${_languageLabel(context, settings.languagePreference)}',
                        orElse: () => context.tr(
                          'Tema, lingua e leggibilità',
                          'Theme, language and readability',
                        ),
                      ),
                      onTap: () => context.push('/settings/appearance'),
                    ),
                    const _SettingsDivider(),
                    _SettingsDestination(
                      key: const Key('notification-settings'),
                      icon: Icons.notifications_active_outlined,
                      title: context.tr('Notifiche', 'Notifications'),
                      subtitle: settingsState.maybeWhen(
                        data: (settings) => context.tr(
                          'Promemoria ${_daysLabelIt(settings.notificationDaysBefore)}',
                          'Reminders ${_daysLabelEn(settings.notificationDaysBefore)}',
                        ),
                        orElse: () => context.tr(
                          'Promemoria di scadenza',
                          'Expiration reminders',
                        ),
                      ),
                      onTap: () => context.push('/settings/notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SettingsSectionLabel(
                context.tr('DATI E INFORMAZIONI', 'DATA AND INFORMATION'),
              ),
              const SizedBox(height: 10),
              GlassSurface(
                child: Column(
                  children: [
                    _SettingsDestination(
                      key: const Key('data-settings'),
                      icon: Icons.backup_outlined,
                      title: context.tr('Dati e backup', 'Data and backup'),
                      subtitle: context.tr(
                        'Salva, ripristina o esporta',
                        'Save, restore or export',
                      ),
                      onTap: () => context.push('/settings/data'),
                    ),
                    const _SettingsDivider(),
                    _SettingsDestination(
                      key: const Key('about-settings'),
                      icon: Icons.info_outline_rounded,
                      title: context.tr(
                        'Privacy e informazioni',
                        'Privacy and information',
                      ),
                      subtitle: context.tr(
                        'Dati, versione e avvertenze',
                        'Data, version and notices',
                      ),
                      onTap: () => context.push('/settings/about'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              privacyCard,
            ],
          ),
        ),
      ],
    );
  }

  static String _daysLabelIt(int days) => switch (days) {
    0 => 'il giorno stesso',
    1 => '1 giorno prima',
    _ => '$days giorni prima',
  };

  static String _daysLabelEn(int days) => switch (days) {
    0 => 'on the same day',
    1 => '1 day before',
    _ => '$days days before',
  };

  static String _themeLabel(BuildContext context, AppThemePreference value) =>
      switch (value) {
        AppThemePreference.system => context.tr('Tema sistema', 'System theme'),
        AppThemePreference.light => context.tr('Tema chiaro', 'Light theme'),
        AppThemePreference.dark => context.tr('Tema scuro', 'Dark theme'),
      };

  static String _languageLabel(
    BuildContext context,
    AppLanguagePreference value,
  ) => switch (value) {
    AppLanguagePreference.system => context.tr(
      'lingua sistema',
      'system language',
    ),
    AppLanguagePreference.italian => context.tr('italiano', 'Italian'),
    AppLanguagePreference.english => context.tr('inglese', 'English'),
  };
}

class _SettingsDestination extends StatelessWidget {
  const _SettingsDestination({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 64,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .3),
  );
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w700,
    ),
  );
}
