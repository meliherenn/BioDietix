import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../models/personal_info.dart';
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
              icon: Icons.person_rounded,
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
          ],
        );
      },
    );
  }
}
