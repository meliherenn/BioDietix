import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../models/product.dart';
import '../../../../models/product_evaluation.dart';
import '../../../../models/profile_memory.dart';
import '../../../../services/biodietix_api.dart';
import '../../../product_checks/presentation/cubit/product_check_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({required this.apiUrl, super.key});

  final String apiUrl;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _quantity = TextEditingController();
  final _category = TextEditingController();
  final _ingredients = TextEditingController();
  final _allergens = TextEditingController();
  final _labels = TextEditingController();
  final _servingSize = TextEditingController();
  final _nutritionGrade = TextEditingController();
  final _novaGroup = TextEditingController();
  final _energy = TextEditingController();
  final _sugar = TextEditingController();
  final _satFat = TextEditingController();
  final _salt = TextEditingController();
  final _sodium = TextEditingController();
  final _protein = TextEditingController();
  final _fiber = TextEditingController();

  var _scannerOpen = false;
  var _busy = false;
  var _manualDetailsOpen = false;
  String? _lookupMessage;
  ProductEvaluation? _evaluation;

  bool get _serverReady => BioDietixApi.isConfiguredUrl(widget.apiUrl);

  bool get _hasProductDetails {
    return [
      _name,
      _brand,
      _quantity,
      _category,
      _ingredients,
      _allergens,
      _labels,
      _servingSize,
      _nutritionGrade,
      _novaGroup,
      _energy,
      _sugar,
      _satFat,
      _salt,
      _sodium,
      _protein,
      _fiber,
    ].any((controller) => controller.text.trim().isNotEmpty);
  }

  @override
  void dispose() {
    for (final controller in [
      _barcode,
      _name,
      _brand,
      _quantity,
      _category,
      _ingredients,
      _allergens,
      _labels,
      _servingSize,
      _nutritionGrade,
      _novaGroup,
      _energy,
      _sugar,
      _satFat,
      _salt,
      _sodium,
      _protein,
      _fiber,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  Product _productFromFields() {
    return Product(
      barcode: _barcode.text.trim(),
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      quantity: _quantity.text.trim(),
      category: _category.text.trim(),
      ingredientsText: _ingredients.text.trim(),
      allergensText: _allergens.text.trim(),
      labels: _labels.text.trim(),
      servingSize: _servingSize.text.trim(),
      nutritionGrade: _nutritionGrade.text.trim(),
      novaGroup: _number(_novaGroup.text),
      energyKcal100g: _number(_energy.text),
      sugarG100g: _number(_sugar.text),
      saturatedFatG100g: _number(_satFat.text),
      saltG100g: _number(_salt.text),
      sodiumMg100g: _number(_sodium.text),
      proteinG100g: _number(_protein.text),
      fiberG100g: _number(_fiber.text),
    );
  }

  void _fillProduct(Product product) {
    _barcode.text = product.barcode;
    _name.text = product.name;
    _brand.text = product.brand;
    _quantity.text = product.quantity;
    _category.text = product.category;
    _ingredients.text = product.ingredientsText;
    _allergens.text = product.allergensText;
    _labels.text = product.labels;
    _servingSize.text = product.servingSize;
    _nutritionGrade.text = product.nutritionGrade;
    _novaGroup.text = product.novaGroup?.toString() ?? '';
    _energy.text = product.energyKcal100g?.toString() ?? '';
    _sugar.text = product.sugarG100g?.toString() ?? '';
    _satFat.text = product.saturatedFatG100g?.toString() ?? '';
    _salt.text = product.saltG100g?.toString() ?? '';
    _sodium.text = product.sodiumMg100g?.toString() ?? '';
    _protein.text = product.proteinG100g?.toString() ?? '';
    _fiber.text = product.fiberG100g?.toString() ?? '';
  }

  void _clearProductDetails() {
    for (final controller in [
      _name,
      _brand,
      _quantity,
      _category,
      _ingredients,
      _allergens,
      _labels,
      _servingSize,
      _nutritionGrade,
      _novaGroup,
      _energy,
      _sugar,
      _satFat,
      _salt,
      _sodium,
      _protein,
      _fiber,
    ]) {
      controller.clear();
    }
  }

  void _openManualDetails({bool clear = false}) {
    if (clear) _clearProductDetails();
    setState(() {
      _manualDetailsOpen = true;
      _evaluation = null;
    });
  }

  void _searchScannedBarcode(String value) {
    _barcode.text = value;
    setState(() => _scannerOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lookup();
    });
  }

  Future<void> _lookup() async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }
    if (_barcode.text.trim().isEmpty) {
      showAppSnack(context, strings.t('scanBarcodeFirst'));
      return;
    }

    setState(() {
      _busy = true;
      _lookupMessage = null;
      _evaluation = null;
      _manualDetailsOpen = false;
    });
    _clearProductDetails();
    try {
      final product = await BioDietixApi(
        widget.apiUrl,
      ).lookupProduct(_barcode.text.trim());
      if (!mounted) return;
      setState(() => _fillProduct(product));
      showAppSnack(context, strings.t('productFound'));
    } on BioDietixApiException catch (error) {
      if (!mounted) return;
      final message = error.isNotFound
          ? strings.t('productLookupNotFound')
          : '${strings.t('productLookupFailed')}: ${error.message}';
      setState(() => _lookupMessage = message);
      showAppSnack(context, message);
    } catch (error) {
      if (mounted) {
        final details = error.toString();
        final message = details.contains('404')
            ? strings.t('productLookupNotFound')
            : '${strings.t('productLookupFailed')}: $details';
        setState(() => _lookupMessage = message);
        showAppSnack(context, message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _evaluate(ProfileMemory? memory) async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    if (memory == null) {
      showAppSnack(context, strings.t('uploadBloodFirst'));
      return;
    }

    setState(() => _busy = true);
    try {
      final product = _productFromFields();
      final result = await BioDietixApi(
        widget.apiUrl,
      ).evaluateProduct(product: product, profileMemory: memory);
      if (!mounted) return;
      setState(() => _evaluation = result);
      await context.read<ProductCheckCubit>().saveEvaluation(
        product: product,
        evaluation: result,
      );
      if (mounted) showAppSnack(context, strings.t('productCheckSaved'));
    } catch (error) {
      if (mounted) {
        showAppSnack(
          context,
          '${strings.t('productEvaluationFailed')}: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _productSummaryCard(ProfileMemory? memory) {
    final strings = AppScope.of(context).strings;
    final productName = _name.text.trim().isEmpty
        ? strings.t('notAvailable')
        : _name.text.trim();
    final meta = [
      _brand.text.trim(),
      _quantity.text.trim(),
      _category.text.trim(),
    ].where((value) => value.isNotEmpty).join(' • ');
    final nutrients = [
      if (_sugar.text.trim().isNotEmpty)
        '${strings.t('sugarShort')} ${_sugar.text.trim()}',
      if (_salt.text.trim().isNotEmpty)
        '${strings.t('saltShort')} ${_salt.text.trim()}',
      if (_energy.text.trim().isNotEmpty)
        '${_energy.text.trim()} ${strings.t('kcal')}',
    ];

    return AppCard(
      title: strings.t('productReady'),
      subtitle: strings.t('productReadySubtitle'),
      accentColor: aqua,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: appElevatedCardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: appLineColor(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: aqua.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(Icons.shopping_basket_rounded, color: aqua),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: appMutedColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (nutrients.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nutrients.map((item) {
                return Chip(
                  label: Text(item),
                  backgroundColor: appSecondaryFill(context),
                  side: BorderSide(color: appLineColor(context)),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: strings.t('evaluateProduct'),
            icon: Icons.check_circle_rounded,
            onPressed: _serverReady ? () => _evaluate(memory) : null,
            busy: _busy,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: strings.t('editProductDetails'),
            icon: Icons.edit_rounded,
            onPressed: () => _openManualDetails(),
            secondary: true,
          ),
        ],
      ),
    );
  }

  Widget _manualAddCard() {
    final strings = AppScope.of(context).strings;
    return AppCard(
      title: strings.t('manualAddProduct'),
      subtitle: strings.t('manualAddProductSubtitle'),
      accentColor: gold,
      child: AppButton(
        label: strings.t('openManualDetails'),
        icon: Icons.edit_note_rounded,
        onPressed: () => _openManualDetails(clear: !_hasProductDetails),
        secondary: true,
      ),
    );
  }

  Widget _manualDetailsCard(ProfileMemory? memory) {
    final strings = AppScope.of(context).strings;
    return AppCard(
      title: strings.t('manualProductDetails'),
      subtitle: strings.t('manualProductHint'),
      accentColor: gold,
      child: Column(
        children: [
          AppTextField(label: strings.t('name'), controller: _name),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.t('brand'),
                  controller: _brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: strings.t('quantity'),
                  controller: _quantity,
                ),
              ),
            ],
          ),
          AppTextField(label: strings.t('category'), controller: _category),
          AppTextField(
            label: strings.t('ingredients'),
            controller: _ingredients,
            maxLines: 3,
          ),
          AppTextField(
            label: strings.t('declaredAllergens'),
            controller: _allergens,
            maxLines: 2,
          ),
          AppTextField(
            label: strings.t('labels'),
            controller: _labels,
            maxLines: 2,
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.t('nutritionGrade'),
                  controller: _nutritionGrade,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: strings.t('novaGroup'),
                  controller: _novaGroup,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          AppTextField(
            label: strings.t('servingSize'),
            controller: _servingSize,
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.t('sugar100'),
                  controller: _sugar,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: strings.t('satFat100'),
                  controller: _satFat,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.t('salt100'),
                  controller: _salt,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: strings.t('energy100'),
                  controller: _energy,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: strings.t('protein100'),
                  controller: _protein,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: strings.t('fiber100'),
                  controller: _fiber,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          AppTextField(
            label: strings.t('sodium100'),
            controller: _sodium,
            keyboardType: TextInputType.number,
          ),
          AppButton(
            label: strings.t('evaluateProduct'),
            icon: Icons.check_circle_rounded,
            onPressed: _serverReady ? () => _evaluate(memory) : null,
            busy: _busy,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_scannerOpen) {
      return _ScannerOverlay(
        onClose: () => setState(() => _scannerOpen = false),
        onBarcode: _searchScannedBarcode,
      );
    }

    final strings = AppScope.of(context).strings;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final memory = state is ProfileLoaded ? state.profileMemory : null;
        return ListView(
          padding: pagePadding,
          children: [
            HeroPanel(
              kicker: strings.t('biodietixMobile'),
              title: strings.t('productScanner'),
              subtitle: strings.t('productScannerSubtitle'),
              icon: Icons.shopping_basket_rounded,
            ),
            AppCard(
              title: strings.t('barcodeLookup'),
              child: Column(
                children: [
                  if (!_serverReady)
                    NoticeBox(
                      message: strings.t('serverNotConfigured'),
                      warning: true,
                    ),
                  if (memory == null)
                    NoticeBox(
                      message: strings.t('bloodRequired'),
                      warning: true,
                    ),
                  AppButton(
                    label: strings.t('openCameraScanner'),
                    onPressed: () => setState(() => _scannerOpen = true),
                    secondary: true,
                    icon: Icons.qr_code_scanner_rounded,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: strings.t('barcodeQrValue'),
                    controller: _barcode,
                  ),
                  AppButton(
                    label: strings.t('lookUpProduct'),
                    onPressed: _serverReady ? _lookup : null,
                    busy: _busy,
                    icon: Icons.search_rounded,
                  ),
                  if (_lookupMessage != null) ...[
                    const SizedBox(height: 12),
                    NoticeBox(message: _lookupMessage!, warning: true),
                  ],
                ],
              ),
            ),
            if (_hasProductDetails && !_manualDetailsOpen)
              _productSummaryCard(memory),
            if (!_hasProductDetails && !_manualDetailsOpen) _manualAddCard(),
            if (_manualDetailsOpen) _manualDetailsCard(memory),
            if (_evaluation != null) _EvaluationCard(evaluation: _evaluation!),
          ],
        );
      },
    );
  }
}

class _ScannerOverlay extends StatefulWidget {
  const _ScannerOverlay({required this.onClose, required this.onBarcode});

  final VoidCallback onClose;
  final ValueChanged<String> onBarcode;

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay> {
  var _handled = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (_handled) return;
            final value = capture.barcodes.isEmpty
                ? null
                : capture.barcodes.first.rawValue;
            if (value != null && value.isNotEmpty) {
              _handled = true;
              widget.onBarcode(value);
            }
          },
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 28,
          child: AppButton(
            label: strings.t('closeScanner'),
            onPressed: widget.onClose,
          ),
        ),
      ],
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.evaluation});

  final ProductEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final color = switch (evaluation.decision) {
      'not_recommended' => danger,
      'use_with_caution' => amber,
      _ => green,
    };
    final icon = switch (evaluation.decision) {
      'not_recommended' => Icons.block_rounded,
      'use_with_caution' => Icons.warning_rounded,
      _ => Icons.check_circle_rounded,
    };
    final dataQualityLevel = evaluation.dataQualityLevel;
    final showDataQualityNotice =
        evaluation.hasDataQuality &&
        (dataQualityLevel == 'low' || dataQualityLevel == 'missing');

    return AppCard(
      title: strings.t('decision'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? .20
                    : .10,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: .34)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.decision(evaluation.decision),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          if (evaluation.hasDataQuality) ...[
            const SizedBox(height: 12),
            _DataQualityBadge(level: dataQualityLevel),
          ],
          if (showDataQualityNotice) ...[
            const SizedBox(height: 12),
            NoticeBox(
              message: strings.dataQualityNotice(dataQualityLevel),
              warning: true,
              icon: Icons.fact_check_rounded,
            ),
          ],
          if (evaluation.reasons.isNotEmpty)
            _EvaluationSection(
              title: strings.t('reasons'),
              items: evaluation.reasons.map(strings.reason).toList(),
            ),
          if (evaluation.positives.isNotEmpty)
            _EvaluationSection(
              title: strings.t('positiveSignals'),
              items: evaluation.positives.map(strings.positive).toList(),
            ),
          if (evaluation.alternatives.isNotEmpty)
            _EvaluationSection(
              title: strings.t('betterAlternatives'),
              items: evaluation.alternatives.map(strings.alternative).toList(),
            ),
          const SizedBox(height: 12),
          NoticeBox(
            message: strings.t('educationalOnly'),
            warning: evaluation.decision != 'recommended',
          ),
        ],
      ),
    );
  }
}

class _DataQualityBadge extends StatelessWidget {
  const _DataQualityBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final color = switch (level) {
      'high' => green,
      'medium' => aqua,
      'low' => amber,
      _ => danger,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .09,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded, color: color, size: 20),
          const SizedBox(width: 9),
          Text(
            '${strings.t('dataQuality')}: ',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Expanded(
            child: Text(
              strings.dataQuality(level),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationSection extends StatelessWidget {
  const _EvaluationSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSecondaryFill(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appLineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
