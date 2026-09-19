import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _checkingPermission = true;
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPermission());
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(appSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Notifiche', 'Notifications'))),
      body: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.tonal(
            onPressed: () => ref.invalidate(appSettingsProvider),
            child: Text(context.tr('Riprova', 'Try again')),
          ),
        ),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            GlassSurface(
              padding: const EdgeInsets.all(16),
              child: ListTile(
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
                title: Text(
                  context.tr('Promemoria di scadenza', 'Expiration reminders'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_permissionLabel),
                trailing: _checkingPermission
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
                        onPressed: _requestPermission,
                        child: Text(context.tr('Attiva', 'Enable')),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Quando avvisarti', 'When to notify you'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            GlassSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Preavviso', 'Advance notice'),
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _daysLabel(settings.notificationDaysBefore),
                              key: const Key('notification-days-label'),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: context.tr('Riduci giorni', 'Decrease days'),
                        onPressed: settings.notificationDaysBefore == 0
                            ? null
                            : () => _configure(
                                () => ref
                                    .read(appSettingsProvider.notifier)
                                    .adjustNotificationDaysBefore(-1),
                              ),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${settings.notificationDaysBefore}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: context.tr('Aumenta giorni', 'Increase days'),
                        onPressed: settings.notificationDaysBefore == 30
                            ? null
                            : () => _configure(
                                () => ref
                                    .read(appSettingsProvider.notifier)
                                    .adjustNotificationDaysBefore(1),
                              ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    title: Text(
                      context.tr('Ora delle notifiche', 'Notification time'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      context.tr(
                        '${_timeLabel(settings)} · Android può ritardare l’avviso di alcuni minuti.',
                        '${_timeLabel(settings)} · Android may delay the alert by a few minutes.',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _configure(() => _selectTime(settings)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _permissionLabel {
    if (_checkingPermission) {
      return context.tr(
        'Controllo del permesso in corso…',
        'Checking permission…',
      );
    }
    if (_notificationsEnabled == true) {
      return context.tr(
        'Attivi. Gli avvisi restano sul dispositivo.',
        'Enabled. Alerts stay on your device.',
      );
    }
    if (_notificationsEnabled == false) {
      return context.tr(
        'Non attivi. Abilitali per ricevere gli avvisi.',
        'Disabled. Enable them to receive alerts.',
      );
    }
    return context.tr(
      'Stato non disponibile. Tocca Attiva per riprovare.',
      'Status unavailable. Tap Enable to try again.',
    );
  }

  String _daysLabel(int days) => context.strings.isEnglish
      ? switch (days) {
          0 => 'On the expiration date',
          1 => 'One day before expiration',
          _ => '$days days before expiration',
        }
      : switch (days) {
          0 => 'Il giorno della scadenza',
          1 => 'Un giorno prima della scadenza',
          _ => '$days giorni prima della scadenza',
        };

  String _timeLabel(AppSettings settings) =>
      '${settings.notificationHour.toString().padLeft(2, '0')}:'
      '${settings.notificationMinute.toString().padLeft(2, '0')}';

  Future<void> _refreshPermission() async {
    if (mounted) setState(() => _checkingPermission = true);
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
      _checkingPermission = false;
    });
  }

  Future<bool> _requestPermission() async {
    setState(() => _checkingPermission = true);
    bool? granted;
    try {
      granted = await ref
          .read(expirationNotificationSchedulerProvider)
          .requestNotificationPermission();
    } catch (_) {
      granted = null;
    }
    if (!mounted) return granted ?? false;
    setState(() {
      _notificationsEnabled = granted;
      _checkingPermission = false;
    });
    if (granted == null) {
      _message(
        context.tr(
          'Promemoria non disponibili. Riavvia l’app e riprova.',
          'Reminders unavailable. Restart the app and try again.',
        ),
      );
    } else if (!granted) {
      _message(
        context.tr(
          'Permesso non concesso. Puoi abilitarlo dalle impostazioni Android.',
          'Permission not granted. You can enable it in Android settings.',
        ),
      );
    }
    return granted ?? false;
  }

  Future<void> _configure(Future<void> Function() configure) async {
    if (_notificationsEnabled != true) {
      final confirmed = await _confirmPermission();
      if (!confirmed || !mounted) return;
      if (!await _requestPermission() || !mounted) return;
    }
    try {
      await configure();
    } catch (_) {
      if (mounted) {
        _message(
          context.tr(
            'Impostazione non salvata. Il valore precedente è invariato.',
            'Setting not saved. The previous value is unchanged.',
          ),
        );
      }
      return;
    }
    try {
      final result = await ref
          .read(notificationSynchronizationProvider)
          .synchronizeLatest();
      if (!result.isComplete && mounted) {
        _message(
          context.tr(
            'Impostazione salvata, ma alcuni promemoria non sono stati aggiornati.',
            'Setting saved, but some reminders were not updated.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _message(
          context.tr(
            'Impostazione salvata. I promemoria verranno riallineati alla prossima apertura.',
            'Setting saved. Reminders will be synchronized the next time the app opens.',
          ),
        );
      }
    }
  }

  Future<void> _selectTime(AppSettings settings) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
      helpText: context.tr('Ora delle notifiche', 'Notification time'),
      confirmText: context.tr('Conferma', 'Confirm'),
      cancelText: context.tr('Annulla', 'Cancel'),
    );
    if (selected == null || !mounted) return;
    await ref
        .read(appSettingsProvider.notifier)
        .setNotificationTime(hour: selected.hour, minute: selected.minute);
  }

  Future<bool> _confirmPermission() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(
            context.tr('Attivare i promemoria?', 'Enable reminders?'),
          ),
          content: Text(
            context.tr(
              'FreshTrack userà le notifiche solo per ricordarti le scadenze. Nessun dato viene inviato online.',
              'FreshTrack will use notifications only to remind you about expiration dates. No data is sent online.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('Annulla', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('Continua', 'Continue')),
            ),
          ],
        ),
      ) ??
      false;

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
