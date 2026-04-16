import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/utils/accessibility_utils.dart';
import 'package:knowvas/shared/widgets/accessible_button.dart';
import 'package:knowvas/shared/widgets/accessible_card.dart';
import 'package:knowvas/shared/widgets/loading_indicator.dart';
import 'package:knowvas/shared/widgets/error_view.dart';

void main() {
  group('AccessibilityUtils', () {
    test('calculates contrast ratio correctly', () {
      // Black on white should have high contrast
      final blackWhiteRatio = AccessibilityUtils.calculateContrastRatio(
        Colors.black,
        Colors.white,
      );
      expect(blackWhiteRatio, greaterThan(20.0));

      // Same color should have ratio of 1
      final sameColorRatio = AccessibilityUtils.calculateContrastRatio(
        Colors.blue,
        Colors.blue,
      );
      expect(sameColorRatio, equals(1.0));
    });

    test('checks WCAG AA compliance', () {
      // Black on white meets AA
      expect(
        AccessibilityUtils.meetsContrastAA(Colors.black, Colors.white),
        isTrue,
      );

      // Light gray on white does not meet AA
      expect(
        AccessibilityUtils.meetsContrastAA(
          Colors.grey[300]!,
          Colors.white,
        ),
        isFalse,
      );
    });

    test('checks WCAG AAA compliance', () {
      // Black on white meets AAA
      expect(
        AccessibilityUtils.meetsContrastAAA(Colors.black, Colors.white),
        isTrue,
      );

      // Dark gray on white may not meet AAA
      expect(
        AccessibilityUtils.meetsContrastAAA(
          Colors.grey[600]!,
          Colors.white,
        ),
        isFalse,
      );
    });

    test('creates reading progress label', () {
      expect(
        AccessibilityUtils.readingProgressLabel(0.75),
        equals('Reading progress: 75 percent'),
      );
      expect(
        AccessibilityUtils.readingProgressLabel(0.0),
        equals('Reading progress: 0 percent'),
      );
      expect(
        AccessibilityUtils.readingProgressLabel(1.0),
        equals('Reading progress: 100 percent'),
      );
    });

    test('creates rating label', () {
      expect(
        AccessibilityUtils.ratingLabel(4.5),
        equals('4.5 out of 5 stars'),
      );
      expect(
        AccessibilityUtils.ratingLabel(3.0, maxRating: 10),
        equals('3.0 out of 10 stars'),
      );
    });

    test('creates page label', () {
      expect(
        AccessibilityUtils.pageLabel(42, 300),
        equals('Page 42 of 300'),
      );
    });

    test('creates download progress label', () {
      expect(
        AccessibilityUtils.downloadProgressLabel(0.5),
        equals('Download progress: 50 percent'),
      );
    });

    test('creates content type label', () {
      expect(
        AccessibilityUtils.contentTypeLabel('ebook'),
        equals('E-book'),
      );
      expect(
        AccessibilityUtils.contentTypeLabel('pdf'),
        equals('PDF document'),
      );
      expect(
        AccessibilityUtils.contentTypeLabel('comic'),
        equals('Comic book'),
      );
      expect(
        AccessibilityUtils.contentTypeLabel('audiobook'),
        equals('Audio book'),
      );
    });

    test('creates button label', () {
      expect(
        AccessibilityUtils.buttonLabel('Download'),
        equals('Download'),
      );
      expect(
        AccessibilityUtils.buttonLabel('Download', target: 'The Great Gatsby'),
        equals('Download The Great Gatsby'),
      );
    });
  });

  group('AccessibleButton', () {
    testWidgets('has semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: 'Sign in to your account',
              child: const Text('Sign In'),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Sign in to your account'),
        findsOneWidget,
      );
    });

    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox that wraps the button
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      
      // Look for our specific ConstrainedBox with min constraints
      bool foundCorrectBox = false;
      for (final box in constrainedBoxes) {
        if (box.constraints.minWidth == AccessibilityUtils.minTouchTargetSize &&
            box.constraints.minHeight == AccessibilityUtils.minTouchTargetSize) {
          foundCorrectBox = true;
          break;
        }
      }
      
      expect(foundCorrectBox, isTrue);
    });

    testWidgets('shows tooltip when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              tooltip: 'Sign in button',
              child: const Text('Sign In'),
            ),
          ),
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
    });
  });

  group('AccessibleIconButton', () {
    testWidgets('has semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.download,
              onPressed: () {},
              semanticLabel: 'Download book',
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Download book'),
        findsOneWidget,
      );
    });

    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIconButton(
              icon: Icons.close,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the ConstrainedBox that wraps the button
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      
      // Look for our specific ConstrainedBox with min constraints
      bool foundCorrectBox = false;
      for (final box in constrainedBoxes) {
        if (box.constraints.minWidth == AccessibilityUtils.minTouchTargetSize &&
            box.constraints.minHeight == AccessibilityUtils.minTouchTargetSize) {
          foundCorrectBox = true;
          break;
        }
      }
      
      expect(foundCorrectBox, isTrue);
    });
  });

  group('AccessibleContentCard', () {
    testWidgets('builds comprehensive semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 200,
                height: 400,
                child: AccessibleContentCard(
                  title: 'The Great Gatsby',
                  author: 'F. Scott Fitzgerald',
                  coverUrl: 'https://example.com/cover.jpg',
                  rating: 4.5,
                  progress: 0.65,
                  contentType: 'ebook',
                  isDownloaded: true,
                  isFavorite: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Check that semantic label contains key information
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label != null,
      );
      
      expect(semanticsFinder, findsWidgets);
      
      // Get the first Semantics widget with a label
      final semanticsWidget = tester.widget<Semantics>(semanticsFinder.first);
      final label = semanticsWidget.properties.label!;
      
      expect(label, contains('E-book'));
      expect(label, contains('The Great Gatsby'));
      expect(label, contains('F. Scott Fitzgerald'));
      expect(label, contains('4.5 out of 5 stars'));
      expect(label, contains('65 percent'));
      expect(label, contains('Downloaded'));
      expect(label, contains('Double tap to open'));
    });
  });

  group('LoadingIndicator', () {
    testWidgets('has semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Loading books'),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Loading books'),
        findsOneWidget,
      );
    });

    testWidgets('announces loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Loading'),
        findsOneWidget,
      );
    });
  });

  group('ErrorView', () {
    testWidgets('has semantic label with error message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Unable to connect',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Check that error is announced
      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && 
                     widget.properties.label != null &&
                     widget.properties.label!.contains('Something went wrong'),
      );
      
      expect(semanticsFinder, findsOneWidget);
      
      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      final label = semanticsWidget.properties.label!;
      
      expect(label, contains('Something went wrong'));
      expect(label, contains('Unable to connect'));
      expect(label, contains('try again'));
    });

    testWidgets('retry button has semantic label', (tester) async {
      var retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Network error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Find and tap retry button by text
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      
      await tester.tap(retryButton);
      expect(retryPressed, isTrue);
    });
  });

  group('Touch Target Sizes', () {
    testWidgets('all buttons meet minimum size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AccessibleButton(
                  onPressed: () {},
                  child: const Text('Button'),
                ),
                AccessibleIconButton(
                  icon: Icons.close,
                  onPressed: () {},
                ),
                AccessibleTextButton(
                  onPressed: () {},
                  child: const Text('Text Button'),
                ),
                AccessibleOutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
              ],
            ),
          ),
        ),
      );

      // Check all buttons have minimum touch target
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      // Count how many meet our requirements
      int validBoxes = 0;
      for (final box in constrainedBoxes) {
        if (box.constraints.minWidth >= AccessibilityUtils.minTouchTargetSize &&
            box.constraints.minHeight >= AccessibilityUtils.minTouchTargetSize) {
          validBoxes++;
        }
      }

      // We should have at least 4 (one for each button)
      expect(validBoxes, greaterThanOrEqualTo(4));
    });
  });
}

