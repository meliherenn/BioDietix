import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../models/profile_memory.dart';
import '../../../meal_logs/domain/meal_log.dart';
import '../../../meal_logs/presentation/cubit/meal_log_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return ListView(
      padding: pagePadding,
      children: [
        HeroPanel(
          kicker: strings.t('personalNutritionEngine'),
          title: strings.t('homeHeroTitle'),
          subtitle: strings.t('homeHeroSubtitle'),
          icon: Icons.monitor_heart_rounded,
        ),
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const AppCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is ProfileLoaded) {
              return _ProfileSummaryCard(
                profileMemory: state.profileMemory,
                extractedValues: state.extractedValues,
              );
            }
            return AppCard(
              title: strings.t('currentProfile'),
              child: Text(strings.t('notAvailable')),
            );
          },
        ),
        _MealLogDashboard(),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.profileMemory,
    required this.extractedValues,
  });

  final ProfileMemory? profileMemory;
  final Map<String, dynamic>? extractedValues;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final memory = profileMemory;
    return AppCard(
      title: strings.t('currentProfile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory == null)
            Text(strings.t('noBloodAnalyzed'))
          else ...[
            _InfoTile(
              icon: Icons.favorite_rounded,
              label: strings.t('healthProfile'),
              value: strings.profileText(memory.healthProfile),
              color: green,
            ),
            _InfoTile(
              icon: Icons.restaurant_menu_rounded,
              label: strings.t('nutritionRecommendation'),
              value: strings.foodText(memory.nutritionRecommendation),
              color: gold,
            ),
            _ChipSection(
              title: strings.t('foodsToIncrease'),
              values: memory.foodsToIncrease.map(strings.foodText).toList(),
              color: green,
            ),
            _ChipSection(
              title: strings.t('foodsToLimit'),
              values: memory.foodsToLimit.map(strings.foodText).toList(),
              color: danger,
            ),
          ],
          if (extractedValues != null && extractedValues!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              strings.t('latestExtractedValues').toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            ...extractedValues!.entries
                .take(8)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(entry.value.toString()),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _MealLogDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return BlocConsumer<MealLogCubit, MealLogState>(
      listener: (context, state) {
        if (state is MealLogLoaded && state.error != null) {
          showAppSnack(context, state.error!);
        } else if (state is MealLogFailure) {
          showAppSnack(context, state.message);
        }
      },
      builder: (context, state) {
        final items = switch (state) {
          MealLogLoaded(:final items) => items,
          MealLogLoading(:final cached) => cached,
          _ => <MealLog>[],
        };
        final busy = state is MealLogLoaded && state.busy;

        return AppCard(
          title: strings.t('mealLogs'),
          subtitle: strings.t('mealLogsSubtitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state is MealLogLoaded && state.fromCache)
                NoticeBox(message: strings.t('offlineCacheNotice')),
              if (state is MealLogLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              AppButton(
                label: strings.t('addMealLog'),
                onPressed: busy ? null : () => _openMealSheet(context),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Text(strings.t('noMealLogs'))
              else
                ...items.map(
                  (item) => _MealLogTile(
                    item: item,
                    onEdit: busy ? null : () => _openMealSheet(context, item),
                    onDelete: busy
                        ? null
                        : () => context.read<MealLogCubit>().delete(item),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMealSheet(BuildContext context, [MealLog? item]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<MealLogCubit>(),
          child: _MealLogSheet(item: item),
        );
      },
    );
  }
}

class _MealLogTile extends StatelessWidget {
  const _MealLogTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final MealLog item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSecondaryFill(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appLineColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: green.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant_rounded, color: green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.note, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.calories} ${strings.t('kcal')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.t('edit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: strings.t('delete'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _MealLogSheet extends StatefulWidget {
  const _MealLogSheet({this.item});

  final MealLog? item;

  @override
  State<_MealLogSheet> createState() => _MealLogSheetState();
}

class _MealLogSheetState extends State<_MealLogSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _calories;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _note = TextEditingController(text: item?.note ?? '');
    _calories = TextEditingController(
      text: item == null || item.calories == 0 ? '' : item.calories.toString(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final calories = int.tryParse(_calories.text.trim()) ?? 0;
    final cubit = context.read<MealLogCubit>();
    final item = widget.item;
    if (item == null) {
      await cubit.create(
        title: _title.text.trim(),
        note: _note.text.trim(),
        calories: calories,
      );
    } else {
      await cubit.update(
        item: item,
        title: _title.text.trim(),
        note: _note.text.trim(),
        calories: calories,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item == null
                  ? strings.t('addMealLog')
                  : strings.t('editMealLog'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            AppFormTextField(
              label: strings.t('mealTitle'),
              controller: _title,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return strings.t('mealTitleRequired');
                }
                return null;
              },
            ),
            AppFormTextField(
              label: strings.t('mealNote'),
              controller: _note,
              maxLines: 3,
            ),
            AppFormTextField(
              label: strings.t('mealCalories'),
              controller: _calories,
              keyboardType: TextInputType.number,
            ),
            AppButton(label: strings.t('save'), onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final text = value.trim().isEmpty ? strings.t('notAvailable') : value;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .09,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.values,
    required this.color,
  });

  final String title;
  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.where((value) => value.trim().isNotEmpty).isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .where((value) => value.trim().isNotEmpty)
                .map(
                  (value) => Chip(
                    label: Text(value),
                    backgroundColor: color.withValues(alpha: .12),
                    side: BorderSide(color: color.withValues(alpha: .22)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
