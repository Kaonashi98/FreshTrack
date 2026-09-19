import 'package:flutter/material.dart';
import 'package:freshtrack/l10n/app_strings.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const lastUpdated = '15 settembre 2026';

  @override
  Widget build(BuildContext context) {
    final english = context.strings.isEnglish;
    final sections = english ? _englishSections : _italianSections;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Privacy'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            for (final section in sections)
              _PrivacySection(title: section.$1, body: section.$2),
          ],
        ),
      ),
    );
  }

  static const _italianSections = <(String, String)>[
    (
      'L’inventario resta sul dispositivo',
      'FreshTrack non richiede un account, non mostra pubblicità e non integra sistemi pubblicitari o di profilazione. Prodotti, scadenze, fotografie e preferenze, inclusa la lingua, vengono conservati localmente e non sono inviati allo sviluppatore.',
    ),
    (
      'Permessi',
      'La fotocamera viene usata solo su tua richiesta per scansionare un codice a barre, fotografare un prodotto o leggere una scadenza. In alternativa puoi scegliere una foto con il selettore di sistema. Le notifiche servono per i promemoria; il permesso di avvio completato consente ad Android di ripristinarli dopo un riavvio.',
    ),
    (
      'Funzioni online opzionali',
      'Solo quando richiedi una ricerca barcode, FreshTrack invia quel codice e la lingua della richiesta a Open Food Facts tramite HTTPS per cercare i dati del prodotto. Il servizio riceve anche i normali dati tecnici della connessione, come l’indirizzo IP e lo User-Agent dell’app. Non vengono inviati inventario, fotografie o date. Se la rete non è disponibile, puoi continuare compilando i dati a mano.',
    ),
    (
      'Foto, OCR e metriche tecniche',
      'Il riconoscimento del testo nelle immagini avviene sul dispositivo: immagini, testo riconosciuto e data proposta non vengono inviati a Google. Gli SDK Google ML Kit possono però inviare tramite HTTPS informazioni tecniche su dispositivo e app, identificatori per installazione, prestazioni, utilizzo, eventi ed errori, per diagnostica e miglioramento del servizio.',
    ),
    (
      'Backup e condivisione',
      'Backup ZIP e CSV vengono creati solo su tua richiesta e salvati nella posizione scelta tramite Android. Non sono cifrati da FreshTrack: conservali in un luogo sicuro. Il backup Android e il trasferimento automatico tra dispositivi sono disabilitati.',
    ),
    (
      'Controllo',
      'Puoi eliminare singoli prodotti oppure cancellare prodotti, immagini e preferenze dalle Impostazioni. Puoi creare un backup completo prima di disinstallare e ripristinarlo in seguito. Senza un backup, la disinstallazione rimuove i dati conservati localmente.',
    ),
    (
      'Uso dell’app',
      'FreshTrack è uno strumento di organizzazione personale. Non è un dispositivo medico e non diagnostica, tratta, cura o previene alcuna patologia. Per pareri medici, diagnosi o trattamenti, consulta un medico, un farmacista o un altro professionista sanitario qualificato.',
    ),
    (
      'Contatti',
      'Per richieste relative alla privacy o all’assistenza: freshtrack.help@outlook.com. Sviluppatore: Nicola Zingaro.',
    ),
    ('Ultimo aggiornamento', '15 settembre 2026'),
  ];

  static const _englishSections = <(String, String)>[
    (
      'Your inventory stays on your device',
      'FreshTrack does not require an account, show ads, or include advertising or profiling systems. Products, expiration dates, photographs and preferences, including language, are stored locally and are not sent to the developer.',
    ),
    (
      'Permissions',
      'The camera is used only at your request to scan a barcode, photograph a product or read an expiration date. Alternatively, you can choose a photo with the system picker. Notifications are used for reminders; the completed-boot permission allows Android to restore them after a restart.',
    ),
    (
      'Optional online features',
      'Only when you request a barcode lookup does FreshTrack send that code and the request language to Open Food Facts over HTTPS to retrieve product data. The service also receives ordinary connection data such as the IP address and the app User-Agent. Your inventory, photographs and dates are not sent. If the network is unavailable, you can continue by entering the data manually.',
    ),
    (
      'Photos, OCR and technical metrics',
      'Text recognition runs on the device: images, recognized text and the proposed date are not sent to Google. Google ML Kit SDKs may, however, send technical information about the device and app, per-installation identifiers, performance, usage, events and errors over HTTPS for diagnostics and service improvement.',
    ),
    (
      'Backup and sharing',
      'ZIP backups and CSV files are created only at your request and saved to the location you choose through Android. FreshTrack does not encrypt them: keep them in a safe place. Android backup and automatic transfer between devices are disabled.',
    ),
    (
      'Control',
      'You can delete individual products or clear products, images and preferences from Settings. You can create a full backup before uninstalling and restore it later. Without a backup, uninstalling removes locally stored data.',
    ),
    (
      'Use of the app',
      'FreshTrack is a personal organization tool. It is not a medical device and does not diagnose, treat, cure or prevent any disease. For medical advice, diagnosis or treatment, consult a doctor, pharmacist or other qualified healthcare professional.',
    ),
    (
      'Contact',
      'For privacy or support requests: freshtrack.help@outlook.com. Developer: Nicola Zingaro.',
    ),
    ('Last updated', 'September 15, 2026'),
  ];
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
