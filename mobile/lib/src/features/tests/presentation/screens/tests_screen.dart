import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../models/profile_memory.dart';
import '../../../../services/biodietix_api.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({required this.apiUrl, super.key});

  final String apiUrl;

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  var _busy = false;
  String? _preview;

  bool get _serverReady => BioDietixApi.isConfiguredUrl(widget.apiUrl);

  Future<void> _openPreviewSheet(String preview) async {
    final strings = AppScope.of(context).strings;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height;
        return AppBottomSheetScaffold(
          title: strings.t('pdfTextPreview'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NoticeBox(
                message: strings.t('pdfPreviewPrivacyNote'),
                icon: Icons.article_rounded,
              ),
              Container(
                constraints: BoxConstraints(maxHeight: height * .58),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: appInputFill(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: appLineColor(context)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    preview,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.45,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  Future<void> _uploadBloodPdf(ProfileLoaded profile) async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final profileCubit = context.read<ProfileCubit>();
    final file = await _pickPdf();
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(widget.apiUrl).analyzeBloodPdf(
        file: file,
        personalInfo: profile.personalInfo,
        allergies: profile.allergies,
      );
      await profileCubit.saveProfileMemory(
        profileMemory: result.profileMemory,
        extractedValues: result.extractedValues,
      );
      setState(() => _preview = result.textPreview);
      if (mounted) showAppSnack(context, strings.t('bloodAnalyzed'));
    } catch (error) {
      if (mounted) {
        showAppSnack(context, '${strings.t('bloodPdfFailed')}: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadAllergyPdf(ProfileLoaded profile) async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final profileCubit = context.read<ProfileCubit>();
    final file = await _pickPdf();
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(widget.apiUrl).analyzeAllergyPdf(file);
      final next = {...profile.allergies, ...result.allergies}.toList();
      await profileCubit.saveAllergies(next);
      setState(() => _preview = result.textPreview);
      if (mounted) {
        showAppSnack(
          context,
          '${result.allergies.length} ${strings.t('allergySignalsDetected')}',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, '${strings.t('allergyPdfFailed')}: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final saving = _busy || state.saving;
        return ListView(
          padding: pagePadding,
          children: [
            HeroPanel(
              kicker: strings.t('biodietixMobile'),
              title: strings.t('tests'),
              subtitle: strings.t('testsSubtitle'),
              icon: Icons.assignment_rounded,
            ),
            _ReportStatusCard(
              profile: state,
              onPreviewPressed: _preview == null
                  ? null
                  : () => _openPreviewSheet(_preview!),
            ),
            AppCard(
              title: strings.t('labReports'),
              subtitle: strings.t('labReportsSubtitle'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (saving)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: LinearProgressIndicator(),
                    ),
                  if (!_serverReady)
                    NoticeBox(
                      message: strings.t('serverNotConfigured'),
                      warning: true,
                    ),
                  AppButton(
                    label: strings.t('uploadBloodPdf'),
                    onPressed: _serverReady
                        ? () => _uploadBloodPdf(state)
                        : null,
                    busy: saving,
                    icon: Icons.biotech_rounded,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: strings.t('uploadAllergyPdf'),
                    onPressed: _serverReady
                        ? () => _uploadAllergyPdf(state)
                        : null,
                    secondary: true,
                    busy: saving,
                    icon: Icons.shield_rounded,
                  ),
                ],
              ),
            ),
            AppCard(
              title: strings.t('currentAllergies'),
              child: state.allergies.isEmpty
                  ? Text(strings.t('noAllergiesSaved'))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: state.allergies.map((allergy) {
                        return Chip(
                          label: Text(strings.allergy(allergy)),
                          backgroundColor: appSecondaryFill(context),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportStatusCard extends StatelessWidget {
  const _ReportStatusCard({
    required this.profile,
    required this.onPreviewPressed,
  });

  final ProfileLoaded profile;
  final VoidCallback? onPreviewPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final memory = profile.profileMemory;
    final extractedValues =
        profile.extractedValues ?? const <String, dynamic>{};
    final hasBloodReport = memory != null || extractedValues.isNotEmpty;
    final hasAllergyReport = profile.allergies.isNotEmpty;
    final hasAnyReport = hasBloodReport || hasAllergyReport;

    return AppCard(
      title: strings.t('reportStatus'),
      subtitle: hasAnyReport
          ? strings.t('reportStatusReadyBody')
          : strings.t('reportStatusEmptyBody'),
      accentColor: hasAnyReport ? green : gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAnyReport)
            StatePanel(
              title: strings.t('noReportYetTitle'),
              message: strings.t('noReportYetBody'),
              icon: Icons.upload_file_rounded,
              color: gold,
            )
          else ...[
            if (hasBloodReport)
              _ReportReadyTile(
                icon: Icons.biotech_rounded,
                title: strings.t('bloodReportReady'),
                message: strings.t('bloodReportReadyBody'),
                color: green,
              ),
            if (hasAllergyReport)
              _ReportReadyTile(
                icon: Icons.verified_user_rounded,
                title: strings.t('allergyReportReady'),
                message: strings.t('allergyReportReadyBody'),
                color: aqua,
              ),
            if (memory != null) _ProfileMemoryPreview(memory: memory),
            if (extractedValues.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                strings.t('latestExtractedValues').toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: extractedValues.entries
                    .take(6)
                    .map(
                      (entry) => _ValuePill(
                        label: entry.key,
                        value: entry.value.toString(),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (onPreviewPressed == null)
              NoticeBox(
                message: strings.t('reportSavedOnDevice'),
                icon: Icons.offline_pin_rounded,
              )
            else ...[
              NoticeBox(
                message: strings.t('pdfPreviewSessionNotice'),
                icon: Icons.visibility_rounded,
              ),
              AppButton(
                label: strings.t('viewPdfPreview'),
                icon: Icons.article_rounded,
                onPressed: onPreviewPressed,
                secondary: true,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportReadyTile extends StatelessWidget {
  const _ReportReadyTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .09,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
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
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: appMutedColor(context),
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _ProfileMemoryPreview extends StatelessWidget {
  const _ProfileMemoryPreview({required this.memory});

  final ProfileMemory memory;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appElevatedCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appLineColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('analysisSummary').toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 9),
          Text(
            strings.profileText(memory.healthProfile).trim().isEmpty
                ? strings.t('notAvailable')
                : strings.profileText(memory.healthProfile),
            style: const TextStyle(fontWeight: FontWeight.w900, height: 1.35),
          ),
          if (memory.nutritionRecommendation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              strings.foodText(memory.nutritionRecommendation),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: appMutedColor(context),
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 152),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: appSecondaryFill(context),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: appLineColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
