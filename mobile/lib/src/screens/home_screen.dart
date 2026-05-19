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
      padding: pagePadding,
      children: [
        HeroPanel(
          kicker: strings.t('personalNutritionEngine'),
          title: strings.t('homeHeroTitle'),
          subtitle: strings.t('homeHeroSubtitle'),
          icon: Icons.monitor_heart_rounded,
        ),
        if (profileMemory == null)
          AppCard(
            title: strings.t('currentProfile'),
            child: Text(strings.t('noBloodAnalyzed')),
          )
        else
          _ProfileSummary(memory: profileMemory!),
        if (extractedValues != null)
          _ExtractedValuesCard(values: extractedValues!),
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
        _ProfileBanner(
          label: strings.t('healthProfile'),
          value: strings.profileText(memory.healthProfile),
        ),
        _RecommendationPanel(
          label: strings.t('nutritionRecommendation'),
          value: strings.foodText(memory.nutritionRecommendation),
        ),
        _FoodSection(
          icon: Icons.add_rounded,
          label: strings.t('foodsToIncrease'),
          foods: memory.foodsToIncrease,
          accent: green,
        ),
        _FoodSection(
          icon: Icons.remove_rounded,
          label: strings.t('foodsToLimit'),
          foods: memory.foodsToLimit,
          accent: danger,
        ),
        if (memory.allergies.isNotEmpty)
          _FoodSection(
            icon: Icons.shield_rounded,
            label: strings.t('allergies'),
            foods: memory.allergies.map(strings.allergy).toList(),
            accent: violet,
          ),
      ],
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final text = value.trim().isEmpty ? strings.t('notAvailable') : value;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF0F3F37), Color(0xFF10231F)]
              : const [Color(0xFFE8F7F1), Colors.white],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: green.withValues(alpha: .32)),
        boxShadow: [
          BoxShadow(
            color: green.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: green,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: green.withValues(alpha: .28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 18, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final text = value.trim().isEmpty ? strings.t('notAvailable') : value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252A1E) : const Color(0xFFFFF9E8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: gold.withValues(alpha: .42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: ink,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodSection extends StatelessWidget {
  const _FoodSection({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10231F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: .24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .24 : .06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
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
                  color: accent.withValues(alpha: isDark ? .22 : .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(strings.t('notAvailable'))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? .18 : .09),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: .24)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isDark ? Colors.white : ink,
                      fontSize: 13,
                      height: 1.15,
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

class _ExtractedValuesCard extends StatelessWidget {
  const _ExtractedValuesCard({required this.values});

  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final entries = values.entries.take(12).toList();

    return AppCard(
      title: strings.t('latestExtractedValues'),
      child: Column(
        children: entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: appSecondaryFill(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appLineColor(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: appMutedColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
