import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../i18n.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../meal_logs/data/meal_log_repository.dart';
import '../../../meal_logs/presentation/cubit/meal_log_cubit.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../scan/presentation/screens/scan_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../tests/presentation/screens/tests_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.user,
    required this.config,
    required this.firebaseReady,
    super.key,
  });

  final User user;
  final AppConfig config;
  final bool firebaseReady;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ProfileCubit(repository: context.read<ProfileRepository>())
                ..load(widget.user.uid),
        ),
        BlocProvider(
          create: (context) =>
              MealLogCubit(repository: context.read<MealLogRepository>())
                ..load(widget.user.uid),
        ),
      ],
      child: Builder(
        builder: (context) {
          final strings = AppScope.of(context).strings;
          final pages = [
            const HomeScreen(),
            const ProfileScreen(),
            TestsScreen(apiUrl: widget.config.apiUrl),
            ScanScreen(apiUrl: widget.config.apiUrl),
            SettingsScreen(
              config: widget.config,
              firebaseReady: widget.firebaseReady,
              userEmail: widget.user.email,
            ),
          ];

          return Scaffold(
            body: SafeArea(child: pages[_tab]),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: strings.t('home'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: strings.t('profile'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.science_outlined),
                  selectedIcon: const Icon(Icons.science),
                  label: strings.t('tests'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.qr_code_scanner),
                  selectedIcon: const Icon(Icons.qr_code_2),
                  label: strings.t('scan'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: strings.t('settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
