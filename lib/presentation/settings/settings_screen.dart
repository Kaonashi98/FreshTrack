import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  bool _checkingNotificationPermission = true;
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _refreshNotificationPermission(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(appSettingsProvider);
    final settings = settingsState.value;
    if (settings == null) {
      return Center(
        child: settingsState.hasError
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Impostazioni non disponibili.'),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(appSettingsProvider),
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      );
    }
    return CustomScrollView(
      key: const Key('settings-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 116),
          sliver: SliverList.list(
            children: [
              Text(
                'Impostazioni',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Personalizza FreshTrack e gestisci i tuoi dati.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(icon: Icons.palette_outlined, title: 'Aspetto'),
              const SizedBox(height: 10),
              GlassSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tema dell’app',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Puoi usare un tema fisso oppure seguire il telefono.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useVertical =
                            constraints.maxWidth < 340 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.5;
                        if (useVertical) {
                          return Column(
                            key: const Key('theme-selector'),
                            children: [
                              for (final option in AppThemePreference.values)
                                ListTile(
                                  leading: Icon(
                                    settings.themePreference == option
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                  ),
                                  title: Text(_themeLabel(option)),
                                  selected: settings.themePreference == option,
                                  onTap: () => ref
                                      .read(appSettingsProvider.notifier)
                                      .setThemePreference(option),
                                ),
                            ],
                          );
                        }
                        return SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<AppThemePreference>(
                            key: const Key('theme-selector'),
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: AppThemePreference.system,
                                icon: Icon(Icons.brightness_auto_rounded),
                                label: Text('Sistema'),
                              ),
                              ButtonSegment(
                                value: AppThemePreference.light,
                                icon: Icon(Icons.light_mode_rounded),
                                label: Text('Chiaro'),
                              ),
                              ButtonSegment(
                                value: AppThemePreference.dark,
                                icon: Icon(Icons.dark_mode_rounded),
                                label: Text('Scuro'),
                              ),
                            ],
                            selected: {settings.themePreference},
                            onSelectionChanged: (selection) => ref
                                .read(appSettingsProvider.notifier)
                                .setThemePreference(selection.single),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.notifications_active_outlined,
                title: 'Notifiche',
              ),
              const SizedBox(height: 10),
              GlassSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      key: const Key('notification-permission'),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _notificationsEnabled == true
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        color: _notificationsEnabled == true
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: const Text(
                        'Promemoria di scadenza',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(_notificationPermissionLabel),
                      trailing: _checkingNotificationPermission
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _notificationsEnabled == true
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : FilledButton.tonal(
                              key: const Key('enable-notifications'),
                              onPressed: _requestNotificationPermission,
                              child: const Text('Attiva'),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: .28),
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final controls = <Widget>[
                          _CounterButton(
                            tooltip: 'Riduci giorni',
                            icon: Icons.remove_rounded,
                            onPressed: settings.notificationDaysBefore == 0
                                ? null
                                : () => _configureNotifications(
                                    () => ref
                                        .read(appSettingsProvider.notifier)
                                        .setNotificationDaysBefore(
                                          settings.notificationDaysBefore - 1,
                                        ),
                                  ),
                          ),
                          SizedBox(
                            width: 42,
                            child: Text(
                              '${settings.notificationDaysBefore}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          _CounterButton(
                            tooltip: 'Aumenta giorni',
                            icon: Icons.add_rounded,
                            onPressed: settings.notificationDaysBefore == 30
                                ? null
                                : () => _configureNotifications(
                                    () => ref
                                        .read(appSettingsProvider.notifier)
                                        .setNotificationDaysBefore(
                                          settings.notificationDaysBefore + 1,
                                        ),
                                  ),
                          ),
                        ];
                        final label = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preavviso',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _notificationLabel(
                                settings.notificationDaysBefore,
                              ),
                              key: const Key('notification-days-label'),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                        if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                            constraints.maxWidth < 300) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label,
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: controls,
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: label),
                            ...controls,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: .28),
                    ),
                    ListTile(
                      key: const Key('notification-time'),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.access_time_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text(
                        'Ora delle notifiche',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Gli avvisi partiranno verso le '
                        '${_notificationTimeLabel(settings)}. Android può '
                        'ritardarli di alcuni minuti.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _configureNotifications(
                        () => _selectNotificationTime(settings),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(icon: Icons.storage_rounded, title: 'Dati'),
              const SizedBox(height: 10),
              GlassSurface(
                padding: const EdgeInsets.all(8),
                child: _SettingsAction(
                  key: const Key('clear-data'),
                  icon: Icons.delete_forever_outlined,
                  title: 'Cancella tutti i dati',
                  subtitle: 'Rimuove prodotti, immagini e preferenze dell’app.',
                  color: AppTheme.danger,
                  onTap: _busy ? null : _clearData,
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.info_outline_rounded,
                title: 'Informazioni',
              ),
              const SizedBox(height: 10),
              GlassSurface(
                padding: const EdgeInsets.all(8),
                child: _SettingsAction(
                  key: const Key('privacy-policy'),
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  subtitle: 'Scopri come FreshTrack protegge i tuoi dati.',
                  onTap: () => context.push('/settings/privacy'),
                ),
              ),
              const SizedBox(height: 14),
              GlassSurface(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'FreshTrack è uno strumento di organizzazione personale. '
                  'Non fornisce consigli medici e non sostituisce il parere '
                  'di un medico o di un farmacista.',
                  key: const Key('medical-disclaimer'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GlassSurface(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FreshTrack',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ref
                                .watch(appVersionLabelProvider)
                                .maybeWhen(
                                  data: (label) => label,
                                  orElse: () => 'Versione 1.0.0',
                                ),
                            key: const Key('app-version'),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Offline-first · I dati restano sul dispositivo',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _notificationLabel(int days) {
    if (days == 0) {
      return 'Avvisa il giorno della scadenza, per tutti i prodotti.';
    }
    if (days == 1) {
      return 'Avvisa un giorno prima della scadenza, per tutti i prodotti.';
    }
    return 'Avvisa $days giorni prima della scadenza, per tutti i prodotti.';
  }

  String _themeLabel(AppThemePreference value) => switch (value) {
    AppThemePreference.system => 'Sistema',
    AppThemePreference.light => 'Chiaro',
    AppThemePreference.dark => 'Scuro',
  };

  String get _notificationPermissionLabel {
    if (_checkingNotificationPermission) {
      return 'Controllo del permesso in corso…';
    }
    if (_notificationsEnabled == true) {
      return 'Attivi. Gli avvisi restano sul dispositivo.';
    }
    if (_notificationsEnabled == false) {
      return 'Non attivi. Abilitali per ricevere gli avvisi.';
    }
    return 'Stato non disponibile. Tocca Attiva per riprovare.';
  }

  Future<void> _refreshNotificationPermission() async {
    if (mounted) setState(() => _checkingNotificationPermission = true);
    bool? enabled;
    try {
      enabled = await ref
          .read(expirationNotificationSchedulerProvider)
          .areNotificationsEnabled();
    } catch (_) {
      enabled = null;
    }
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _checkingNotificationPermission = false;
    });
  }

  Future<bool> _requestNotificationPermission() async {
    setState(() => _checkingNotificationPermission = true);
    var granted = false;
    try {
      granted = await ref
          .read(expirationNotificationSchedulerProvider)
          .requestNotificationPermission();
    } catch (_) {
      granted = false;
    }
    if (!mounted) return granted;
    setState(() {
      _notificationsEnabled = granted;
      _checkingNotificationPermission = false;
    });
    if (!granted) {
      _showMessage(
        'Permesso non concesso. Puoi abilitarlo dalle impostazioni Android.',
      );
    }
    return granted;
  }

  Future<void> _configureNotifications(
    Future<void> Function() configure,
  ) async {
    if (_notificationsEnabled != true) {
      final confirmed = await _confirm(
        title: 'Attivare i promemoria?',
        message:
            'FreshTrack userà le notifiche solo per ricordarti le scadenze. '
            'Nessun dato viene inviato online.',
        confirmLabel: 'Continua',
      );
      if (!confirmed || !mounted) return;
      final granted = await _requestNotificationPermission();
      if (!granted || !mounted) return;
    }
    try {
      await configure();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Impostazione non salvata. Il valore precedente è invariato.',
        );
      }
      return;
    }
    try {
      final result = await ref
          .read(notificationSynchronizationProvider)
          .synchronizeLatest();
      if (!result.isComplete && mounted) {
        _showMessage(
          'Impostazione salvata, ma alcuni promemoria non sono stati aggiornati.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Impostazione salvata. I promemoria verranno riallineati alla prossima apertura.',
        );
      }
    }
  }

  String _notificationTimeLabel(AppSettings settings) =>
      '${settings.notificationHour.toString().padLeft(2, '0')}:'
      '${settings.notificationMinute.toString().padLeft(2, '0')}';

  Future<void> _selectNotificationTime(AppSettings settings) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
      helpText: 'Ora delle notifiche',
      confirmText: 'Conferma',
      cancelText: 'Annulla',
    );
    if (selected == null || !mounted) return;
    await ref
        .read(appSettingsProvider.notifier)
        .setNotificationTime(hour: selected.hour, minute: selected.minute);
  }

  Future<void> _clearData() async {
    final confirmed = await _confirm(
      title: 'Cancellare tutti i dati?',
      message:
          'Prodotti, scadenze, immagini e preferenze verranno rimossi '
          'definitivamente.',
      confirmLabel: 'Cancella',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(productRepositoryProvider).clear();
      final incomplete = <String>[];
      try {
        await ref.read(productImageStorageProvider).deleteAll();
      } catch (_) {
        incomplete.add('alcune immagini');
      }
      try {
        await ref.read(appSettingsProvider.notifier).reset();
      } catch (_) {
        incomplete.add('le preferenze');
      }
      if (!mounted) return;
      if (incomplete.isEmpty) {
        _showMessage('Tutti i dati sono stati cancellati.');
      } else {
        _showMessage(
          'Prodotti cancellati, ma non è stato possibile rimuovere '
          '${incomplete.join(' e ')}. Riprova.',
        );
      }
    } catch (_) {
      if (mounted) _showMessage('Cancellazione non riuscita.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: AppTheme.danger)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: effectiveColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: effectiveColor),
    );
  }
}
