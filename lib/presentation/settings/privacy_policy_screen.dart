import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const lastUpdated = '23 agosto 2026';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      title: const Text('Privacy'),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: const [
          _PrivacySection(
            title: 'I tuoi dati restano sul dispositivo',
            body:
                'FreshTrack non richiede un account, non mostra pubblicità e '
                'non usa strumenti di analisi. Prodotti, scadenze, fotografie '
                'e preferenze vengono conservati localmente.',
          ),
          _PrivacySection(
            title: 'Permessi',
            body:
                'La fotocamera viene usata solo quando scegli di scattare la '
                'foto di un prodotto. Le notifiche servono esclusivamente per '
                'i promemoria sulle scadenze. Il permesso di avvio completato '
                'serve ad Android per ripristinare i promemoria dopo un '
                'riavvio.',
          ),
          _PrivacySection(
            title: 'Condivisione',
            body:
                'FreshTrack non vende, condivide o trasmette dati personali a '
                'terzi. Il backup automatico Android e il trasferimento dei '
                'dati dell’app tra dispositivi sono disabilitati.',
          ),
          _PrivacySection(
            title: 'Controllo',
            body:
                'Puoi eliminare singoli prodotti oppure cancellare prodotti, '
                'immagini e preferenze dalle Impostazioni. Disinstallando '
                'l’app vengono rimossi anche i dati conservati localmente.',
          ),
          _PrivacySection(
            title: 'Uso dell’app',
            body:
                'FreshTrack è uno strumento di organizzazione personale. Non '
                'fornisce consigli medici e non sostituisce il parere di un '
                'medico o di un farmacista.',
          ),
          _PrivacySection(
            title: 'Contatti',
            body:
                'Per richieste relative alla privacy o all’assistenza: '
                'freshtrack.help@outlook.com. Sviluppatore: Nicola Zingaro.',
          ),
          _PrivacySection(title: 'Ultimo aggiornamento', body: lastUpdated),
        ],
      ),
    ),
  );
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
