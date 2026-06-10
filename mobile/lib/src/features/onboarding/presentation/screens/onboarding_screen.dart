import 'package:flutter/material.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onFinished, super.key});

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final isLast = _index == 2;
    if (!isLast) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    setState(() => _busy = true);
    await widget.onFinished();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final pages = [
      _OnboardingPage(
        icon: Icons.monitor_heart_rounded,
        title: strings.t('onboardLabsTitle'),
        body: strings.t('onboardLabsBody'),
      ),
      _OnboardingPage(
        icon: Icons.qr_code_scanner_rounded,
        title: strings.t('onboardScanTitle'),
        body: strings.t('onboardScanBody'),
      ),
      _OnboardingPage(
        icon: Icons.cloud_done_rounded,
        title: strings.t('onboardOfflineTitle'),
        body: strings.t('onboardOfflineBody'),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: pagePadding.copyWith(bottom: 22),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  children: pages,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  final selected = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? green : appLineColor(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: _index == pages.length - 1
                    ? strings.t('onboardingStart')
                    : strings.t('onboardingNext'),
                onPressed: _next,
                busy: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [green, deepGreen],
            ),
            borderRadius: BorderRadius.circular(34),
          ),
          child: Icon(icon, size: 58, color: Colors.white),
        ),
        const SizedBox(height: 30),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: 28, height: 1.15),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: appMutedColor(context),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
