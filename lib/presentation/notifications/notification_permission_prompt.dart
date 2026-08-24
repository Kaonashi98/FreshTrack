import 'package:flutter/material.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';

Future<void> offerExpirationNotificationPermission({
  required BuildContext context,
  required ExpirationNotificationScheduler scheduler,
}) async {
  final enabled = await scheduler.areNotificationsEnabled();
  if (enabled || !context.mounted) return;

  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Attivare i promemoria?'),
          content: const Text(
            'FreshTrack può avvisarti nel giorno della scadenza e, se lo '
            'imposti, anche nei giorni precedenti. Le notifiche restano sul '
            'dispositivo e non vengono inviate online.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Non ora'),
            ),
            FilledButton(
              key: const Key('confirm-enable-notifications'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Attiva'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) return;

  final granted = await scheduler.requestNotificationPermission();
  if (!context.mounted) return;
  if (!granted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permesso non concesso. Puoi abilitarlo dalle Impostazioni.',
        ),
      ),
    );
  }
}
