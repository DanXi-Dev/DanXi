import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/provider/language_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageManager.toLocale', () {
    test('uses the mainland Chinese locale for Simplified Chinese', () {
      final locale = LanguageManager.toLocale(Language.SIMPLIFIED_CHINESE);

      expect(locale.languageCode, 'zh');
      expect(locale.scriptCode, isNull);
      expect(locale.countryCode, 'CN');
    });

    test('keeps Traditional Chinese on the traditional script locale', () {
      final locale = LanguageManager.toLocale(Language.TRADITIONAL_CHINESE);

      expect(locale.languageCode, 'zh');
      expect(locale.scriptCode, 'Hant');
      expect(locale.countryCode, isNull);
    });
  });
}
