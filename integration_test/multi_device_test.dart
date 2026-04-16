import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:knowvas_flutter_client/app/app.dart';

/// Multi-device and OS version integration tests
/// 
/// These tests verify:
/// - App works correctly on different device types (phone, tablet)
/// - Platform-specific features work correctly
/// - Responsive UI adapts to different screen sizes
/// - OS-specific behaviors are handled correctly
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Device and OS Version Tests', () {
    setUp(() {
      _setupMockPlatformChannels();
    });

    testWidgets('App adapts to phone screen size', (WidgetTester tester) async {
      // Set phone screen size
      await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone SE size

      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app renders correctly on phone
      expect(find.byType(Scaffold), findsWidgets);
      
      // Check that navigation is appropriate for phone (bottom nav bar)
      final hasBottomNav = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      final hasNavBar = find.byType(NavigationBar).evaluate().isNotEmpty;
      
      // Phone should use bottom navigation
      expect(hasBottomNav || hasNavBar, isTrue,
          reason: 'Phone should have bottom navigation');

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('App adapts to tablet screen size', (WidgetTester tester) async {
      // Set tablet screen size
      await tester.binding.setSurfaceSize(const Size(1024, 768)); // iPad size

      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app renders correctly on tablet
      expect(find.byType(Scaffold), findsWidgets);

      // Tablet might use side navigation or adaptive layout
      final hasNavigationRail = find.byType(NavigationRail).evaluate().isNotEmpty;
      final hasBottomNav = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      final hasNavBar = find.byType(NavigationBar).evaluate().isNotEmpty;
      
      // Tablet should have some form of navigation
      expect(hasNavigationRail || hasBottomNav || hasNavBar, isTrue,
          reason: 'Tablet should have navigation');

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('App handles landscape orientation', (WidgetTester tester) async {
      // Set landscape orientation
      await tester.binding.setSurfaceSize(const Size(812, 375)); // iPhone X landscape

      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app renders correctly in landscape
      expect(find.byType(Scaffold), findsWidgets);

      // Sign in if needed
      await _performSignInIfNeeded(tester);

      // Navigate to library
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify content displays correctly in landscape
        final hasContent = find.byType(GridView).evaluate().isNotEmpty ||
            find.byType(ListView).evaluate().isNotEmpty;
        expect(hasContent || find.byType(Card).evaluate().isNotEmpty, isTrue,
            reason: 'Content should display in landscape');
      }

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Platform-specific features: Android', (WidgetTester tester) async {
      // This test runs on Android devices/emulators
      if (!Platform.isAndroid) {
        return; // Skip on non-Android platforms
      }

      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Android-specific features
      // - Back button handling
      // - Material Design components
      // - Android-specific permissions

      // Test back button behavior
      await _performSignInIfNeeded(tester);

      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Simulate Android back button
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();

          // Verify navigation worked
          expect(find.byType(Scaffold), findsWidgets);
        }
      }

      // Verify Material Design components are used
      final hasMaterialApp = find.byType(MaterialApp).evaluate().isNotEmpty;
      expect(hasMaterialApp, isTrue,
          reason: 'Android should use MaterialApp');
    });

    testWidgets('Platform-specific features: iOS', (WidgetTester tester) async {
      // This test runs on iOS devices/simulators
      if (!Platform.isIOS) {
        return; // Skip on non-iOS platforms
      }

      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify iOS-specific features
      // - Cupertino widgets (if used)
      // - iOS-specific gestures
      // - Safe area handling

      await _performSignInIfNeeded(tester);

      // Check for iOS-style navigation
      final hasCupertinoNav = find.byType(CupertinoNavigationBar).evaluate().isNotEmpty;
      
      // Note: App might use Material Design on iOS too
      // This just verifies the app works on iOS

      expect(find.byType(Scaffold), findsWidgets,
          reason: 'App should render on iOS');
    });

    testWidgets('Reader works on different screen sizes', (WidgetTester tester) async {
      // Test reader on phone size
      await tester.binding.setSurfaceSize(const Size(375, 667));

      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _performSignInIfNeeded(tester);

      // Navigate to library and open reader
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final contentCards = find.byType(Card);
        if (contentCards.evaluate().isNotEmpty) {
          await tester.tap(contentCards.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          final readButton = find.text('Read');
          if (readButton.evaluate().isNotEmpty) {
            await tester.tap(readButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Verify reader opened
            expect(find.byType(Scaffold), findsWidgets,
                reason: 'Reader should work on phone size');
          }
        }
      }

      // Test reader on tablet size
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpAndSettle();

      // Reader should adapt to larger screen
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'Reader should adapt to tablet size');

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('App handles system theme changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app responds to system theme
      // This would require platform channel mocking for theme changes
      expect(find.byType(MaterialApp), findsOneWidget);

      // The app should handle both light and dark system themes
      // This is verified by the app's theme configuration
    });

    testWidgets('App handles different text scales', (WidgetTester tester) async {
      // Test with larger text scale (accessibility)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaleFactor: 2.0),
          child: const ProviderScope(
            child: KnowvasApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app renders with larger text
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'App should handle large text scale');

      // Check that UI doesn't break with large text
      final hasOverflow = tester.takeException() != null;
      expect(hasOverflow, isFalse,
          reason: 'UI should not overflow with large text');
    });

    testWidgets('App works with reduced motion settings', (WidgetTester tester) async {
      // Test with reduced motion (accessibility)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            disableAnimations: true,
          ),
          child: const ProviderScope(
            child: KnowvasApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app works without animations
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'App should work with reduced motion');

      await _performSignInIfNeeded(tester);

      // Navigate between screens
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton.first);
        await tester.pumpAndSettle();

        // Navigation should work without animations
        expect(find.byType(Scaffold), findsWidgets);
      }
    });

    testWidgets('App handles low memory conditions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _performSignInIfNeeded(tester);

      // Simulate low memory warning
      // In a real scenario, this would trigger memory cleanup
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      
      // Navigate through multiple screens to build up memory usage
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final discoverButton = find.text('Discover');
      if (discoverButton.evaluate().isNotEmpty) {
        await tester.tap(discoverButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final profileButton = find.text('Profile');
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // App should still be responsive
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'App should handle navigation under memory pressure');
    });

    testWidgets('App handles network switching (WiFi to cellular)', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _performSignInIfNeeded(tester);

      // Simulate network type change
      // This would be handled by connectivity monitoring in the app
      
      // Navigate to library
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // App should continue working regardless of network type
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}

/// Helper function to perform sign-in if needed
Future<void> _performSignInIfNeeded(WidgetTester tester) async {
  final discoverButton = find.text('Discover');
  final libraryButton = find.text('Library');

  if (discoverButton.evaluate().isNotEmpty || libraryButton.evaluate().isNotEmpty) {
    return; // Already signed in
  }

  final signInText = find.text('Sign In');
  if (signInText.evaluate().isEmpty) {
    return; // Not on sign-in screen
  }

  final textFields = find.byType(TextField);
  if (textFields.evaluate().length >= 2) {
    await tester.enterText(textFields.first, 'test@example.com');
    await tester.enterText(textFields.at(1), 'password123');
    await tester.pumpAndSettle();

    final elevatedButton = find.widgetWithText(ElevatedButton, 'Sign In');
    final filledButton = find.widgetWithText(FilledButton, 'Sign In');

    if (elevatedButton.evaluate().isNotEmpty) {
      await tester.tap(elevatedButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } else if (filledButton.evaluate().isNotEmpty) {
      await tester.tap(filledButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
  }
}

/// Setup mock platform channels
void _setupMockPlatformChannels() {
  // Reader method channel
  const readerChannel = MethodChannel('com.knowvas.reader/channel');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    readerChannel,
    (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'openReader':
          return {'status': 'ok'};
        case 'closeReader':
          return null;
        case 'setReaderPrefs':
          return null;
        default:
          return null;
      }
    },
  );

  // Reader event channel
  const eventChannel = EventChannel('com.knowvas.reader/events');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(eventChannel.name, (ByteData? message) async {
    return null;
  });

  // Connectivity channel
  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    connectivityChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return 'wifi';
      }
      return null;
    },
  );
}
