import 'package:flutter/material.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/l10n/app_strings.dart';

Future<bool> offerExpirationNotificationPermission({
  required BuildContext context,
  required ExpirationNotificationScheduler scheduler,
}) async {
  final enabled = await scheduler.areNotificationsEnabled();
  if (enabled || !context.mounted) return false;

  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text(
            context.tr('Attivare i promemoria?', 'Enable reminders?'),
          ),
          content: Text(
            context.tr(
              'FreshTrack può avvisarti nel giorno della scadenza e, se lo imposti, anche nei giorni precedenti. Le notifiche restano sul dispositivo e non vengono inviate online.',
              'FreshTrack can alert you on the expiration date and, if configured, in the preceding days. Notifications stay on your device and are not sent online.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Non ora', 'Not now')),
            ),
            FilledButton(
              key: const Key('confirm-enable-notifications'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('Attiva', 'Enable')),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return false;

  final granted = await scheduler.requestNotificationPermission();
  if (!context.mounted) return granted;
  if (!granted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'Permesso non concesso. Puoi abilitarlo dalle Impostazioni.',
            'Permission not granted. You can enable it in Settings.',
          ),
        ),
      ),
    );
  }
  return granted;
}
