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

  Future<void> _showPhotoSourceSheet() async {
    final strings = AppScope.of(context).strings;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AppBottomSheetScaffold(
        title: strings.t('photoSourceTitle'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: strings.t('gallery'),
              icon: Icons.photo_library_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _pickProfilePhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: strings.t('camera'),
              icon: Icons.photo_camera_rounded,
              secondary: true,
              onPressed: () {
                Navigator.of(context).pop();
                _pickProfilePhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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
    return AppScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            kicker: strings.t('biodietixMobile'),
            title: strings.t('settings'),
            subtitle: strings.t('settingsSubtitle'),
            trailing: const BioDietixLogoMark(size: 58),
          ),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final loaded = state is ProfileLoaded ? state : null;
              return AppCard(
                title: strings.t('accountProfile'),
                accentColor: aqua,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileAvatar(
                          radius: 39,
                          photoUrl: loaded?.photoUrl,
                          onTap: widget.firebaseReady
                              ? _showPhotoSourceSheet
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
                              Text(
                                widget.userEmail ?? '-',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (loaded?.saving == true) ...[
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(),
                    ],
                    if (loaded?.error != null) ...[
                      const SizedBox(height: 14),
                      NoticeBox(message: loaded!.error!, warning: true),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      label: strings.t('changeProfilePhoto'),
                      icon: Icons.add_a_photo_rounded,
                      onPressed: widget.firebaseReady
                          ? _showPhotoSourceSheet
                          : null,
                      secondary: true,
                    ),
                    if (!widget.firebaseReady) ...[
                      const SizedBox(height: 12),
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
            title: strings.t('appearance'),
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return AppSegmentedControl<ThemeMode>(
                  value: state.mode,
                  onChanged: context.read<ThemeCubit>().setThemeMode,
                  items: [
                    AppSegment(
                      value: ThemeMode.system,
                      label: strings.t('system'),
                      icon: Icons.auto_awesome_rounded,
                    ),
                    AppSegment(
                      value: ThemeMode.light,
                      label: strings.t('light'),
                      icon: Icons.light_mode_rounded,
                    ),
                    AppSegment(
                      value: ThemeMode.dark,
                      label: strings.t('dark'),
                      icon: Icons.dark_mode_rounded,
                    ),
                  ],
                );
              },
            ),
          ),
          AppCard(
            title: strings.t('language'),
            child: BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, state) {
                return AppSegmentedControl<AppLanguage>(
                  value: state.language,
                  onChanged: context.read<LocaleCubit>().setLanguage,
                  items: [
                    AppSegment(
                      value: AppLanguage.en,
                      label: strings.t('english'),
                      icon: Icons.language_rounded,
                    ),
                    AppSegment(
                      value: AppLanguage.tr,
                      label: strings.t('turkish'),
                      icon: Icons.translate_rounded,
                    ),
                  ],
                );
              },
            ),
          ),
          AppCard(
            title: strings.t('cloudService'),
            subtitle: strings.t('cloudServiceSubtitle'),
            accentColor: apiConfigured ? green : amber,
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
                  icon: Icons.cloud_done_rounded,
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
              children: [
                AppButton(
                  label: strings.t('signOut'),
                  icon: Icons.logout_rounded,
                  onPressed: context.read<AuthCubit>().signOut,
                  secondary: true,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: strings.t('deleteHealthData'),
                  icon: Icons.delete_outline_rounded,
                  onPressed: context.read<ProfileCubit>().clearHealthData,
                  secondary: true,
                  destructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(18),
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
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
