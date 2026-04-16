import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  group('Localization Tests', () {
    testWidgets('English localization loads correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('ar'),
          ],
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Spanish localization loads correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('ar'),
          ],
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Registrarse'), findsOneWidget);
    });

    testWidgets('French localization loads correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('ar'),
          ],
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Se Connecter'), findsOneWidget);
      expect(find.text('S\'inscrire'), findsOneWidget);
    });

    testWidgets('Arabic localization loads correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('ar'),
          ],
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تسجيل الدخول'), findsOneWidget);
      expect(find.text('إنشاء حساب'), findsOneWidget);
    });

    testWidgets('RTL layout for Arabic', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('ar'),
          ],
          home: TestWidget(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the text direction is RTL
      final BuildContext context = tester.element(find.byType(TestWidget));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    test('All supported locales are valid', () {
      const supportedLocales = [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('ar'),
      ];

      for (final locale in supportedLocales) {
        expect(locale.languageCode.length, 2);
        expect(locale.languageCode, isNotEmpty);
      }
    });
  });
}

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Column(
        children: [
          Text(l10n.signIn),
          Text(l10n.signUp),
        ],
      ),
    );
  }
}
