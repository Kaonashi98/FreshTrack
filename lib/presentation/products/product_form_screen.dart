import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/notifications/notification_permission_prompt.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({this.productId, super.key});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _imagePicker = ImagePicker();

  ProductCategory _category = ProductCategory.food;
  MeasurementUnit _unit = MeasurementUnit.pieces;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 7));
  XFile? _selectedImage;
  String? _existingImagePath;
  String? _loadedProductId;
  Product? _originalProduct;
  bool _saving = false;
  bool _selectingImage = false;

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId;
    if (productId != null && _loadedProductId != productId) {
      final product = ref.watch(productByIdProvider(productId));
      return product.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Modifica prodotto')),
          body: Center(
            child: FilledButton.tonal(
              onPressed: () => ref.invalidate(productByIdProvider(productId)),
              child: const Text('Riprova'),
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return const Scaffold(
              body: Center(child: Text('Prodotto non trovato')),
            );
          }
          _loadProduct(item);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _originalProduct == null ? 'Nuovo prodotto' : 'Modifica prodotto',
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Text(
                    'Informazioni',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('product-name'),
                    controller: _name,
                    maxLength: 160,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Inserisci il nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione (facoltativa)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductCategory>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: _categoryOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                  ),
                  if (_category == ProductCategory.medicines) ...[
                    const SizedBox(height: 8),
                    Text(
                      'FreshTrack serve solo a ricordare la scadenza. Non '
                      'sostituisce il parere di un medico o di un farmacista.',
                      key: const Key('medicine-disclaimer'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('product-quantity'),
                          controller: _quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Quantità *',
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            return parsed == null ||
                                    !parsed.isFinite ||
                                    parsed <= 0
                                ? 'Valore non valido'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<MeasurementUnit>(
                          initialValue: _unit,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Unità'),
                          items: selectableMeasurementUnits
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _unit = value ?? _unit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: 'Data di acquisto',
                    value: _purchaseDate,
                    onTap: () => _pickDate(purchase: true),
                  ),
                  const SizedBox(height: 12),
                  _DateField(
                    label: 'Data di scadenza',
                    value: _expirationDate,
                    onTap: () => _pickDate(purchase: false),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Foto del prodotto',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Facoltativa. Aggiungila dalla fotocamera o dalla galleria.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _PhotoPicker(
                    imagePath: _selectedImage?.path ?? _existingImagePath,
                    loading: _selectingImage,
                    onCamera: () => _pickImage(ImageSource.camera),
                    onGallery: () => _pickImage(ImageSource.gallery),
                    onRemove:
                        _selectedImage == null && _existingImagePath == null
                        ? null
                        : () => setState(() {
                            _selectedImage = null;
                            _existingImagePath = null;
                          }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('save-product'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _originalProduct == null
                          ? 'Salva prodotto'
                          : 'Salva modifiche',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _loadProduct(Product product) {
    _loadedProductId = product.id;
    _originalProduct = product;
    _name.text = product.name;
    _description.text = product.description ?? '';
    _quantity.text = product.quantity.toStringAsFixed(
      product.quantity % 1 == 0 ? 0 : 1,
    );
    _category = product.category;
    _unit = selectableMeasurementUnits.contains(product.unit)
        ? product.unit
        : MeasurementUnit.pieces;
    _purchaseDate = product.purchaseDate.toLocalDateTime();
    _expirationDate = product.expirationDate.toLocalDateTime();
    _existingImagePath = product.imagePath;
  }

  List<ProductCategory> get _categoryOptions =>
      selectableProductCategories.contains(_category)
      ? selectableProductCategories
      : [_category, ...selectableProductCategories];

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _selectingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Non è stato possibile acquisire la foto.');
      }
    } finally {
      if (mounted) setState(() => _selectingImage = false);
    }
  }

  Future<void> _recoverLostImage() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (!response.isEmpty && response.file != null && mounted) {
        setState(() => _selectedImage = response.file);
      }
    } catch (_) {
      // Il recupero è best-effort: il form rimane comunque utilizzabile.
    }
  }

  Future<void> _pickDate({required bool purchase}) async {
    final current = purchase ? _purchaseDate : _expirationDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (purchase) {
        _purchaseDate = picked;
        if (_expirationDate.isBefore(picked)) _expirationDate = picked;
      } else {
        _expirationDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expirationDate.isBefore(_purchaseDate)) {
      _showMessage('La scadenza non può precedere l’acquisto.');
      return;
    }

    setState(() => _saving = true);
    final original = _originalProduct;
    String? newImagePath;
    var productSaved = false;
    late Product product;
    try {
      if (_selectedImage != null) {
        newImagePath = await ref
            .read(productImageStorageProvider)
            .save(_selectedImage!.path);
      }

      final now = DateTime.now();
      product = Product(
        id: original?.id ?? const Uuid().v4(),
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        category: _category,
        quantity: double.parse(_quantity.text.replaceAll(',', '.')),
        unit: _unit,
        purchaseDate: CivilDate.fromDateTime(_purchaseDate),
        expirationDate: CivilDate.fromDateTime(_expirationDate),
        imagePath: newImagePath ?? _existingImagePath,
        status: original?.status ?? ProductStatus.available,
        notificationDaysBefore:
            ref.read(appSettingsProvider).value?.notificationDaysBefore ??
            AppSettings.defaults.notificationDaysBefore,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
      );
      await ref.read(productRepositoryProvider).save(product);
      productSaved = true;
      final oldImagePath = original?.imagePath;
      if (oldImagePath != null && oldImagePath != product.imagePath) {
        await deleteProductImageBestEffort(
          ref.read(productImageStorageProvider),
          oldImagePath,
        );
      }
      ref.invalidate(productByIdProvider(product.id));
    } catch (_) {
      if (!productSaved) {
        await deleteProductImageBestEffort(
          ref.read(productImageStorageProvider),
          newImagePath,
        );
      }
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Salvataggio non riuscito. Riprova.');
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    try {
      final result = await ref
          .read(notificationSynchronizationProvider)
          .synchronizeLatest();
      if (!result.isComplete && mounted) {
        _showMessage(
          'Prodotto salvato, ma alcuni promemoria non sono stati aggiornati.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Prodotto salvato. I promemoria verranno riallineati alla prossima apertura.',
        );
      }
    }
    if (!mounted) return;
    try {
      await offerExpirationNotificationPermission(
        context: context,
        scheduler: ref.read(expirationNotificationSchedulerProvider),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Prodotto salvato. I promemoria non sono al momento disponibili.',
        );
      }
    }
    if (mounted) context.pop(product);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.imagePath,
    required this.loading,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final String? imagePath;
  final bool loading;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (imagePath == null)
        Container(
          key: const Key('empty-photo-picker'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nessuna foto',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text('Puoi aggiungerla anche in seguito.'),
                  ],
                ),
              ),
            ],
          ),
        )
      else
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Image.file(
                File(imagePath!),
                key: const Key('product-image-preview'),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Anteprima non disponibile')),
              ),
            ),
          ),
        ),
      const SizedBox(height: 10),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('take-product-photo'),
            onPressed: loading ? null : onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Scatta foto'),
          ),
          OutlinedButton.icon(
            key: const Key('choose-product-photo'),
            onPressed: loading ? null : onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galleria'),
          ),
          if (onRemove != null)
            IconButton.filledTonal(
              tooltip: 'Rimuovi foto',
              onPressed: loading ? null : onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      if (loading) const LinearProgressIndicator(),
    ],
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(DateFormat('dd/MM/yyyy').format(value)),
    ),
  );
}
