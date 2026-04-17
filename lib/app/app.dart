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

  /// Called when the app comes back to the foreground.
  /// Mirrors the web's visibility/focus listener that calls checkSessionValidity().
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).checkSessionValidity();
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
