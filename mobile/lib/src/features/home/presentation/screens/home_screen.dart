import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../product_checks/domain/product_check.dart';
import '../../../product_checks/presentation/cubit/product_check_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onOpenScanner, super.key});

  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            kicker: strings.t('personalNutritionEngine'),
            title: strings.t('decisionHomeTitle'),
            subtitle: strings.t('decisionHomeSubtitle'),
            trailing: const BioDietixLogoMark(size: 58),
          ),
          _ProductCheckDashboard(onOpenScanner: onOpenScanner),
        ],
      ),
    );
  }
}

class _ProductCheckDashboard extends StatelessWidget {
  const _ProductCheckDashboard({required this.onOpenScanner});

  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return BlocConsumer<ProductCheckCubit, ProductCheckState>(
      listener: (context, state) {
        if (state is ProductCheckLoaded && state.error != null) {
          showAppSnack(context, state.error!);
        } else if (state is ProductCheckFailure) {
          showAppSnack(context, state.message);
        }
      },
      builder: (context, state) {
        final items = switch (state) {
          ProductCheckLoaded(:final items) => items,
          ProductCheckLoading(:final cached) => cached,
          _ => <ProductCheck>[],
        };
        final busy = state is ProductCheckLoaded && state.busy;
        final cautionCount = items
            .where((item) => item.decision == 'use_with_caution')
            .length;
        final blockedCount = items
            .where((item) => item.decision == 'not_recommended')
            .length;
        final suitableCount = items
            .where((item) => item.decision == 'recommended')
            .length;

        if (state is ProductCheckFailure && items.isEmpty) {
          return AppCard(
            child: StatePanel(
              title: strings.t('notAvailable'),
              message: state.message,
              icon: Icons.cloud_off_rounded,
              color: danger,
            ),
          );
        }

        return Column(
          children: [
            AppCard(
              title: strings.t('decisionOverview'),
              subtitle: strings.t('decisionOverviewSubtitle'),
              trailing: _MiniBadge(
                label: state is ProductCheckLoading
                    ? strings.t('splashChecking')
                    : strings.t('splashReady'),
                color: state is ProductCheckLoading ? amber : green,
              ),
              child: Column(
                children: [
                  if (state is ProductCheckLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: LinearProgressIndicator(),
                    ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: .98,
                    children: [
                      MetricTile(
                        label: strings.t('checkedProducts'),
                        value: '${items.length}',
                        subtitle: strings.t('productChecks'),
                        icon: Icons.fact_check_rounded,
                        color: aqua,
                      ),
                      MetricTile(
                        label: strings.t('safeToEat'),
                        value: '$suitableCount',
                        subtitle: strings.t('decisionRecommended'),
                        icon: Icons.check_circle_rounded,
                        color: green,
                      ),
                      MetricTile(
                        label: strings.t('needsAttention'),
                        value: '$cautionCount',
                        subtitle: strings.t('decisionCaution'),
                        icon: Icons.warning_rounded,
                        color: amber,
                      ),
                      MetricTile(
                        label: strings.t('avoidProducts'),
                        value: '$blockedCount',
                        subtitle: strings.t('decisionNotRecommended'),
                        icon: Icons.block_rounded,
                        color: danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: strings.t('scanProduct'),
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: onOpenScanner,
                  ),
                ],
              ),
            ),
            AppCard(
              title: strings.t('latestProductChecks'),
              subtitle: strings.t('latestProductChecksSubtitle'),
              child: items.isEmpty
                  ? StatePanel(
                      title: strings.t('noProductChecksTitle'),
                      message: strings.t('noProductChecksBody'),
                      icon: Icons.shopping_basket_rounded,
                      action: AppButton(
                        label: strings.t('scanProduct'),
                        icon: Icons.qr_code_scanner_rounded,
                        onPressed: onOpenScanner,
                      ),
                    )
                  : Column(
                      children: items.map((item) {
                        return _ProductCheckTile(
                          item: item,
                          onEdit: busy
                              ? null
                              : () => _openNoteSheet(context, item),
                          onDelete: busy
                              ? null
                              : () => context.read<ProductCheckCubit>().delete(
                                  item,
                                ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNoteSheet(BuildContext context, ProductCheck item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<ProductCheckCubit>(),
          child: _ProductCheckNoteSheet(item: item),
        );
      },
    );
  }
}

class _ProductCheckTile extends StatelessWidget {
  const _ProductCheckTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ProductCheck item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final color = _decisionColor(item.decision);
    final productName = item.productName.trim().isEmpty
        ? strings.t('unknownProduct')
        : item.productName;
    final brand = item.brand.trim();
    final barcode = item.barcode.trim();
    final meta = [
      if (brand.isNotEmpty) brand,
      if (barcode.isNotEmpty) barcode,
      _dateLabel(item.createdAt),
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_decisionIcon(item.decision), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appMutedColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _StatusChip(
                      label: strings.decision(item.decision),
                      color: color,
                    ),
                    _StatusChip(
                      label: strings.dataQuality(item.dataQualityLevel),
                      color: aqua,
                    ),
                  ],
                ),
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              IconButton(
                tooltip: strings.t('editProductNote'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_rounded),
              ),
              IconButton(
                tooltip: strings.t('delete'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }
}

class _ProductCheckNoteSheet extends StatefulWidget {
  const _ProductCheckNoteSheet({required this.item});

  final ProductCheck item;

  @override
  State<_ProductCheckNoteSheet> createState() => _ProductCheckNoteSheetState();
}

class _ProductCheckNoteSheetState extends State<_ProductCheckNoteSheet> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.item.note);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<ProductCheckCubit>().updateNote(
      item: widget.item,
      note: _note.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return AppBottomSheetScaffold(
      title: strings.t('editProductNote'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.productName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          AppFormTextField(
            label: strings.t('productNote'),
            controller: _note,
            maxLines: 4,
            prefixIcon: Icons.notes_rounded,
          ),
          AppButton(
            label: strings.t('save'),
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

Color _decisionColor(String decision) {
  return switch (decision) {
    'not_recommended' => danger,
    'use_with_caution' => amber,
    _ => green,
  };
}

IconData _decisionIcon(String decision) {
  return switch (decision) {
    'not_recommended' => Icons.block_rounded,
    'use_with_caution' => Icons.warning_rounded,
    _ => Icons.check_circle_rounded,
  };
}
