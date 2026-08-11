/*
 *     Copyright (C) 2021  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/page/forum/text_selector.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        switch (call.method) {
          case 'read':
            return '0123456789abcdef';
          case 'readAll':
            return <String, String>{};
          case 'containsKey':
            return true;
          default:
            return null;
        }
      },
    );
    SharedPreferences.setMockInitialValues({});
    await SettingsProvider.getInstance().init();
  });

  testWidgets(
      'TextSelectorPage stays scrollable on long markdown content with selection',
      (tester) async {
    final paragraph = '这是一段用于测试长文本选择复制功能的楼层内容。';
    final longContent =
        List.generate(120, (index) {
      final image = index % 10 == 0
          ? '\n\n![图片](https://example.com/img/$index.png)'
          : '';
      return '$index $paragraph$image';
    }).join('\n\n');

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        S.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: TextSelectorPage(arguments: {'text': longContent}),
    ));

    // The page renders the whole markdown inside a selectable region.
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('0 $paragraph'), findsOneWidget);

    // Scroll to the bottom: the content must not be stuck and the last
    // paragraph must become visible.
    await tester.fling(
        find.byType(ListView), const Offset(0, -8000), 6000);
    await tester.pumpAndSettle();

    expect(find.text('119 $paragraph'), findsOneWidget);
  });
}
