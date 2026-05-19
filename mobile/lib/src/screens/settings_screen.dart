import 'package:flutter/material.dart';

import '../i18n.dart';
import '../services/biodietix_api.dart';
import '../widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.apiUrl,
    required this.firebaseReady,
    required this.userEmail,
    required this.language,
    required this.themeMode,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
    required this.onClearHealthData,
    required this.onSignOut,
    super.key,
  });

  final String apiUrl;
  final bool firebaseReady;
  final String? userEmail;
  final AppLanguage language;
  final ThemeMode themeMode;
  final Future<void> Function(AppLanguage language) onLanguageChanged;
  final Future<void> Function(ThemeMode themeMode) onThemeModeChanged;
  final Future<void> Function() onClearHealthData;
  final Future<void> Function() onSignOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _busy = false;

  Future<void> _checkApi() async {
    final strings = AppScope.of(context).strings;
    if (!BioDietixApi.isConfiguredUrl(widget.apiUrl)) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(widget.apiUrl).health();
      if (mounted) {
        showAppSnack(
          context,
          '${strings.t('apiConnected')}: ${result['status']}',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, '${strings.t('apiConnectionFailed')}: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AppCard(
          title: strings.t('settings'),
          subtitle: strings.t('settingsSubtitle'),
          child: const SizedBox.shrink(),
        ),
        AppCard(
          title: strings.t('language'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                label: strings.t('english'),
                selected: widget.language == AppLanguage.en,
                onTap: () => widget.onLanguageChanged(AppLanguage.en),
              ),
              AppChip(
                label: strings.t('turkish'),
                selected: widget.language == AppLanguage.tr,
                onTap: () => widget.onLanguageChanged(AppLanguage.tr),
              ),
            ],
          ),
        ),
        AppCard(
          title: strings.t('appearance'),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppChip(
                label: strings.t('system'),
                selected: widget.themeMode == ThemeMode.system,
                onTap: () => widget.onThemeModeChanged(ThemeMode.system),
              ),
              AppChip(
                label: strings.t('light'),
                selected: widget.themeMode == ThemeMode.light,
                onTap: () => widget.onThemeModeChanged(ThemeMode.light),
              ),
              AppChip(
                label: strings.t('dark'),
                selected: widget.themeMode == ThemeMode.dark,
                onTap: () => widget.onThemeModeChanged(ThemeMode.dark),
              ),
            ],
          ),
        ),
        AppCard(
          title: strings.t('server'),
          subtitle: strings.t('serverSubtitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('productionApiUrl').toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              SelectableText(
                !BioDietixApi.isConfiguredUrl(widget.apiUrl)
                    ? strings.t('notConfigured')
                    : widget.apiUrl,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              if (!BioDietixApi.isConfiguredUrl(widget.apiUrl))
                NoticeBox(
                  message: strings.t('serverNotConfigured'),
                  warning: true,
                ),
              AppButton(
                label: strings.t('checkApiConnection'),
                onPressed: BioDietixApi.isConfiguredUrl(widget.apiUrl)
                    ? _checkApi
                    : null,
                secondary: true,
                busy: _busy,
              ),
            ],
          ),
        ),
        AppCard(
          title: strings.t('account'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('signedInAs').toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
              Text(widget.userEmail ?? '-'),
              const SizedBox(height: 14),
              AppButton(
                label: strings.t('signOut'),
                onPressed: widget.onSignOut,
                secondary: true,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: strings.t('deleteHealthData'),
                onPressed: widget.onClearHealthData,
                secondary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
