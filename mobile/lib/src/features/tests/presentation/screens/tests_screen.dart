import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/diagnostics/safe_diagnostics.dart';
import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../../i18n/profile_summary_localizer.dart';
import '../../../../models/profile_memory.dart';
import '../../../../services/biodietix_api.dart';
import '../../../../services/pdf_upload_source.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({required this.apiUrl, this.pdfPicker, super.key});

  final String apiUrl;
  final PdfPickerService? pdfPicker;

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  var _busy = false;
  String? _preview;

  PdfPickerService get _pdfPicker => widget.pdfPicker ?? PdfPickerService();

  bool get _serverReady => BioDietixApi.isConfiguredUrl(widget.apiUrl);

  String _errorMessage(AppStrings strings, Object error) {
    if (error is BioDietixApiException) {
      return strings.t(error.localizationKey);
    }
    return strings.t('apiRequestFailedError');
  }

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

  Future<PdfUploadSource?> _pickPdf({
    required String operation,
    required String requestId,
  }) async {
    safeDebugLog(
      'pdf_upload',
      'picker_opened',
      requestId: requestId,
      fields: {'operation': operation},
    );
    final selected = await _pdfPicker.pickPdf();
    safeDebugLog(
      'pdf_upload',
      'picker_returned',
      requestId: requestId,
      fields: {'operation': operation, 'has_result': selected != null},
    );
    if (selected == null) {
      safeDebugLog(
        'pdf_upload',
        'picker_cancelled',
        requestId: requestId,
        fields: {'operation': operation},
      );
      return null;
    }
    safeDebugLog(
      'pdf_upload',
      'file_selected',
      requestId: requestId,
      fields: {
        'operation': operation,
        'filename': selected.safeNameForLog,
        'reported_size': selected.size,
        'path_present': selected.hasPath,
        'bytes_present': selected.hasBytes,
      },
    );
    return selected;
  }

  Future<bool> _confirmHealthUpload() async {
    final strings = AppScope.of(context).strings;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.t('healthUploadConsentTitle')),
            content: Text(strings.t('healthUploadConsentBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.t('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.t('continueAction')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _uploadBloodPdf(ProfileLoaded profile) async {
    final strings = AppScope.of(context).strings;
    final requestId = BioDietixApi.newRequestId();
    safeDebugLog(
      'pdf_upload',
      'button_pressed',
      requestId: requestId,
      fields: {'operation': 'blood_pdf'},
    );
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final profileCubit = context.read<ProfileCubit>();
    try {
      if (!await _confirmHealthUpload() || !mounted) return;
      final pdf = await _pickPdf(operation: 'blood_pdf', requestId: requestId);
      if (pdf == null || !mounted) return;
      setState(() => _busy = true);
      final result = await BioDietixApi(widget.apiUrl).analyzeBloodPdf(
        pdf: pdf,
        personalInfo: profile.personalInfo,
        allergies: profile.allergies,
        requestId: requestId,
      );
      await profileCubit.saveProfileMemory(
        profileMemory: result.profileMemory,
        extractedValues: result.extractedValues,
      );
      setState(() => _preview = result.textPreview);
      if (mounted) showAppSnack(context, strings.t('bloodAnalyzed'));
    } on Object catch (error, stackTrace) {
      safeDebugError(
        'pdf_upload',
        'flow_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: error is BioDietixApiException
            ? error.code.name
            : error is PdfSourceException
            ? error.code.name
            : null,
      );
      if (mounted) {
        showAppSnack(
          context,
          '${strings.t('bloodPdfFailed')}: ${_errorMessage(strings, error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadAllergyPdf(ProfileLoaded profile) async {
    final strings = AppScope.of(context).strings;
    final requestId = BioDietixApi.newRequestId();
    safeDebugLog(
      'pdf_upload',
      'button_pressed',
      requestId: requestId,
      fields: {'operation': 'allergy_pdf'},
    );
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final profileCubit = context.read<ProfileCubit>();
    try {
      if (!await _confirmHealthUpload() || !mounted) return;
      final pdf = await _pickPdf(
        operation: 'allergy_pdf',
        requestId: requestId,
      );
      if (pdf == null || !mounted) return;
      setState(() => _busy = true);
      final result = await BioDietixApi(
        widget.apiUrl,
      ).analyzeAllergyPdf(pdf, requestId: requestId);
      final next = {...profile.allergies, ...result.allergies}.toList();
      await profileCubit.saveAllergies(next);
      setState(() => _preview = result.textPreview);
      if (mounted) {
        showAppSnack(
          context,
          '${result.allergies.length} ${strings.t('allergySignalsDetected')}',
        );
      }
    } on Object catch (error, stackTrace) {
      safeDebugError(
        'pdf_upload',
        'flow_failed',
        error,
        stackTrace,
        requestId: requestId,
        errorCode: error is BioDietixApiException
            ? error.code.name
            : error is PdfSourceException
            ? error.code.name
            : null,
      );
      if (mounted) {
        showAppSnack(
          context,
          '${strings.t('allergyPdfFailed')}: ${_errorMessage(strings, error)}',
        );
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
                  NoticeBox(
                    message: strings.t('medicalDisclaimer'),
                    icon: Icons.health_and_safety_outlined,
                    warning: true,
                  ),
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
            if (memory != null && memory.dataQualityStatus == 'limited')
              NoticeBox(
                message: strings.t('limitedLabDataWarning'),
                icon: Icons.warning_amber_rounded,
                warning: true,
              ),
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
                        label: strings.labLabel(entry.key),
                        value: strings.labValue(entry.key, entry.value),
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
    final summary = LocalizedProfileSummary(
      codes: memory.displayCodes,
      language: strings.language,
      isComplete: memory.summaryLocalizationComplete,
    );
    final healthProfile = summary.healthProfile;
    final recommendation = summary.recommendation;
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
            healthProfile.trim().isEmpty
                ? strings.t('notAvailable')
                : healthProfile,
            style: const TextStyle(fontWeight: FontWeight.w900, height: 1.35),
          ),
          if (recommendation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation,
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
