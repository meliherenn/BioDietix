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
  final _category = TextEditingController();
  final _ingredients = TextEditingController();
  final _allergens = TextEditingController();
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
      _category,
      _ingredients,
      _allergens,
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
      category: _category.text.trim(),
      ingredientsText: _ingredients.text.trim(),
      allergensText: _allergens.text.trim(),
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
    _category.text = product.category;
    _ingredients.text = product.ingredientsText;
    _allergens.text = product.allergensText;
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
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          title: strings.t('productScanner'),
          subtitle: strings.t('productScannerSubtitle'),
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
      'not_recommended' => const Color(0xFFB42318),
      'use_with_caution' => const Color(0xFFA16207),
      _ => green,
    };
    return AppCard(
      title: strings.t('decision'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              strings.decision(evaluation.decision),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (evaluation.reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              strings.t('reasons').toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            ...evaluation.reasons.map(
              (reason) => Text('- ${strings.reason(reason)}'),
            ),
          ],
          if (evaluation.alternatives.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              strings.t('betterAlternatives').toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            ...evaluation.alternatives.map(
              (item) => Text('- ${strings.alternative(item)}'),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            strings.t('educationalOnly'),
            style: TextStyle(color: appMutedColor(context)),
          ),
        ],
      ),
    );
  }
}
