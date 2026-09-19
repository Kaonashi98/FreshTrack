import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsScreen extends ConsumerWidget {
  const AboutSettingsScreen({super.key});

  static final _openFoodFactsUri = Uri.parse(
    'https://world.openfoodfacts.org/',
  );

  Future<void> _openOpenFoodFacts(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        _openFoodFactsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Impossibile aprire Open Food Facts.',
              'Unable to open Open Food Facts.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(
        context.tr('Privacy e informazioni', 'Privacy and information'),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            key: const Key('privacy-policy'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              context.tr('Informativa sulla privacy', 'Privacy policy'),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              context.tr(
                'Come vengono usati dati, fotocamera e servizi online',
                'How data, camera and online services are used',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/privacy'),
          ),
        ),
        const SizedBox(height: 18),
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            key: const Key('open-food-facts-attribution'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.public_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              context.tr(
                'Dati da Open Food Facts',
                'Data from Open Food Facts',
              ),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              context.tr(
                'Database © Open Food Facts contributors, licenza ODbL',
                'Database © Open Food Facts contributors, ODbL license',
              ),
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openOpenFoodFacts(context),
          ),
        ),
        const SizedBox(height: 18),
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            key: const Key('open-source-licenses'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.description_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              context.tr('Licenze open source', 'Open-source licenses'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              context.tr(
                'Riconoscimenti e licenze dei componenti utilizzati',
                'Notices and licenses for the components used',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'FreshTrack',
            ),
          ),
        ),
        const SizedBox(height: 18),
        GlassSurface(
          padding: const EdgeInsets.all(18),
          child: Text(
            context.tr(
              'FreshTrack è uno strumento di organizzazione personale. Non è un dispositivo medico e non diagnostica, tratta, cura o previene alcuna patologia. Per pareri medici, diagnosi o trattamenti, consulta un medico, un farmacista o un altro professionista sanitario qualificato.',
              'FreshTrack is a personal organization tool. It is not a medical device and does not diagnose, treat, cure or prevent any disease. For medical advice, diagnosis or treatment, consult a doctor, pharmacist or other qualified healthcare professional.',
            ),
            key: const Key('medical-disclaimer'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 18),
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
                          .watch(appVersionProvider)
                          .maybeWhen(
                            data: (version) => context.tr(
                              'Versione ${version.split('+').first} · build ${version.split('+').last}',
                              'Version ${version.split('+').first} · build ${version.split('+').last}',
                            ),
                            orElse: () => context.tr(
                              'Versione non disponibile',
                              'Version unavailable',
                            ),
                          ),
                      key: const Key('app-version'),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr(
                        'Offline-first · Inventario conservato localmente',
                        'Offline-first · Inventory stored locally',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
