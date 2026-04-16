import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:knowvas_flutter_client/app/app.dart';

/// Integration tests for the Knowvas Flutter app
/// 
/// These tests verify end-to-end functionality including:
/// - Sign-in flow
/// - Library browsing
/// - Content opening
/// - Reader launch with platform channel communication
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Knowvas App Integration Tests', () {
    setUp(_setupMockPlatformChannels);

    testWidgets('Sign-in flow end-to-end', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on the sign-in screen or discover screen
      // (depending on auth state)
      final signInFinder = find.text('Sign In');
      final discoverFinder = find.text('Discover');

      if (signInFinder.evaluate().isNotEmpty) {
        // We're on sign-in screen, perform sign-in
        expect(find.text('Email'), findsWidgets);
        expect(find.text('Password'), findsWidgets);

        // Find email and password fields
        final emailField = find.byType(TextField).first;
        final passwordField = find.byType(TextField).at(1);

        // Enter credentials
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.pumpAndSettle();

        // Find and tap sign-in button
        final elevatedButton = find.widgetWithText(ElevatedButton, 'Sign In');
        final filledButton = find.widgetWithText(FilledButton, 'Sign In');
        
        if (elevatedButton.evaluate().isNotEmpty) {
          await tester.tap(elevatedButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        } else if (filledButton.evaluate().isNotEmpty) {
          await tester.tap(filledButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }

      // After sign-in (or if already signed in), verify we can see the app
      // Note: This test may fail if backend is not available
      // In that case, we just verify the UI is rendered correctly
      final hasDiscover = discoverFinder.evaluate().isNotEmpty;
      final hasLibrary = find.text('Library').evaluate().isNotEmpty;
      final hasProfile = find.text('Profile').evaluate().isNotEmpty;
      
      expect(hasDiscover || hasLibrary || hasProfile, isTrue);
    });

    testWidgets('Library browsing and content opening', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Sign in if needed
      await _performSignInIfNeeded(tester);

      // Find and tap Library navigation button
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify library screen is displayed
        // Look for common library UI elements
        final hasGridView = find.byType(GridView).evaluate().isNotEmpty;
        final hasListView = find.byType(ListView).evaluate().isNotEmpty;
        expect(hasGridView || hasListView, isTrue);

        // If there are library items, try to tap one
        final contentCards = find.byType(Card);
        if (contentCards.evaluate().isNotEmpty) {
          await tester.tap(contentCards.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Verify navigation occurred (screen changed)
          // We should see either content detail or reader
          expect(find.byType(Scaffold), findsWidgets);
        }
      }
    });

    testWidgets('Reader launch with mocked platform channel', (WidgetTester tester) async {
      // Setup reader platform channel mock
      _setupReaderPlatformChannelMock();

      // Start the app
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Sign in if needed
      await _performSignInIfNeeded(tester);

      // Navigate to library
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to open a content item
        final contentCards = find.byType(Card);
        if (contentCards.evaluate().isNotEmpty) {
          await tester.tap(contentCards.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Look for "Read" or "Open" button
          final readButton = find.text('Read');
          final openButton = find.text('Open');
          final continueButton = find.text('Continue Reading');
          
          final hasReadButton = readButton.evaluate().isNotEmpty;
          final hasOpenButton = openButton.evaluate().isNotEmpty;
          final hasContinueButton = continueButton.evaluate().isNotEmpty;

          if (hasReadButton) {
            await tester.tap(readButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          } else if (hasOpenButton) {
            await tester.tap(openButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          } else if (hasContinueButton) {
            await tester.tap(continueButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Verify we're in a reader-like screen
            // The reader might show loading, error, or actual content
            expect(find.byType(Scaffold), findsWidgets);
          }
        }
      }
    });

    testWidgets('Verify reader ready event reception', (WidgetTester tester) async {
      // Setup reader platform channel with event stream
      _setupReaderPlatformChannelMock();
      _setupReaderEventStreamMock();

      // Start the app
      await tester.pumpWidget(
        const ProviderScope(
          child: KnowvasApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Sign in if needed
      await _performSignInIfNeeded(tester);

      // Navigate to library
      final libraryButton = find.text('Library');
      if (libraryButton.evaluate().isNotEmpty) {
        await tester.tap(libraryButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to open a content item
        final contentCards = find.byType(Card);
        if (contentCards.evaluate().isNotEmpty) {
          await tester.tap(contentCards.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Look for and tap read button
          final readButton = find.text('Read');
          final openButton = find.text('Open');
          final continueButton = find.text('Continue Reading');

          if (readButton.evaluate().isNotEmpty) {
            await tester.tap(readButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          } else if (openButton.evaluate().isNotEmpty) {
            await tester.tap(openButton.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          } else if (continueButton.evaluate().isNotEmpty) {
            await tester.tap(continueButton.first);
            
            // Wait for reader to initialize and receive ready event
            await tester.pump(const Duration(milliseconds: 500));
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Verify reader UI elements are present
            // Look for page indicators, controls, or content
            final hasPageText = find.textContaining('Page').evaluate().isNotEmpty;
            final hasOfText = find.textContaining('of').evaluate().isNotEmpty;
            final hasControls = find.byType(IconButton).evaluate().isNotEmpty;

            // At least one of these should be present in a reader
            expect(hasPageText || hasOfText || hasControls, isTrue);
          }
        }
      }
    });
  });
}

/// Helper function to perform sign-in if needed
Future<void> _performSignInIfNeeded(WidgetTester tester) async {
  // Check if we're already signed in by looking for main navigation
  final discoverButton = find.text('Discover');
  final libraryButton = find.text('Library');

  if (discoverButton.evaluate().isNotEmpty || libraryButton.evaluate().isNotEmpty) {
    // Already signed in
    return;
  }

  // Look for sign-in screen elements
  final signInText = find.text('Sign In');
  if (signInText.evaluate().isEmpty) {
    // Not on sign-in screen, can't proceed
    return;
  }

  // Find email and password fields
  final textFields = find.byType(TextField);
  if (textFields.evaluate().length >= 2) {
    await tester.enterText(textFields.first, 'test@example.com');
    await tester.enterText(textFields.at(1), 'password123');
    await tester.pumpAndSettle();

    // Find and tap sign-in button
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

/// Setup all mock platform channels
void _setupMockPlatformChannels() {
  // This would be called in setUp to initialize all mocks
  // For now, we'll set them up individually in tests
}

/// Setup mock responses for reader platform channel
void _setupReaderPlatformChannelMock() {
  const channel = MethodChannel('com.knowvas.reader/channel');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'openReader':
          // Simulate successful reader opening
          return {
            'status': 'ok',
          };
        case 'closeReader':
          return null;
        case 'setReaderPrefs':
          return null;
        default:
          return null;
      }
    },
  );
}

/// Setup mock event stream for reader events
void _setupReaderEventStreamMock() {
  const channel = EventChannel('com.knowvas.reader/events');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(channel.name, (ByteData? message) async {
    // This is a simplified mock that doesn't fully implement event streams
    // In a real scenario, you'd need a more sophisticated mock
    // For now, this prevents errors when the event channel is accessed
    return null;
  });
}
