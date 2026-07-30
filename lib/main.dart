import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_controller.dart';
import 'core/push_notification_service.dart';
import 'core/app_theme.dart';
import 'data/umbrella_repository.dart';
import 'firebase_options.dart';
import 'features/auth/auth_screens.dart';
import 'features/shell/app_shell.dart';
import 'widgets/app_components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (PushNotificationService.isSupported || kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await PushNotificationService.instance.initialize();
  }

  SupabaseClient? client;
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
    client = Supabase.instance.client;
  }

  runApp(UmbrellaApp(repository: UmbrellaRepository(client: client)));
}

class UmbrellaApp extends StatefulWidget {
  const UmbrellaApp({super.key, this.repository});

  final UmbrellaRepository? repository;

  @override
  State<UmbrellaApp> createState() => _UmbrellaAppState();
}

class _UmbrellaAppState extends State<UmbrellaApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(widget.repository ?? UmbrellaRepository());
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return AppScope(
          controller: _controller,
          child: MaterialApp(
            title: 'Haven — Umbrella4U',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(_controller.theme),
            scrollBehavior: const CozyScrollBehavior(),
            home: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  child: _rootFor(_controller),
                ),
                ConnectionStatusBanner(visible: _controller.offline),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _rootFor(AppController controller) {
    if (!controller.ready) {
      return const _LaunchScreen(key: ValueKey('launch'));
    }
    if (!controller.isLoggedIn && !controller.guestMode) {
      return const WelcomeScreen(key: ValueKey('welcome'));
    }
    if (controller.passwordRecovery) {
      return const SetNewPasswordScreen(key: ValueKey('password-recovery'));
    }
    if (controller.needsOnboarding) {
      return const OnboardingScreen(key: ValueKey('onboarding'));
    }
    return const AppShell(key: ValueKey('app-shell'));
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 62),
                SizedBox(height: 28),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CupertinoActivityIndicator(radius: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
