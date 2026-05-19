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
        _InsightCard(
          icon: Icons.favorite_rounded,
          label: strings.t('healthProfile'),
          value: strings.profileText(memory.healthProfile),
          accent: green,
        ),
        _InsightCard(
          icon: Icons.restaurant_menu_rounded,
          label: strings.t('nutritionRecommendation'),
          value: strings.foodText(memory.nutritionRecommendation),
          accent: gold,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FoodListCard(
                icon: Icons.add_circle_rounded,
                label: strings.t('foodsToIncrease'),
                foods: memory.foodsToIncrease,
                accent: green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FoodListCard(
                icon: Icons.remove_circle_rounded,
                label: strings.t('foodsToLimit'),
                foods: memory.foodsToLimit,
                accent: const Color(0xFFB42318),
              ),
            ),
          ],
        ),
        if (memory.allergies.isNotEmpty)
          _FoodListCard(
            icon: Icons.shield_rounded,
            label: strings.t('allergies'),
            foods: memory.allergies.map(strings.allergy).toList(),
            accent: const Color(0xFF7C3AED),
          ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final text = value.isEmpty ? strings.t('notAvailable') : value;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .10,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FoodListCard extends StatelessWidget {
  const _FoodListCard({
    required this.icon,
    required this.label,
    required this.foods,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final List<String> foods;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final items = foods
        .map(strings.foodText)
        .where((item) => item.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(strings.t('notAvailable'))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: .28)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
