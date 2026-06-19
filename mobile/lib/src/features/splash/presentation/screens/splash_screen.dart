import 'package:flutter/material.dart';

import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: appBackground(context),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appBackground(context),
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF121A13)
                  : const Color(0xFFFFF3DF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BioDietixLogoMark(size: 118),
                    const SizedBox(height: 26),
                    Text(
                      strings.t('appTitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.t('splashSubtitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: appMutedColor(context),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _SplashStatus(
                            label: strings.t('splashInternet'),
                            value: strings.t('splashReady'),
                            icon: Icons.wifi_rounded,
                          ),
                          _SplashStatus(
                            label: strings.t('splashSession'),
                            value: strings.t('splashReady'),
                            icon: Icons.verified_user_rounded,
                          ),
                          _SplashStatus(
                            label: strings.t('splashHive'),
                            value: strings.t('splashReady'),
                            icon: Icons.inventory_2_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            strings.t('splashChecking'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashStatus extends StatelessWidget {
  const _SplashStatus({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: appSoftGreen(context),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: green),
          ),
        ],
      ),
    );
  }
}
