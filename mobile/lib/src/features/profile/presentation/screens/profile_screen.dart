import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../models/personal_info.dart';
import '../../../../models/profile_memory.dart';
import '../cubit/profile_cubit.dart';

const allergyOptions = {
  'milk',
  'gluten',
  'peanut',
  'tree_nut',
  'egg',
  'soy',
  'fish',
  'shellfish',
  'sesame',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  String? _syncedSignature;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _syncControllers(ProfileLoaded state) {
    final signature = [
      state.personalInfo.age,
      state.personalInfo.weightKg,
      state.personalInfo.heightCm,
    ].join(':');
    if (_syncedSignature == signature) return;
    _syncedSignature = signature;
    _age.text = state.personalInfo.age.toString();
    _weight.text = state.personalInfo.weightKg?.toString() ?? '';
    _height.text = state.personalInfo.heightCm?.toString() ?? '';
  }

  double? _number(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    return parsed != null && parsed > 0 ? parsed : null;
  }

  PersonalInfo _infoFromFields(ProfileLoaded state, {String? gender}) {
    return PersonalInfo(
      gender: gender ?? state.personalInfo.gender,
      age: int.tryParse(_age.text) ?? state.personalInfo.age,
      weightKg: _number(_weight.text),
      heightCm: _number(_height.text),
    );
  }

  void _toggleAllergy(ProfileLoaded state, String id) {
    final next = [...state.allergies];
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    context.read<ProfileCubit>().updateAllergies(next);
  }

  Future<void> _save(ProfileLoaded state) async {
    FocusScope.of(context).unfocus();
    context.read<ProfileCubit>().updatePersonalInfo(_infoFromFields(state));
    await context.read<ProfileCubit>().saveProfile();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          if (state.notice != null) {
            showAppSnack(context, strings.t(state.notice!));
          }
          if (state.error != null) showAppSnack(context, state.error!);
        } else if (state is ProfileFailure) {
          showAppSnack(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is! ProfileLoaded) {
          return Center(child: Text(strings.t('notAvailable')));
        }

        _syncControllers(state);
        return ListView(
          padding: pagePadding,
          children: [
            HeroPanel(
              kicker: strings.t('biodietixMobile'),
              title: strings.t('profile'),
              subtitle: strings.t('profileSubtitle'),
              icon: Icons.spa_rounded,
            ),
            AppCard(
              title: strings.t('personalDetails'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('gender').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      AppChip(
                        label: strings.t('female'),
                        selected: state.personalInfo.gender == 'Female',
                        onTap: () =>
                            context.read<ProfileCubit>().updatePersonalInfo(
                              _infoFromFields(state, gender: 'Female'),
                            ),
                      ),
                      AppChip(
                        label: strings.t('male'),
                        selected: state.personalInfo.gender == 'Male',
                        onTap: () =>
                            context.read<ProfileCubit>().updatePersonalInfo(
                              _infoFromFields(state, gender: 'Male'),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: strings.t('age'),
                    controller: _age,
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: strings.t('weightKg'),
                          controller: _weight,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: strings.t('heightCm'),
                          controller: _height,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    strings.t('knownAllergies').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: allergyOptions.map((id) {
                      return AppChip(
                        label: strings.allergy(id),
                        selected: state.allergies.contains(id),
                        onTap: () => _toggleAllergy(state, id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: strings.t('saveProfile'),
                    onPressed: () => _save(state),
                    busy: state.saving,
                  ),
                ],
              ),
            ),
            _DietCompassCard(
              profileMemory: state.profileMemory,
              extractedValues: state.extractedValues,
              allergies: state.allergies,
            ),
          ],
        );
      },
    );
  }
}

class _DietCompassCard extends StatelessWidget {
  const _DietCompassCard({
    required this.profileMemory,
    required this.extractedValues,
    required this.allergies,
  });

  final ProfileMemory? profileMemory;
  final Map<String, dynamic>? extractedValues;
  final List<String> allergies;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final memory = profileMemory;
    final labCount = extractedValues?.length ?? 0;
    final increase = memory == null
        ? ''
        : _foodPreview(strings, memory.foodsToIncrease);
    final limit = memory == null
        ? ''
        : _foodPreview(strings, memory.foodsToLimit);
    final hasSignals =
        increase.isNotEmpty ||
        limit.isNotEmpty ||
        labCount > 0 ||
        allergies.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appCardColor(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: appLineColor(context)),
        boxShadow: [appSoftShadow(context, opacity: .62)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: aqua.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .08
                      : .05,
                ),
                borderRadius: BorderRadius.circular(34),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.t('currentProfile').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: gold),
                    ),
                  ),
                  if (labCount > 0)
                    _StatusPill(label: '$labCount ${strings.t('labSignals')}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                strings.t('nutritionCompass'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                strings.t('homeProfileSubtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: appMutedColor(context),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (memory == null)
                NoticeBox(
                  message: strings.t('homeProfileEmptyHint'),
                  icon: Icons.spa_rounded,
                )
              else ...[
                _CompassTile(
                  icon: Icons.favorite_rounded,
                  label: strings.t('healthProfile'),
                  value: strings.profileText(memory.healthProfile),
                  color: aqua,
                ),
                const SizedBox(height: 10),
                _GuideStrip(
                  label: strings.t('todaysGuide'),
                  value: _compactRecommendation(
                    strings,
                    memory.nutritionRecommendation,
                  ),
                ),
              ],
              if (hasSignals) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (increase.isNotEmpty)
                      _CompassChip(
                        icon: Icons.trending_up_rounded,
                        label: strings.t('increaseShort'),
                        value: increase,
                        color: green,
                      ),
                    if (limit.isNotEmpty)
                      _CompassChip(
                        icon: Icons.warning_amber_rounded,
                        label: strings.t('limitShort'),
                        value: limit,
                        color: tomato,
                      ),
                    if (allergies.isNotEmpty)
                      _CompassChip(
                        icon: Icons.verified_user_rounded,
                        label: strings.t('allergies'),
                        value: '${allergies.length}',
                        color: gold,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _foodPreview(AppStrings strings, List<String> values) {
    return values
        .where((value) => value.trim().isNotEmpty)
        .take(2)
        .map(strings.foodText)
        .join(', ');
  }

  String _compactRecommendation(AppStrings strings, String value) {
    var text = strings.foodText(value).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return strings.t('notAvailable');

    text = text
        .replaceAll(
          RegExp(
            r'\s*this is not a medical diagnosis\.?',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    final sentence = RegExp(r'^(.+?[.!?])\s').firstMatch(text)?.group(1);
    final candidate = sentence == null || sentence.length < 36
        ? text
        : sentence;
    if (candidate.length <= 138) return candidate;

    final cut = candidate.substring(0, 138);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace <= 0) return '${cut.trim()}...';
    return '${cut.substring(0, lastSpace).trim()}...';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: aqua.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: aqua.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: aqua),
      ),
    );
  }
}

class _CompassTile extends StatelessWidget {
  const _CompassTile({
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
    final safeValue = value.trim().isEmpty ? strings.t('notAvailable') : value;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .09,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  safeValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStrip extends StatelessWidget {
  const _GuideStrip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: gold.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .18 : .12,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gold.withValues(alpha: .30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.local_dining_rounded, color: gold, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: gold),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassChip extends StatelessWidget {
  const _CompassChip({
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
    final safeValue = value.trim().isEmpty ? strings.t('notAvailable') : value;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 142, maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .10,
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    safeValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
