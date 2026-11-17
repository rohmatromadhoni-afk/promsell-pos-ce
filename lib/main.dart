import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:promsell_pos_ce/core/di/injection_container.dart';
import 'package:promsell_pos_ce/core/services/app_lock_lifecycle_observer.dart';
import 'package:promsell_pos_ce/core/services/app_lock_service.dart';
import 'package:promsell_pos_ce/core/services/crash_log_service.dart';
import 'package:promsell_pos_ce/core/utils/app_logger.dart';
import 'package:promsell_pos_ce/core/theme/app_theme.dart';
import 'package:promsell_pos_ce/core/shell/main_shell.dart';
import 'package:promsell_pos_ce/core/widgets/splash/app_splash_wrapper.dart';
import 'package:promsell_pos_ce/features/accounts/presentation/pages/account_gate.dart';
import 'package:promsell_pos_ce/features/home/presentation/pages/home_page.dart';
import 'package:promsell_pos_ce/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:promsell_pos_ce/features/settings/data/services/backup_restore_service.dart';
import 'package:promsell_pos_ce/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:promsell_pos_ce/features/settings/presentation/mappers/settings_locale_mapper.dart';
import 'package:promsell_pos_ce/l10n/app_localizations.dart';

void main() async {
  await runPromsellApp();
}

Future<void> runPromsellApp({bool configure = true}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Auto-rotate: POS may run in landscape (tablet) or portrait (phone).
  await _applyOrientationForDevice();

  if (configure) configureDependencies();
  final crashLogService = sl<CrashLogService>();

  FlutterError.onError = (details) {
    AppLogger.error(
      'FlutterError',
      error: details.exception,
      stack: details.stack,
    );
    crashLogService.recordError(
      details.exception,
      details.stack,
      context: 'FlutterError',
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformError', error: error, stack: stack);
    crashLogService.recordError(error, stack, context: 'PlatformError');
    return true;
  };

  final settingsCubit = sl<SettingsCubit>();

  // Startup services that touch secure storage / disk (settings load, cold
  // start lock, pre-restore cleanup) run AFTER runApp: the in-app
  // AppSplashWrapper covers the loading gap, so a hung Keystore or first-run
  // DB migration can never freeze the app at the native splash. SettingsCubit
  // additionally bounds its own read with a timeout and fails safe.
  runApp(const PromsellApp());

  await _bootstrapStartupServices(settingsCubit);
}

/// Post-first-frame startup work. Every step is individually guarded — none
/// of them may crash or hang the running app.
Future<void> _bootstrapStartupServices(SettingsCubit settingsCubit) async {
  try {
    await settingsCubit.load();
  } catch (e, stack) {
    AppLogger.error('Startup settings load crashed', error: e, stack: stack);
  }

  // V092-B.2: cold-start lock — ensure a fresh process starts with a cold
  // sensitive session, and lock again whenever the app goes to background.
  try {
    await AppLockLifecycleObserver(
      sl<AppLockService>(),
    ).start().timeout(const Duration(seconds: 5));
  } catch (e, stack) {
    AppLogger.warning(
      'startup lock observer failed or timed out',
      error: e,
      stack: stack,
    );
  }

  // V092-B.4: clean up leftover pre-restore DB backups now that the live
  // DB has opened successfully. Best-effort — never block app startup.
  try {
    await sl<BackupRestoreService>().cleanupPreRestoreBackups();
  } catch (e, stack) {
    AppLogger.warning(
      'pre_restore cleanup failed at startup',
      error: e,
      stack: stack,
    );
  }
}

class PromsellApp extends StatelessWidget {
  const PromsellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (prev, curr) =>
            prev.settings.localeCode != curr.settings.localeCode ||
            prev.settings.themeModeName != curr.settings.themeModeName ||
            prev.settings.onboardingCompleted !=
                curr.settings.onboardingCompleted,
        builder: (ctx, state) {
          final showOnboarding = !state.settings.onboardingCompleted;
          return MaterialApp(
            title: 'Barokah Karangsari',
            debugShowCheckedModeBanner: false,
            locale: settingsLocale(state.settings),
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsThemeMode(state.settings),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('id')],
            // Clamp text scaling to 1.3x — POS UI must stay usable on small tablets.
            // Auto-detect RTL from locale for future Arabic/Hebrew support.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final clampedScaler = mq.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.3,
              );
              final locale = Localizations.localeOf(context);
              final isRtl = [
                'ar',
                'he',
                'fa',
                'ur',
              ].any((code) => locale.languageCode == code);
              return MediaQuery(
                data: mq.copyWith(textScaler: clampedScaler),
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: child!,
                ),
              );
            },
            home: AppSplashWrapper(
              child: showOnboarding
                  ? const OnboardingPage()
                  : const AccountGate(child: MainShell()),
            ),
            navigatorObservers: [HomePage.routeObserver],
          );
        },
      ),
    );
  }
}

/// Allows every orientation on every device: tablet POS is used in
/// landscape, and phones can rotate too (wide layout kicks in ≥ 600 dp).
///
/// Called before any widget is built, so MediaQuery is not available.
Future<void> _applyOrientationForDevice() async {
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
}
