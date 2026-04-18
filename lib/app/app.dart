import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/performance_service.dart';
import '../core/services/push_notification_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/settings/presentation/providers/settings_provider.dart';
import 'router.dart';

class KnowvasApp extends ConsumerStatefulWidget {
  const KnowvasApp({super.key});

  @override
  ConsumerState<KnowvasApp> createState() => _KnowvasAppState();
}

class _KnowvasAppState extends ConsumerState<KnowvasApp> with WidgetsBindingObserver {
  Timer? _sessionPollTimer;
  int _failureCount = 0;

  static const _basePollInterval = Duration(seconds: 30);
  static const _maxPollInterval = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final duration = PerformanceService().stopAppLaunch();
      if (duration != null) {
        debugPrint('App launch completed in ${duration.inMilliseconds}ms');
      }
      final router = ref.read(routerProvider);
      PushNotificationService().setRouter(router);

      // Start session polling once the app is fully initialised
      _startPolling();
    });
  }

  @override
  void dispose() {
    _sessionPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startPolling() {
    _sessionPollTimer?.cancel();
    _sessionPollTimer = Timer(_basePollInterval, _pollSession);
  }

  Future<void> _pollSession() async {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (!isAuthenticated) {
      // Not logged in — no need to poll
      _failureCount = 0;
      return;
    }

    try {
      await ref.read(authProvider.notifier).checkSessionValidity();
      _failureCount = 0;
      // Schedule next poll at base interval
      _sessionPollTimer = Timer(_basePollInterval, _pollSession);
    } catch (_) {
      // Network error — back off exponentially, cap at max
      _failureCount++;
      final backoff = Duration(
        milliseconds: (_basePollInterval.inMilliseconds *
                (1 << _failureCount.clamp(0, 6)))
            .clamp(0, _maxPollInterval.inMilliseconds),
      );
      _sessionPollTimer = Timer(backoff, _pollSession);
    }
  }

  /// Called when the app comes back to the foreground — check immediately
  /// then reset the poll timer, mirroring the web's visibilitychange handler.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).checkSessionValidity();
      _startPolling(); // reset timer so we don't double-fire
    } else if (lifecycleState == AppLifecycleState.paused) {
      // App going to background — pause polling to save battery
      _sessionPollTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeName = ref.watch(settingsProvider.select((prefs) => prefs.theme));
    final language = ref.watch(settingsProvider.select((prefs) => prefs.language));

    final theme = themeName == 'sepia' ? AppTheme.sepiaTheme : AppTheme.lightTheme;

    Locale? locale;
    if (language.isNotEmpty && language != 'system') {
      locale = Locale(language);
    }

    return MaterialApp.router(
      title: 'Knowvas',
      theme: theme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('ar'),
      ],
    );
  }
}
