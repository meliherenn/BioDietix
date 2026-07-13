import 'package:flutter/material.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({required this.onSelected, super.key});

  final Future<void> Function(AppLanguage language) onSelected;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  AppLanguage? _busyLanguage;

  Future<void> _select(AppLanguage language) async {
    if (_busyLanguage != null) return;
    setState(() => _busyLanguage = language);
    try {
      await widget.onSelected(language);
    } finally {
      if (mounted) setState(() => _busyLanguage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: appBackground(context),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: appBackgroundGradient(context),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: pagePadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - pagePadding.vertical,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BioDietixLogoMark(size: 88),
                      const SizedBox(height: 22),
                      Text(
                        strings.t('languageSelectionBrand'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: green,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.t('languageSelectionTitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        strings.t('languageSelectionBody'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: appMutedColor(context),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _LanguageChoice(
                        key: const Key('language-choice-tr'),
                        language: AppLanguage.tr,
                        title: strings.t('languageTurkishNative'),
                        subtitle: strings.t('languageTurkishSubtitle'),
                        busy: _busyLanguage == AppLanguage.tr,
                        enabled: _busyLanguage == null,
                        onTap: _select,
                      ),
                      const SizedBox(height: 12),
                      _LanguageChoice(
                        key: const Key('language-choice-en'),
                        language: AppLanguage.en,
                        title: strings.t('languageEnglishNative'),
                        subtitle: strings.t('languageEnglishSubtitle'),
                        busy: _busyLanguage == AppLanguage.en,
                        enabled: _busyLanguage == null,
                        onTap: _select,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.language,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final AppLanguage language;
  final String title;
  final String subtitle;
  final bool busy;
  final bool enabled;
  final ValueChanged<AppLanguage> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: Material(
        color: appCardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: appLineColor(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onTap(language) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: appSoftGreen(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      language.code.toUpperCase(),
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (busy)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    const Icon(Icons.arrow_forward_rounded, color: green),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
