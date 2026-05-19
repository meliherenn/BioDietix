import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../i18n.dart';
import '../models/product.dart';
import '../models/product_evaluation.dart';
import '../models/profile_memory.dart';
import '../services/biodietix_api.dart';
import '../widgets/ui.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    required this.apiUrl,
    required this.profileMemory,
    super.key,
  });

  final String apiUrl;
  final ProfileMemory? profileMemory;

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
  String? _lookupMessage;
  ProductEvaluation? _evaluation;

  bool get _serverReady => BioDietixApi.isConfiguredUrl(widget.apiUrl);

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
    return parsed != null && parsed > 0 ? parsed : null;
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
    });
    try {
      final product = await BioDietixApi(
        widget.apiUrl,
      ).lookupProduct(_barcode.text.trim());
      _fillProduct(product);
      if (mounted) showAppSnack(context, strings.t('productFound'));
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

  Future<void> _evaluate() async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final memory = widget.profileMemory;
    if (memory == null) {
      showAppSnack(context, strings.t('uploadBloodFirst'));
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(
        widget.apiUrl,
      ).evaluateProduct(product: _productFromFields(), profileMemory: memory);
      setState(() => _evaluation = result);
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

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    if (_scannerOpen) {
      return _ScannerOverlay(
        onClose: () => setState(() => _scannerOpen = false),
        onBarcode: (value) {
          _barcode.text = value;
          setState(() => _scannerOpen = false);
        },
      );
    }

    return ListView(
      padding: pagePadding,
      children: [
        HeroPanel(
          kicker: strings.t('biodietixMobile'),
          title: strings.t('productScanner'),
          subtitle: strings.t('productScannerSubtitle'),
          icon: Icons.qr_code_scanner_rounded,
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
              if (widget.profileMemory == null)
                NoticeBox(message: strings.t('bloodRequired'), warning: true),
              AppButton(
                label: strings.t('openCameraScanner'),
                onPressed: () => setState(() => _scannerOpen = true),
                secondary: true,
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
              ),
              if (_lookupMessage != null) ...[
                const SizedBox(height: 12),
                NoticeBox(message: _lookupMessage!, warning: true),
              ],
            ],
          ),
        ),
        AppCard(
          title: strings.t('productDetails'),
          subtitle: strings.t('manualProductHint'),
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
                onPressed: _serverReady ? _evaluate : null,
                busy: _busy,
              ),
            ],
          ),
        ),
        if (_evaluation != null) _EvaluationCard(evaluation: _evaluation!),
      ],
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.onClose, required this.onBarcode});

  final VoidCallback onClose;
  final ValueChanged<String> onBarcode;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final value = capture.barcodes.isEmpty
                ? null
                : capture.barcodes.first.rawValue;
            if (value != null && value.isNotEmpty) {
              onBarcode(value);
            }
          },
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 28,
          child: AppButton(
            label: strings.t('closeScanner'),
            onPressed: onClose,
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    strings.decision(evaluation.decision),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 19,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (evaluation.reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            _EvaluationSection(
              title: strings.t('reasons'),
              icon: Icons.rule_rounded,
              accent: color,
              items: evaluation.reasons.map(strings.reason).toList(),
            ),
          ],
          if (evaluation.positives.isNotEmpty) ...[
            const SizedBox(height: 14),
            _EvaluationSection(
              title: strings.t('positiveSignals'),
              icon: Icons.trending_up_rounded,
              accent: green,
              items: evaluation.positives.map(strings.positive).toList(),
            ),
          ],
          if (evaluation.alternatives.isNotEmpty) ...[
            const SizedBox(height: 14),
            _EvaluationSection(
              title: strings.t('betterAlternatives'),
              icon: Icons.swap_horiz_rounded,
              accent: violet,
              items: evaluation.alternatives.map(strings.alternative).toList(),
            ),
          ],
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

class _EvaluationSection extends StatelessWidget {
  const _EvaluationSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSecondaryFill(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appLineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 10),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
