import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/data/products/open_food_facts_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_validation.dart';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/notifications/notification_permission_prompt.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/data_transfer_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/shared/text/search_normalization.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({
    this.productId,
    this.templateId,
    this.scanOnOpen = false,
    super.key,
  });

  final String? productId;
  final String? templateId;
  final bool scanOnOpen;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _imagePicker = ImagePicker();
  final _nameFocusNode = FocusNode();

  ProductCategory _category = ProductCategory.food;
  MeasurementUnit _unit = MeasurementUnit.pieces;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 7));
  XFile? _selectedImage;
  String? _existingImagePath;
  String? _loadedProductId;
  Product? _originalProduct;
  String? _barcode;
  bool _saving = false;
  bool _scanningBarcode = false;
  bool _readingExpirationDate = false;
  bool _selectingImage = false;
  bool _showAdvanced = false;
  int _formGeneration = 0;

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
    if (widget.scanOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scanBarcode();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceId = widget.productId ?? widget.templateId;
    if (sourceId != null && _loadedProductId != sourceId) {
      final product = ref.watch(productByIdProvider(sourceId));
      return product.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          appBar: AppBar(
            title: Text(context.tr('Modifica prodotto', 'Edit product')),
          ),
          body: Center(
            child: FilledButton.tonal(
              onPressed: () => ref.invalidate(productByIdProvider(sourceId)),
              child: Text(context.tr('Riprova', 'Try again')),
            ),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  context.tr('Prodotto non trovato', 'Product not found'),
                ),
              ),
            );
          }
          _loadProduct(item, asTemplate: widget.templateId != null);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _originalProduct == null
            ? context.tr('Nuovo prodotto', 'New product')
            : context.tr('Modifica prodotto', 'Edit product'),
      ),
    ),
    body: SafeArea(
      child: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    if (_originalProduct == null && !_compactForm(context)) ...[
                      Text(
                        context.tr(
                          'Bastano nome e scadenza.',
                          'A name and expiration date are enough.',
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    _FormSection(
                      children: [
                        _ProductNameAutocomplete(
                          controller: _name,
                          focusNode: _nameFocusNode,
                          products:
                              ref.watch(productsProvider).value ?? const [],
                          onSelected: _applySuggestion,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('scan-barcode'),
                            onPressed: _scanningBarcode ? null : _scanBarcode,
                            icon: _scanningBarcode
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.qr_code_scanner_rounded),
                            label: Text(
                              context.tr(
                                'Scansiona il codice',
                                'Scan the code',
                              ),
                            ),
                          ),
                        ),
                        if (_barcode case final barcode?) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              key: const Key('barcode-chip'),
                              avatar: const Icon(
                                Icons.qr_code_2_rounded,
                                size: 18,
                              ),
                              label: Text(barcode),
                              tooltip: context.tr(
                                'Barcode acquisito',
                                'Barcode captured',
                              ),
                              onDeleted: () => setState(() {
                                _barcode = null;
                                _scanningBarcode = false;
                                _formGeneration++;
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      children: [
                        _DateField(
                          label: context.tr(
                            'Data di scadenza',
                            'Expiration date',
                          ),
                          value: _expirationDate,
                          onTap: _readingExpirationDate
                              ? null
                              : () => _pickDate(purchase: false),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final choice in [
                              (0, context.tr('Oggi', 'Today')),
                              (1, context.tr('Domani', 'Tomorrow')),
                              (7, context.tr('Tra 7 giorni', 'In 7 days')),
                            ])
                              ChoiceChip(
                                key: Key('quick-expiry-${choice.$1}'),
                                label: Text(choice.$2),
                                selected:
                                    CivilDate.fromDateTime(_expirationDate) ==
                                    CivilDate.fromDateTime(
                                      DateTime.now(),
                                    ).addDays(choice.$1),
                                onSelected: _readingExpirationDate
                                    ? null
                                    : (_) {
                                        FocusScope.of(context).unfocus();
                                        setState(
                                          () => _expirationDate =
                                              CivilDate.fromDateTime(
                                                    DateTime.now(),
                                                  )
                                                  .addDays(choice.$1)
                                                  .toLocalDateTime(),
                                        );
                                      },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('scan-expiration-date'),
                            onPressed: _readingExpirationDate
                                ? null
                                : _scanExpirationDate,
                            icon: _readingExpirationDate
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.document_scanner_outlined),
                            label: Text(
                              context.tr('Leggi dalla foto', 'Read from photo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      children: [
                        DropdownButtonFormField<ProductCategory>(
                          key: ValueKey(_category),
                          initialValue: _category,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: context.tr('Categoria', 'Category'),
                          ),
                          items: _categoryOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value.localizedLabel(
                                      context.strings.languageCode,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _category = value ?? _category),
                        ),
                        if (_category == ProductCategory.medicines) ...[
                          const SizedBox(height: 8),
                          Text(
                            context.tr(
                              'FreshTrack serve solo a ricordare la scadenza. Non è un dispositivo medico e non diagnostica, tratta, cura o previene alcuna patologia. Per pareri medici, diagnosi o trattamenti consulta un professionista sanitario.',
                              'FreshTrack only reminds you about expiration dates. It is not a medical device and does not diagnose, treat, cure or prevent any disease. Consult a healthcare professional for medical advice, diagnosis or treatment.',
                            ),
                            key: const Key('medicine-disclaimer'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        key: ValueKey('advanced-$_showAdvanced'),
                        initiallyExpanded: _showAdvanced,
                        onExpansionChanged: (value) => _showAdvanced = value,
                        leading: const Icon(Icons.tune_rounded),
                        title: Text(
                          context.tr('Altri dettagli', 'More details'),
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          context.tr(
                            'Quantità, acquisto, descrizione e foto',
                            'Quantity, purchase, description and photo',
                          ),
                        ),
                        children: [_buildAdvancedDetails(context)],
                      ),
                    ),
                    if (_originalProduct == null) ...[
                      const SizedBox(height: 12),
                      _saveAnotherButton(),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: .5),
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const Key('save-product'),
                      onPressed: _saving ? null : () => _save(),
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
                              ? context.tr('Aggiungi prodotto', 'Add product')
                              : context.tr('Salva modifiche', 'Save changes'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  bool _compactForm(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) > 21 ||
      MediaQuery.sizeOf(context).height < 600;

  Widget _saveAnotherButton() => TextButton.icon(
    key: const Key('save-and-add-another'),
    onPressed: _saving ? null : () => _save(addAnother: true),
    icon: const Icon(Icons.add_rounded),
    label: Text(
      context.tr('Salva e aggiungi un altro', 'Save and add another'),
    ),
  );

  Widget _buildAdvancedDetails(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
    child: Column(
      children: [
        TextFormField(
          controller: _description,
          maxLines: 3,
          maxLength: maxProductDescriptionLength,
          decoration: InputDecoration(
            labelText: context.tr(
              'Descrizione (facoltativa)',
              'Description (optional)',
            ),
            alignLabelWithHint: true,
          ),
        ),
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
                decoration: InputDecoration(
                  labelText: context.tr('Quantità *', 'Quantity *'),
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  return parsed == null ||
                          !parsed.isFinite ||
                          parsed <= 0 ||
                          parsed > maxProductQuantity
                      ? context.tr('Valore non valido', 'Invalid value')
                      : null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<MeasurementUnit>(
                key: ValueKey(_unit),
                initialValue: _unit,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('Unità', 'Unit'),
                ),
                items: selectableMeasurementUnits
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(
                          value.localizedLabel(context.strings.languageCode),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _unit = value ?? _unit),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateField(
          label: context.tr('Data di acquisto', 'Purchase date'),
          value: _purchaseDate,
          onTap: () => _pickDate(purchase: true),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.tr('Foto del prodotto', 'Product photo'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            context.tr(
              'Facoltativa. Aggiungila dalla fotocamera o dalla galleria.',
              'Optional. Add one from the camera or gallery.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 12),
        _PhotoPicker(
          imagePath: _selectedImage?.path ?? _existingImagePath,
          loading: _selectingImage,
          onCamera: () => _pickImage(ImageSource.camera),
          onGallery: () => _pickImage(ImageSource.gallery),
          onRemove: _selectedImage == null && _existingImagePath == null
              ? null
              : () => setState(() {
                  _selectedImage = null;
                  _existingImagePath = null;
                }),
        ),
      ],
    ),
  );

  void _loadProduct(Product product, {required bool asTemplate}) {
    _loadedProductId = product.id;
    _originalProduct = asTemplate ? null : product;
    _name.text = product.name;
    _description.text = product.description ?? '';
    _quantity.text = product.quantityText;
    _category = product.category;
    _unit = selectableMeasurementUnits.contains(product.unit)
        ? product.unit
        : MeasurementUnit.pieces;
    _barcode = product.barcode;
    if (asTemplate) {
      final today = CivilDate.fromDateTime(DateTime.now());
      final shelfLife = product.expirationDate
          .differenceInDays(product.purchaseDate)
          .clamp(0, 3650);
      _purchaseDate = today.toLocalDateTime();
      _expirationDate = today.addDays(shelfLife).toLocalDateTime();
      _existingImagePath = null;
      _showAdvanced = false;
    } else {
      _purchaseDate = product.purchaseDate.toLocalDateTime();
      _expirationDate = product.expirationDate.toLocalDateTime();
      _existingImagePath = product.imagePath;
      _showAdvanced = true;
    }
  }

  void _applySuggestion(Product product) {
    _formGeneration++;
    final today = CivilDate.fromDateTime(DateTime.now());
    final shelfLife = product.expirationDate
        .differenceInDays(product.purchaseDate)
        .clamp(0, 3650);
    setState(() {
      _scanningBarcode = false;
      _readingExpirationDate = false;
      _category = product.category;
      _quantity.text = product.quantityText;
      _unit = selectableMeasurementUnits.contains(product.unit)
          ? product.unit
          : MeasurementUnit.pieces;
      _barcode = product.barcode;
      _purchaseDate = today.toLocalDateTime();
      _expirationDate = today.addDays(shelfLife).toLocalDateTime();
    });
  }

  List<ProductCategory> get _categoryOptions =>
      selectableProductCategories.contains(_category)
      ? selectableProductCategories
      : [_category, ...selectableProductCategories];

  Future<void> _scanBarcode() async {
    if (_scanningBarcode || _saving) return;
    final generation = _formGeneration;
    final barcode = await context.push<String>('/products/scan-barcode');
    if (barcode == null || !mounted || generation != _formGeneration) return;
    setState(() {
      _barcode = barcode;
      _scanningBarcode = true;
    });

    final localProducts = ref.read(productsProvider).value ?? const <Product>[];
    Product? localMatch;
    for (final product in localProducts) {
      if (product.barcode == barcode) {
        localMatch = product;
        break;
      }
    }
    if (localMatch != null) {
      _name.text = localMatch.name;
      _applySuggestion(localMatch);
      if (mounted) {
        setState(() => _scanningBarcode = false);
        _showMessage(
          context.tr(
            'Prodotto riconosciuto dai dati già salvati.',
            'Product recognized from your saved data.',
          ),
        );
      }
      return;
    }

    final previousName = _name.text;
    final previousCategory = _category;
    final languageCode = context.strings.languageCode;
    BarcodeLookupResult result;
    try {
      final service = await ref.read(openFoodFactsServiceProvider.future);
      result = await service.lookup(barcode, languageCode: languageCode);
    } catch (_) {
      result = const BarcodeLookupResult.unavailable();
    }
    if (!mounted || generation != _formGeneration || _barcode != barcode) {
      return;
    }
    final lookup = result.product;
    setState(() {
      _scanningBarcode = false;
      if (lookup != null) {
        if (_name.text == previousName) _name.text = lookup.name;
        if (_category == previousCategory) _category = lookup.category;
        if (_description.text.trim().isEmpty && lookup.brand != null) {
          _description.text = context.tr(
            'Marca: ${lookup.brand}',
            'Brand: ${lookup.brand}',
          );
        }
      }
    });
    switch (result.status) {
      case BarcodeLookupStatus.found:
        _showMessage(
          context.tr(
            'Prodotto riconosciuto. Verifica nome e scadenza.',
            'Product recognized. Check its name and expiration date.',
          ),
        );
      case BarcodeLookupStatus.notFound:
        _showMessage(
          context.tr(
            'Barcode acquisito. Inserisci il nome manualmente.',
            'Barcode captured. Enter the name manually.',
          ),
        );
      case BarcodeLookupStatus.unavailable:
        _showMessage(
          context.tr(
            'Barcode acquisito. Ricerca online non disponibile: puoi continuare manualmente.',
            'Barcode captured. Online lookup is unavailable: you can continue manually.',
          ),
        );
    }
  }

  Future<void> _scanExpirationDate() async {
    final generation = _formGeneration;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(
                  context.tr(
                    'Fotografa la scadenza',
                    'Photograph expiration date',
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.tr('Scegli una foto', 'Choose a photo')),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _readingExpirationDate = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2200,
        maxHeight: 2200,
        imageQuality: 92,
      );
      if (image == null || !mounted) return;
      final candidates = await ref
          .read(expirationDateOcrServiceProvider)
          .recognize(image.path);
      if (!mounted || generation != _formGeneration) return;
      if (candidates.isEmpty) {
        _showMessage(
          context.tr(
            'Nessuna data riconosciuta. Prova con una foto più nitida.',
            'No date recognized. Try a clearer photo.',
          ),
        );
        return;
      }
      final selected = await showDialog<CivilDate>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: Text(
            context.tr('Conferma la scadenza', 'Confirm expiration date'),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Text(
                context.tr(
                  'Controlla sempre la confezione: FreshTrack non salva automaticamente la data.',
                  'Always check the packaging: FreshTrack does not save the date automatically.',
                ),
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final candidate in candidates.take(8))
              SimpleDialogOption(
                key: Key('ocr-date-${candidate.date}'),
                onPressed: () => Navigator.pop(dialogContext, candidate.date),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(
                    DateFormat.yMd(
                      context.strings.languageCode,
                    ).format(candidate.date.toLocalDateTime()),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Testo rilevato: ${candidate.source.trim()}',
                      'Detected text: ${candidate.source.trim()}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      if (selected != null && mounted && generation == _formGeneration) {
        setState(() => _expirationDate = selected.toLocalDateTime());
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(
            'Non è stato possibile leggere la scadenza dalla foto.',
            'The expiration date could not be read from the photo.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _readingExpirationDate = false);
    }
  }

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
        _showMessage(
          context.tr(
            'Non è stato possibile acquisire la foto.',
            'The photo could not be acquired.',
          ),
        );
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
      lastDate: DateTime(2100, 12, 31),
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

  Future<void> _save({bool addAnother = false}) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    final quantity = double.tryParse(_quantity.text.replaceAll(',', '.'));
    final quantityError = ProductValidation.quantity(quantity);
    if (quantityError != null) {
      _showMessage(quantityError);
      return;
    }
    if (CivilDate.fromDateTime(
      _expirationDate,
    ).isBefore(CivilDate.fromDateTime(_purchaseDate))) {
      _showMessage(
        context.tr(
          'La scadenza non può precedere l’acquisto.',
          'The expiration date cannot be before the purchase date.',
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _scanningBarcode = false;
      _readingExpirationDate = false;
    });
    _formGeneration++;
    final repository = ref.read(productRepositoryProvider);
    final imageStorage = ref.read(productImageStorageProvider);
    final synchronization = ref.read(notificationSynchronizationProvider);
    final scheduler = ref.read(expirationNotificationSchedulerProvider);
    final original = _originalProduct;
    String? newImagePath;
    var productSaved = false;
    final now = DateTime.now();
    var product = Product(
      id: original?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      category: _category,
      quantity: quantity!,
      unit: _unit,
      purchaseDate: CivilDate.fromDateTime(_purchaseDate),
      expirationDate: CivilDate.fromDateTime(_expirationDate),
      imagePath: _existingImagePath,
      barcode: _barcode,
      status: original?.status ?? ProductStatus.available,
      notificationDaysBefore:
          ref.read(appSettingsProvider).value?.notificationDaysBefore ??
          AppSettings.defaults.notificationDaysBefore,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );
    final selectedImage = _selectedImage;
    try {
      ProductValidation.requireValid(product);
      await mutationLockFor(repository).run(() async {
        if (selectedImage != null) {
          newImagePath = await imageStorage.save(selectedImage.path);
          product = product.copyWith(imagePath: newImagePath);
        }
        await repository.save(product);
        productSaved = true;
        final oldImagePath = original?.imagePath;
        if (oldImagePath != null && oldImagePath != product.imagePath) {
          await deleteProductImageBestEffort(imageStorage, oldImagePath);
        }
      });
      if (mounted) ref.invalidate(productByIdProvider(product.id));
    } catch (_) {
      if (!productSaved) {
        await deleteProductImageBestEffort(imageStorage, newImagePath);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        context.tr(
          'Salvataggio non riuscito. Riprova.',
          'Save failed. Try again.',
        ),
      );
      return;
    }

    try {
      final result = await synchronization.synchronizeLatest();
      if (!result.isComplete && mounted) {
        _showMessage(
          context.tr(
            'Prodotto salvato, ma alcuni promemoria non sono stati aggiornati.',
            'Product saved, but some reminders were not updated.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(
            'Prodotto salvato. I promemoria verranno riallineati alla prossima apertura.',
            'Product saved. Reminders will be synchronized the next time the app opens.',
          ),
        );
      }
    }
    if (!mounted) return;
    try {
      final permissionGranted = await offerExpirationNotificationPermission(
        context: context,
        scheduler: scheduler,
      );
      if (permissionGranted) await synchronization.synchronizeLatest();
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(
            'Prodotto salvato. I promemoria non sono al momento disponibili.',
            'Product saved. Reminders are currently unavailable.',
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (addAnother) {
      _resetForNextProduct();
      _showMessage(
        context.tr(
          'Prodotto salvato. Puoi aggiungerne un altro.',
          'Product saved. You can add another.',
        ),
      );
    } else {
      context.pop(product);
    }
  }

  void _resetForNextProduct() {
    _formGeneration++;
    final today = DateTime.now();
    setState(() {
      _name.clear();
      _scanningBarcode = false;
      _readingExpirationDate = false;
      _description.clear();
      _quantity.text = '1';
      _purchaseDate = today;
      _expirationDate = today.add(const Duration(days: 7));
      _selectedImage = null;
      _existingImagePath = null;
      _barcode = null;
      _showAdvanced = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductNameAutocomplete extends StatelessWidget {
  const _ProductNameAutocomplete({
    required this.controller,
    required this.focusNode,
    required this.products,
    required this.onSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<Product> products;
  final ValueChanged<Product> onSelected;

  @override
  Widget build(BuildContext context) => RawAutocomplete<Product>(
    textEditingController: controller,
    focusNode: focusNode,
    displayStringForOption: (product) => product.name,
    optionsBuilder: (value) {
      final query = normalizeForSearch(value.text.trim());
      if (query.isEmpty) return const Iterable<Product>.empty();
      final ordered = [...products]
        ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
      final seen = <String>{};
      return ordered
          .where((product) {
            final normalized = normalizeForSearch(product.name);
            return normalized.contains(query) && seen.add(normalized);
          })
          .take(6)
          .toList(growable: false);
    },
    onSelected: onSelected,
    fieldViewBuilder: (context, textController, node, onSubmitted) =>
        TextFormField(
          key: const Key('product-name'),
          controller: textController,
          focusNode: node,
          maxLength: maxProductNameLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: MediaQuery.textScalerOf(context).scale(14) > 21
                ? context.tr('Nome', 'Name')
                : context.tr('Nome del prodotto', 'Product name'),
            hintText: context.tr(
              'Esempio: yogurt greco',
              'Example: Greek yogurt',
            ),
            counterText: '',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? context.tr('Inserisci il nome', 'Enter a name')
              : null,
        ),
    optionsViewBuilder: (context, onOptionSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 260),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final product = options.elementAt(index);
              return ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(product.name),
                subtitle: Text(
                  '${product.category.localizedLabel(context.strings.languageCode)} · ${product.quantityText} ${product.unit.localizedLabel(context.strings.languageCode)}',
                ),
                onTap: () => onOptionSelected(product),
              );
            },
          ),
        ),
      ),
    ),
  );
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Nessuna foto', 'No photo'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text(
                      context.tr(
                        'Puoi aggiungerla anche in seguito.',
                        'You can add one later.',
                      ),
                    ),
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
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    context.tr(
                      'Anteprima non disponibile',
                      'Preview unavailable',
                    ),
                  ),
                ),
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
            label: Text(context.tr('Scatta foto', 'Take photo')),
          ),
          OutlinedButton.icon(
            key: const Key('choose-product-photo'),
            onPressed: loading ? null : onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(context.tr('Galleria', 'Gallery')),
          ),
          if (onRemove != null)
            IconButton.filledTonal(
              tooltip: context.tr('Rimuovi foto', 'Remove photo'),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: MediaQuery.textScalerOf(context).scale(14) > 21
            ? null
            : const Icon(Icons.calendar_today_outlined),
        suffixIcon: MediaQuery.textScalerOf(context).scale(14) > 21
            ? null
            : const Icon(Icons.edit_calendar_outlined),
      ),
      child: Text(DateFormat.yMd(context.strings.languageCode).format(value)),
    ),
  );
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}
