import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models/personal_info.dart';
import '../widgets/ui.dart';

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
  const ProfileScreen({
    required this.personalInfo,
    required this.allergies,
    required this.onPersonalInfoChanged,
    required this.onAllergiesChanged,
    required this.onSave,
    super.key,
  });

  final PersonalInfo personalInfo;
  final List<String> allergies;
  final ValueChanged<PersonalInfo> onPersonalInfoChanged;
  final ValueChanged<List<String>> onAllergiesChanged;
  final Future<void> Function() onSave;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _age;
  late final TextEditingController _weight;
  late final TextEditingController _height;

  @override
  void initState() {
    super.initState();
    _age = TextEditingController(text: widget.personalInfo.age.toString());
    _weight = TextEditingController(
      text: widget.personalInfo.weightKg?.toString() ?? '',
    );
    _height = TextEditingController(
      text: widget.personalInfo.heightCm?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  double? _number(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    return parsed != null && parsed > 0 ? parsed : null;
  }

  void _syncPersonalInfo({String? gender}) {
    widget.onPersonalInfoChanged(
      PersonalInfo(
        gender: gender ?? widget.personalInfo.gender,
        age: int.tryParse(_age.text) ?? widget.personalInfo.age,
        weightKg: _number(_weight.text),
        heightCm: _number(_height.text),
      ),
    );
  }

  void _toggleAllergy(String id) {
    final next = [...widget.allergies];
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onAllergiesChanged(next);
  }

  Future<void> _save() async {
    _syncPersonalInfo();
    await widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          title: strings.t('profile'),
          subtitle: strings.t('profileSubtitle'),
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
                    selected: widget.personalInfo.gender == 'Female',
                    onTap: () => _syncPersonalInfo(gender: 'Female'),
                  ),
                  AppChip(
                    label: strings.t('male'),
                    selected: widget.personalInfo.gender == 'Male',
                    onTap: () => _syncPersonalInfo(gender: 'Male'),
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
                    selected: widget.allergies.contains(id),
                    onTap: () => _toggleAllergy(id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              AppButton(label: strings.t('saveProfile'), onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}
