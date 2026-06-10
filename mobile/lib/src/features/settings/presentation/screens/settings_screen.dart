import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../services/biodietix_api.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../cubit/locale_cubit.dart';
import '../cubit/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.config,
    required this.firebaseReady,
    required this.userEmail,
    super.key,
  });

  final AppConfig config;
  final bool firebaseReady;
  final String? userEmail;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _picker = ImagePicker();
  var _busy = false;

  Future<void> _checkApi() async {
    final strings = AppScope.of(context).strings;
    if (!BioDietixApi.isConfiguredUrl(widget.config.apiUrl)) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(widget.config.apiUrl).health();
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

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 84,
    );
    if (file == null) return;
    if (mounted) {
      await context.read<ProfileCubit>().uploadProfilePhoto(File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final isDev = widget.config.flavor == AppFlavor.dev;
    final apiConfigured = BioDietixApi.isConfiguredUrl(widget.config.apiUrl);
    return ListView(
      padding: pagePadding,
      children: [
        HeroPanel(
          kicker: strings.t('biodietixMobile'),
          title: strings.t('settings'),
          subtitle: strings.t('settingsSubtitle'),
          icon: Icons.eco_rounded,
        ),
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            final loaded = state is ProfileLoaded ? state : null;
            return AppCard(
              title: strings.t('accountProfile'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: appSecondaryFill(context),
                        backgroundImage: loaded?.photoUrl == null
                            ? null
                            : NetworkImage(loaded!.photoUrl!),
                        child: loaded?.photoUrl == null
                            ? const Icon(Icons.person_rounded, size: 34)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.t('signedInAs').toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(widget.userEmail ?? '-'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (loaded?.saving == true) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (loaded?.error != null) ...[
                    const SizedBox(height: 12),
                    NoticeBox(message: loaded!.error!, warning: true),
                  ],
                  const SizedBox(height: 14),
                  AppButton(
                    label: strings.t('uploadPhotoGallery'),
                    onPressed: widget.firebaseReady
                        ? () => _pickProfilePhoto(ImageSource.gallery)
                        : null,
                    secondary: true,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: strings.t('uploadPhotoCamera'),
                    onPressed: widget.firebaseReady
                        ? () => _pickProfilePhoto(ImageSource.camera)
                        : null,
                    secondary: true,
                  ),
                  if (!widget.firebaseReady) ...[
                    const SizedBox(height: 10),
                    NoticeBox(
                      message: strings.t('firebaseMissingMessage'),
                      warning: true,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        AppCard(
          title: strings.t('language'),
          child: BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, state) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChip(
                    label: strings.t('english'),
                    selected: state.language == AppLanguage.en,
                    onTap: () =>
                        context.read<LocaleCubit>().setLanguage(AppLanguage.en),
                  ),
                  AppChip(
                    label: strings.t('turkish'),
                    selected: state.language == AppLanguage.tr,
                    onTap: () =>
                        context.read<LocaleCubit>().setLanguage(AppLanguage.tr),
                  ),
                ],
              );
            },
          ),
        ),
        AppCard(
          title: strings.t('appearance'),
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChip(
                    label: strings.t('system'),
                    selected: state.mode == ThemeMode.system,
                    onTap: () => context.read<ThemeCubit>().setThemeMode(
                      ThemeMode.system,
                    ),
                  ),
                  AppChip(
                    label: strings.t('light'),
                    selected: state.mode == ThemeMode.light,
                    onTap: () => context.read<ThemeCubit>().setThemeMode(
                      ThemeMode.light,
                    ),
                  ),
                  AppChip(
                    label: strings.t('dark'),
                    selected: state.mode == ThemeMode.dark,
                    onTap: () =>
                        context.read<ThemeCubit>().setThemeMode(ThemeMode.dark),
                  ),
                ],
              );
            },
          ),
        ),
        AppCard(
          title: strings.t('cloudService'),
          subtitle: strings.t('cloudServiceSubtitle'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConnectionStatusRow(
                online: apiConfigured,
                label: apiConfigured
                    ? strings.t('serviceReady')
                    : strings.t('serviceUnavailable'),
              ),
              if (isDev) ...[
                const SizedBox(height: 14),
                Text(
                  strings.t('flavor').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                Text(widget.config.flavor.value),
                const SizedBox(height: 14),
                Text(
                  strings.t('serviceEndpoint').toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  apiConfigured
                      ? widget.config.apiUrl
                      : strings.t('notConfigured'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (!apiConfigured) ...[
                const SizedBox(height: 14),
                NoticeBox(
                  message: strings.t('serverNotConfigured'),
                  warning: true,
                ),
              ],
              const SizedBox(height: 14),
              AppButton(
                label: strings.t('checkApiConnection'),
                onPressed: apiConfigured ? _checkApi : null,
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
              AppButton(
                label: strings.t('signOut'),
                onPressed: context.read<AuthCubit>().signOut,
                secondary: true,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: strings.t('deleteHealthData'),
                onPressed: context.read<ProfileCubit>().clearHealthData,
                secondary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConnectionStatusRow extends StatelessWidget {
  const _ConnectionStatusRow({required this.online, required this.label});

  final bool online;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = online ? green : amber;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .08,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
