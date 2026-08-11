import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/language_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageManager.toLocale', () {
    test('uses the mainland Chinese locale for Simplified Chinese', () {
      final locale = LanguageManager.toLocale(Language.SIMPLIFIED_CHINESE);

      expect(locale.languageCode, 'zh');
      expect(locale.scriptCode, isNull);
      expect(locale.countryCode, 'CN');
      expect(S.delegate.supportedLocales, contains(locale));
    });

    test('keeps Traditional Chinese on the traditional script locale', () {
      final locale = LanguageManager.toLocale(Language.TRADITIONAL_CHINESE);

      expect(locale.languageCode, 'zh');
      expect(locale.scriptCode, 'Hant');
      expect(locale.countryCode, isNull);
    });

    testWidgets('keeps zh-CN after Flutter locale resolution', (tester) async {
      late Locale resolvedLocale;

      await tester.pumpWidget(
        MaterialApp(
          locale: LanguageManager.toLocale(Language.SIMPLIFIED_CHINESE),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [S.delegate],
          home: Builder(
            builder: (context) {
              resolvedLocale = Localizations.localeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(resolvedLocale, const Locale('zh', 'CN'));
    });
  });
}
