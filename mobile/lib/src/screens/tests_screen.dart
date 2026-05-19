import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models/personal_info.dart';
import '../models/profile_memory.dart';
import '../services/biodietix_api.dart';
import '../widgets/ui.dart';

class TestsScreen extends StatefulWidget {
  const TestsScreen({
    required this.apiUrl,
    required this.personalInfo,
    required this.allergies,
    required this.onAllergiesChanged,
    required this.onProfileMemory,
    required this.onExtractedValues,
    super.key,
  });

  final String apiUrl;
  final PersonalInfo personalInfo;
  final List<String> allergies;
  final ValueChanged<List<String>> onAllergiesChanged;
  final Future<void> Function(ProfileMemory memory) onProfileMemory;
  final ValueChanged<Map<String, dynamic>> onExtractedValues;

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  var _busy = false;
  String? _preview;

  bool get _serverReady => BioDietixApi.isConfiguredUrl(widget.apiUrl);

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

  Future<void> _uploadBloodPdf() async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final file = await _pickPdf();
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(widget.apiUrl).analyzeBloodPdf(
        file: file,
        personalInfo: widget.personalInfo,
        allergies: widget.allergies,
      );
      await widget.onProfileMemory(result.profileMemory);
      widget.onExtractedValues(result.extractedValues);
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

  Future<void> _uploadAllergyPdf() async {
    final strings = AppScope.of(context).strings;
    if (!_serverReady) {
      showAppSnack(context, strings.t('serverNotConfigured'));
      return;
    }

    final file = await _pickPdf();
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final result = await BioDietixApi(widget.apiUrl).analyzeAllergyPdf(file);
      final next = {...widget.allergies, ...result.allergies}.toList();
      widget.onAllergiesChanged(next);
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
    return ListView(
      padding: pagePadding,
      children: [
        HeroPanel(
          kicker: strings.t('biodietixMobile'),
          title: strings.t('tests'),
          subtitle: strings.t('testsSubtitle'),
          icon: Icons.science_rounded,
        ),
        AppCard(
          title: strings.t('labReports'),
          child: Column(
            children: [
              if (!_serverReady)
                NoticeBox(
                  message: strings.t('serverNotConfigured'),
                  warning: true,
                ),
              AppButton(
                label: strings.t('uploadBloodPdf'),
                onPressed: _serverReady ? _uploadBloodPdf : null,
                busy: _busy,
              ),
              const SizedBox(height: 10),
              AppButton(
                label: strings.t('uploadAllergyPdf'),
                onPressed: _serverReady ? _uploadAllergyPdf : null,
                secondary: true,
                busy: _busy,
              ),
            ],
          ),
        ),
        AppCard(
          title: strings.t('currentAllergies'),
          child: widget.allergies.isEmpty
              ? Text(strings.t('noAllergiesSaved'))
              : Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.allergies.map((allergy) {
                    return Chip(
                      label: Text(strings.allergy(allergy)),
                      backgroundColor: appSecondaryFill(context),
                    );
                  }).toList(),
                ),
        ),
        if (_preview != null)
          AppCard(
            title: strings.t('pdfTextPreview'),
            child: Text(
              _preview!.length > 1200
                  ? _preview!.substring(0, 1200)
                  : _preview!,
            ),
          ),
      ],
    );
  }
}
