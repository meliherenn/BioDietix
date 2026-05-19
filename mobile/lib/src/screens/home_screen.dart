import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models/profile_memory.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.profileMemory,
    required this.extractedValues,
    super.key,
  });

  final ProfileMemory? profileMemory;
  final Map<String, dynamic>? extractedValues;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        HeroPanel(
          kicker: strings.t('personalNutritionEngine'),
          title: strings.t('homeHeroTitle'),
          subtitle: strings.t('homeHeroSubtitle'),
        ),
        AppCard(
          title: strings.t('currentProfile'),
          child: profileMemory == null
              ? Text(strings.t('noBloodAnalyzed'))
              : _ProfileSummary(memory: profileMemory!),
        ),
        if (extractedValues != null)
          AppCard(
            title: strings.t('latestExtractedValues'),
            child: Column(
              children: extractedValues!.entries.take(12).map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(color: appMutedColor(context)),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.memory});

  final ProfileMemory memory;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Block(
          label: strings.t('healthProfile'),
          value: strings.profileText(memory.healthProfile),
        ),
        _Block(
          label: strings.t('nutritionRecommendation'),
          value: strings.foodText(memory.nutritionRecommendation),
        ),
        _Block(
          label: strings.t('foodsToIncrease'),
          value: strings.foodText(memory.foodsToIncrease.join(', ')),
        ),
        _Block(
          label: strings.t('foodsToLimit'),
          value: strings.foodText(memory.foodsToLimit.join(', ')),
        ),
        if (memory.allergies.isNotEmpty)
          _Block(
            label: strings.t('allergies'),
            value: memory.allergies.map(strings.allergy).join(', '),
          ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(value.isEmpty ? strings.t('notAvailable') : value),
        ],
      ),
    );
  }
}
