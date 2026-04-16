import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KnowvasApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Knowvas Flutter Client'), findsOneWidget);
  });
}
