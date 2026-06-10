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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appCardColor(context),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: appLineColor(context)),
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: .24),
                            blurRadius: 38,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/launcher/biodietix_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
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
                    const SizedBox(height: 30),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.t('splashChecking'),
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(letterSpacing: 0),
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
