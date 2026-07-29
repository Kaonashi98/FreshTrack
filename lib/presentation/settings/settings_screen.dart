import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
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
                    SizedBox(
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preavviso predefinito',
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
                          ),
                        ),
                        _CounterButton(
                          tooltip: 'Riduci giorni',
                          icon: Icons.remove_rounded,
                          onPressed: settings.notificationDaysBefore == 0
                              ? null
                              : () => ref
                                    .read(appSettingsProvider.notifier)
                                    .setNotificationDaysBefore(
                                      settings.notificationDaysBefore - 1,
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
                              : () => ref
                                    .read(appSettingsProvider.notifier)
                                    .setNotificationDaysBefore(
                                      settings.notificationDaysBefore + 1,
                                    ),
                        ),
                      ],
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
                        'Gli avvisi arriveranno alle '
                        '${_notificationTimeLabel(settings)}.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _selectNotificationTime(settings),
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
                  subtitle: 'Rimuove definitivamente prodotti e immagini.',
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
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FreshTrack',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Versione 1.0.0 · build 2',
                            key: Key('app-version'),
                          ),
                          SizedBox(height: 2),
                          Text(
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
    if (days == 0) return 'Avvisa il giorno della scadenza.';
    if (days == 1) return 'Avvisa un giorno prima della scadenza.';
    return 'Avvisa $days giorni prima della scadenza.';
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
          'Prodotti, scadenze e immagini verranno rimossi definitivamente.',
      confirmLabel: 'Cancella',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final current = await ref.read(productsProvider.future);
      await ref.read(productRepositoryProvider).clear();
      await _deleteImages(current);
      if (mounted) _showMessage('Tutti i dati sono stati cancellati.');
    } catch (_) {
      if (mounted) _showMessage('Cancellazione non riuscita.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteImages(List<Product> products) async {
    final storage = ref.read(productImageStorageProvider);
    for (final product in products) {
      await storage.delete(product.imagePath);
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
      Text(title, style: Theme.of(context).textTheme.titleLarge),
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
