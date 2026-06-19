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
        icon: Icons.restaurant_menu_rounded,
        title: strings.t('onboardLabsTitle'),
        body: strings.t('onboardLabsBody'),
        color: green,
      ),
      _OnboardingPage(
        icon: Icons.shopping_basket_rounded,
        title: strings.t('onboardScanTitle'),
        body: strings.t('onboardScanBody'),
        color: tomato,
      ),
      _OnboardingPage(
        icon: Icons.bookmark_added_rounded,
        title: strings.t('onboardOfflineTitle'),
        body: strings.t('onboardOfflineBody'),
        color: aqua,
      ),
    ];

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
          child: Padding(
            padding: pagePadding.copyWith(top: 18, bottom: 22),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BioDietixLogoMark(size: 48, showGlow: false),
                ),
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
                      width: selected ? 30 : 8,
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
                  icon: _index == pages.length - 1
                      ? Icons.arrow_forward_rounded
                      : Icons.chevron_right_rounded,
                ),
              ],
            ),
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
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NutritionIllustration(
                  icon: icon,
                  color: color,
                  size: compact ? 198 : 260,
                ),
                SizedBox(height: compact ? 18 : 34),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 24 : 28,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: appMutedColor(context),
                    fontSize: compact ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NutritionIllustration extends StatelessWidget {
  const _NutritionIllustration({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = size / 260;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 222 * scale,
            height: 222 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? .14
                    : .10,
              ),
            ),
          ),
          Container(
            width: 156 * scale,
            height: 156 * scale,
            decoration: BoxDecoration(
              color: appCardColor(context),
              shape: BoxShape.circle,
              border: Border.all(color: appLineColor(context), width: 8),
              boxShadow: [appSoftShadow(context)],
            ),
            child: Center(
              child: Container(
                width: 90 * scale,
                height: 90 * scale,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, deepGreen],
                  ),
                  borderRadius: BorderRadius.circular(32 * scale),
                ),
                child: Icon(icon, size: 44 * scale, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 12 * scale,
            top: 42 * scale,
            child: _MiniFoodCard(
              color: gold,
              icon: Icons.egg_alt_rounded,
              scale: scale,
            ),
          ),
          Positioned(
            right: 8 * scale,
            bottom: 54 * scale,
            child: _MiniFoodCard(
              color: aqua,
              icon: Icons.water_drop_rounded,
              scale: scale,
            ),
          ),
          Positioned(
            left: 40 * scale,
            bottom: 18 * scale,
            child: _MiniFoodCard(
              color: tomato,
              icon: Icons.local_fire_department_rounded,
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFoodCard extends StatelessWidget {
  const _MiniFoodCard({
    required this.color,
    required this.icon,
    required this.scale,
  });

  final Color color;
  final IconData icon;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66 * scale,
      height: 66 * scale,
      decoration: BoxDecoration(
        color: appCardColor(context),
        borderRadius: BorderRadius.circular(22 * scale),
        border: Border.all(color: appLineColor(context)),
        boxShadow: [appSoftShadow(context, opacity: .48)],
      ),
      child: Icon(icon, color: color, size: 30 * scale),
    );
  }
}
