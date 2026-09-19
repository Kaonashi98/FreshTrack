import 'package:flutter/material.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController _controller;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoZoom: false,
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
          errorBuilder: (context, error) => _ScannerError(error: error),
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 290,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                context.tr(
                  'Inquadra il codice a barre. La ricerca online partirà solo dopo la scansione.',
                  'Frame the barcode. The online search starts only after scanning.',
                ),
                textAlign: TextAlign.center,
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
      final value = barcode.rawValue?.replaceAll(RegExp(r'\D'), '');
      if (value == null ||
          value.length < minProductBarcodeLength ||
          value.length > maxProductBarcodeLength) {
        continue;
      }
      _handled = true;
      try {
        await _controller.stop();
      } catch (_) {
        /* A valid detection can still be returned if camera shutdown fails. */
      }
      if (mounted) Navigator.pop(context, value);
      return;
    }
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});
  final MobileScannerException error;

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
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Controlla il permesso Fotocamera nelle impostazioni Android e riprova.',
              'Check the Camera permission in Android settings and try again.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
