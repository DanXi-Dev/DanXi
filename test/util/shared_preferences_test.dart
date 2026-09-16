/*
 *     Copyright (C) 2026  DanXi-Dev
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

import 'package:dan_xi/util/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureValues = <String, String>{};
  final calls = <String>[];
  var upgradeState = 'legacyDataUnreadable';

  setUp(() {
    XSharedPreferences.resetForTesting();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    secureValues.clear();
    calls.clear();
    upgradeState = 'legacyDataUnreadable';
    SharedPreferences.setMockInitialValues({'stale_ciphertext': 'unreadable'});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          final arguments =
              (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          switch (call.method) {
            case 'checkUpgradeStatus':
              return <String, Object>{
                'state': upgradeState,
                'reason': upgradeState == 'ok' ? 'none' : 'missingKeyMaterial',
                'entryCount': upgradeState == 'ok' ? 0 : 1,
                'willDiscardOnNextAccess': upgradeState != 'ok',
              };
            case 'deleteAll':
              secureValues.clear();
              return null;
            case 'read':
              return secureValues[arguments['key']];
            case 'write':
              secureValues[arguments['key'] as String] =
                  arguments['value'] as String;
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'rebuilds preferences once when secure storage data is unreadable',
    () async {
      final preferences = await XSharedPreferences.getInstance();
      final rawPreferences = await SharedPreferences.getInstance();

      expect(rawPreferences.containsKey('stale_ciphertext'), isFalse);
      expect(calls, containsAllInOrder(['checkUpgradeStatus', 'deleteAll']));

      await preferences.setString('id', '12345678901');
      expect(preferences.getString('id'), '12345678901');
      expect(await XSharedPreferences.getInstance(), same(preferences));

      upgradeState = 'ok';
      XSharedPreferences.resetForTesting();
      final restoredPreferences = await XSharedPreferences.getInstance();

      expect(restoredPreferences.getString('id'), '12345678901');
      expect(calls.where((call) => call == 'deleteAll'), hasLength(1));
    },
  );

  test('shares one initialization across concurrent callers', () async {
    upgradeState = 'ok';
    SharedPreferences.setMockInitialValues({});

    final instances = await Future.wait([
      XSharedPreferences.getInstance(),
      XSharedPreferences.getInstance(),
    ]);

    expect(instances[1], same(instances[0]));
    expect(calls.where((call) => call == 'checkUpgradeStatus'), hasLength(1));
    expect(calls.where((call) => call == 'read'), hasLength(1));
    expect(calls.where((call) => call == 'write'), hasLength(1));
  });
}
