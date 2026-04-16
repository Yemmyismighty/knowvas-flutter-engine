import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:knowvas/features/settings/presentation/screens/notification_settings_screen.dart';

void main() {
  group('NotificationSettingsScreen', () {
    Widget createTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: NotificationSettingsScreen(),
        ),
      );
    }

    testWidgets('displays notification settings screen title', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Notification Settings'), findsOneWidget);
    });

    testWidgets('displays email notifications section', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('EMAIL NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Receive notifications via email'), findsOneWidget);
    });

    testWidgets('displays email notification types when enabled', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Releases'), findsOneWidget);
      expect(find.text('Reading Reminders'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('Promotions & Deals'), findsOneWidget);
      expect(find.text('Reading Goals'), findsOneWidget);
    });

    testWidgets('displays push notifications section', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('PUSH NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Receive notifications on your device'), findsOneWidget);
    });

    testWidgets('displays push notification types when enabled', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Content'), findsOneWidget);
      expect(find.text('Social Activity'), findsOneWidget);
      expect(find.text('Download Complete'), findsOneWidget);
    });

    testWidgets('screen renders without errors', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the screen renders
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('contains switch list tiles for notifications', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify there are multiple SwitchListTile widgets
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('contains settings sections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify there are multiple Card widgets (from SettingsSection)
      expect(find.byType(Card), findsWidgets);
    });
  });
}
