import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/ui.dart';
import '../../../../i18n.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../product_checks/data/product_check_repository.dart';
import '../../../product_checks/presentation/cubit/product_check_cubit.dart';
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
          create: (context) => ProductCheckCubit(
            repository: context.read<ProductCheckRepository>(),
          )..load(widget.user.uid),
        ),
      ],
      child: Builder(
        builder: (context) {
          final strings = AppScope.of(context).strings;
          final pages = [
            HomeScreen(onOpenScanner: () => setState(() => _tab = 3)),
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
            body: SafeArea(bottom: false, child: pages[_tab]),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: appCardColor(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border(top: BorderSide(color: appLineColor(context))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .24),
                    blurRadius: 24,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: NavigationBar(
                    height: 86,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    indicatorColor: green.withValues(alpha: .28),
                    selectedIndex: _tab,
                    onDestinationSelected: (value) =>
                        setState(() => _tab = value),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.restaurant_menu_outlined),
                        selectedIcon: const Icon(Icons.restaurant_menu),
                        label: strings.t('home'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.spa_outlined),
                        selectedIcon: const Icon(Icons.spa),
                        label: strings.t('profile'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.assignment_outlined),
                        selectedIcon: const Icon(Icons.assignment),
                        label: strings.t('tests'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.shopping_basket_outlined),
                        selectedIcon: const Icon(Icons.shopping_basket),
                        label: strings.t('scan'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.tune_outlined),
                        selectedIcon: const Icon(Icons.tune),
                        label: strings.t('settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
