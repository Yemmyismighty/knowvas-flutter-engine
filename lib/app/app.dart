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

/// Drives the session-validity poll loop.
/// Starts automatically when the user is authenticated, stops when not.
/// Lives outside the widget tree so widget rebuilds can't kill it.
final sessionPollerProvider = Provider<void>((ref) {
  const base = Duration(seconds: 15);
  const max = Duration(minutes: 2);
  int failures = 0;
  Timer? timer;

  void schedule(Duration delay) {
    timer?.cancel();
    timer = Timer(delay, () async {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      debugPrint('⏱ Session poll — isAuthenticated=$isAuthenticated');
      if (!isAuthenticated) {
        failures = 0;
        schedule(base); // keep polling so we catch re-login
        return;
      }
      try {
        await ref.read(authProvider.notifier).checkSessionValidity();
        failures = 0;
        schedule(base);
      } catch (_) {
        failures++;
        final backoff = Duration(
          milliseconds: (base.inMilliseconds * (1 << failures.clamp(0, 6)))
              .clamp(0, max.inMilliseconds),
        );
        debugPrint('⚠️ Session poll error — backoff ${backoff.inSeconds}s');
        schedule(backoff);
      }
    });
  }

  schedule(base);
  ref.onDispose(() => timer?.cancel());
});

class KnowvasApp extends ConsumerStatefulWidget {
  const KnowvasApp({super.key});

  @override
  ConsumerState<KnowvasApp> createState() => _KnowvasAppState();
}

class _KnowvasAppState extends ConsumerState<KnowvasApp> with WidgetsBindingObserver {
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
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      // Immediate check on foreground + reset the poll timer
      ref.read(authProvider.notifier).checkSessionValidity();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the session poller to keep it alive for the app's lifetime
    ref.watch(sessionPollerProvider);

    final router = ref.watch(routerProvider);
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
