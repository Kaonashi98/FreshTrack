import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  final _imagePicker = ImagePicker();
  bool _handled = false;
  bool _analyzingGallery = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoZoom: true,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf14,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Scansiona barcode', 'Scan barcode')),
      actions: [
        IconButton(
          key: const Key('barcode-gallery'),
          tooltip: context.tr('Foto dalla galleria', 'Photo from gallery'),
          onPressed: _analyzingGallery ? null : _analyzeGallery,
          icon: _analyzingGallery
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined),
        ),
        IconButton(
          tooltip: context.tr('Torcia', 'Flashlight'),
          onPressed: () async {
            try {
              await _controller.toggleTorch();
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr(
                        'Torcia non disponibile.',
                        'Flashlight unavailable.',
                      ),
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.flashlight_on_outlined),
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => _ScannerError(
            error: error,
            onManualEntry: _enterManually,
            onGallery: _analyzeGallery,
          ),
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 88,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(
                      'Avvicina il codice a barre al riquadro. Tieni ferma la confezione; la torcia aiuta se c’è poco contrasto.',
                      'Bring the barcode into the frame. Hold the pack still; the flashlight helps when contrast is low.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('barcode-manual-entry'),
                    onPressed: _enterManually,
                    child: Text(
                      context.tr(
                        'Inserisci il codice a mano',
                        'Enter the code manually',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = _normalizedBarcode(barcode.rawValue);
      if (value == null) continue;
      await _complete(value);
      return;
    }
  }

  Future<void> _analyzeGallery() async {
    if (_handled || _analyzingGallery) return;
    setState(() => _analyzingGallery = true);
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      final capture = await _controller.analyzeImage(image.path);
      final value = capture?.barcodes
          .map((barcode) => _normalizedBarcode(barcode.rawValue))
          .whereType<String>()
          .firstOrNull;
      if (value != null) {
        await _complete(value);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Nessun barcode riconosciuto nella foto. Prova un’immagine più nitida o inserisci il codice a mano.',
                'No barcode recognized in the photo. Try a clearer image or enter the code manually.',
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Impossibile leggere la foto. Inserisci il codice a mano.',
                'The photo could not be read. Enter the code manually.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzingGallery = false);
    }
  }

  Future<void> _enterManually() async {
    if (_handled) return;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _ManualBarcodeDialog(),
    );
    if (value == null || !mounted) return;
    await _complete(value);
  }

  Future<void> _complete(String value) async {
    if (_handled) return;
    _handled = true;
    try {
      await _controller.stop();
    } catch (_) {
      /* A valid detection can still be returned if camera shutdown fails. */
    }
    if (mounted) Navigator.pop(context, value);
  }

  String? _normalizedBarcode(String? raw) {
    final value = raw?.replaceAll(RegExp(r'\D'), '');
    if (value == null ||
        value.length < minProductBarcodeLength ||
        value.length > maxProductBarcodeLength) {
      return null;
    }
    return value;
  }
}

class _ManualBarcodeDialog extends StatefulWidget {
  const _ManualBarcodeDialog();

  @override
  State<_ManualBarcodeDialog> createState() => _ManualBarcodeDialogState();
}

class _ManualBarcodeDialogState extends State<_ManualBarcodeDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(context.tr('Inserisci il codice', 'Enter the code')),
      content: TextField(
        key: const Key('manual-barcode-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxProductBarcodeLength),
        ],
        decoration: InputDecoration(
          labelText: context.tr('Codice a barre', 'Barcode'),
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Annulla', 'Cancel')),
        ),
        FilledButton(
          key: const Key('confirm-manual-barcode'),
          onPressed: _submit,
          child: Text(context.tr('Usa codice', 'Use code')),
        ),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (value.length < minProductBarcodeLength ||
        value.length > maxProductBarcodeLength) {
      setState(() {
        _error = context.tr(
          'Inserisci da $minProductBarcodeLength a $maxProductBarcodeLength cifre.',
          'Enter $minProductBarcodeLength to $maxProductBarcodeLength digits.',
        );
      });
      return;
    }
    Navigator.pop(context, value);
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({
    required this.error,
    required this.onManualEntry,
    required this.onGallery,
  });
  final MobileScannerException error;
  final VoidCallback onManualEntry;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 58),
          const SizedBox(height: 14),
          Text(
            context.tr('Fotocamera non disponibile', 'Camera unavailable'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Controlla il permesso Fotocamera nelle impostazioni Android, oppure usa una foto o inserisci il codice a mano.',
              'Check the Camera permission in Android settings, or use a photo or enter the code manually.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonal(
                onPressed: onGallery,
                child: Text(context.tr('Galleria', 'Gallery')),
              ),
              FilledButton(
                onPressed: onManualEntry,
                child: Text(context.tr('Inserisci codice', 'Enter code')),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
