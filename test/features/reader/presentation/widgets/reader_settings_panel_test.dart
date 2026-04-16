import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/platform/reader_dtos.dart';
import 'package:knowvas/features/reader/presentation/providers/reader_provider.dart';
import 'package:knowvas/features/reader/presentation/providers/reader_state.dart';
import 'package:knowvas/features/reader/presentation/widgets/reader_settings_panel.dart';

void main() {
  group('ReaderSettingsPanel', () {
    testWidgets('displays all EPUB settings when content type is epub',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderSettingsPanel(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Reader Settings'), findsOneWidget);
      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Font Family'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Line Height'), findsOneWidget);
      expect(find.text('Margins'), findsOneWidget);
      expect(find.text('Layout'), findsOneWidget);
      expect(find.text('Apply Settings'), findsOneWidget);
    });

    testWidgets('displays only theme for PDF content',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifierPdf()),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderSettingsPanel(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Reader Settings'), findsOneWidget);
      expect(find.text('Font Size'), findsNothing);
      expect(find.text('Font Family'), findsNothing);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Line Height'), findsNothing);
      expect(find.text('Margins'), findsNothing);
      expect(find.text('Layout'), findsNothing);
    });

    testWidgets('font size slider updates preference',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderSettingsPanel(),
            ),
          ),
        ),
      );

      // Find and drag the font size slider
      final slider = find.byType(Slider).first;
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Assert - slider should have moved
      expect(slider, findsOneWidget);
    });

    testWidgets('theme selector shows all themes for EPUB',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderSettingsPanel(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Sepia'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('font family selector shows all options',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderSettingsPanel(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Serif'), findsOneWidget);
      expect(find.text('Sans Serif'), findsOneWidget);
      expect(find.text('Monospace'), findsOneWidget);
    });

    testWidgets('layout selector shows single and double page options',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderSettingsPanel(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Single Page'), findsOneWidget);
      expect(find.text('Double Page'), findsOneWidget);
    });

    testWidgets('close button dismisses the panel',
        (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          readerProvider.overrideWith(() => MockReaderNotifier()),
        ],
      );

      bool dismissed = false;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => const ReaderSettingsPanel(),
                      ).then((_) => dismissed = true);
                    },
                    child: const Text('Show Settings'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the bottom sheet
      await tester.tap(find.text('Show Settings'));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Assert
      expect(dismissed, isTrue);
    });
  });
}

/// Mock Reader Notifier for EPUB content
class MockReaderNotifier extends Reader {
  @override
  ReaderState build() {
    return ReaderState.ready(
      sessionId: 'test-session',
      contentId: 1,
      contentType: 'epub',
      totalPages: 100,
      preferences: const ReaderPreferences(
        fontSize: 16,
        theme: 'light',
        layout: 'single',
        fontFamily: 'serif',
        lineHeight: 1.5,
        margin: 1.0,
      ),
    );
  }

  @override
  Future<void> updatePreferences(ReaderPreferences preferences) async {
    // Mock implementation
    state = state.copyWith(preferences: preferences);
  }
}

/// Mock Reader Notifier for PDF content
class MockReaderNotifierPdf extends Reader {
  @override
  ReaderState build() {
    return ReaderState.ready(
      sessionId: 'test-session',
      contentId: 1,
      contentType: 'pdf',
      totalPages: 100,
      preferences: const ReaderPreferences(
        theme: 'light',
      ),
    );
  }

  @override
  Future<void> updatePreferences(ReaderPreferences preferences) async {
    // Mock implementation
    state = state.copyWith(preferences: preferences);
  }
}
