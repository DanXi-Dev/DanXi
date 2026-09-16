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
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureValues = <String, String>{};
  final calls = <String>[];
  var upgradeState = 'legacyDataUnreadable';
  var rawPreferencesEmptyWhenDeletingSecureStorage = false;

  setUp(() {
    XSharedPreferences.resetForTesting(isAndroid: true);
    secureValues.clear();
    calls.clear();
    upgradeState = 'legacyDataUnreadable';
    rawPreferencesEmptyWhenDeletingSecureStorage = false;
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
              final rawPreferences = await SharedPreferences.getInstance();
              rawPreferencesEmptyWhenDeletingSecureStorage = rawPreferences
                  .getKeys()
                  .isEmpty;
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
    XSharedPreferences.resetForTesting();
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
      expect(rawPreferencesEmptyWhenDeletingSecureStorage, isTrue);

      await preferences.setString('id', '12345678901');
      expect(preferences.getString('id'), '12345678901');
      expect(await XSharedPreferences.getInstance(), same(preferences));

      upgradeState = 'ok';
      XSharedPreferences.resetForTesting(isAndroid: true);
      final restoredPreferences = await XSharedPreferences.getInstance();

      expect(restoredPreferences.getString('id'), '12345678901');
      expect(calls.where((call) => call == 'deleteAll'), hasLength(1));
    },
  );

  test(
    'discards orphaned encrypted preferences before creating a key',
    () async {
      upgradeState = 'ok';
      const oldKey = '0123456789abcdef';
      final encryptor = LegacyAESEncryptor();
      final orphanedKey = encryptor.encrypt(oldKey, 'id');
      SharedPreferences.setMockInitialValues({
        orphanedKey: encryptor.encrypt(oldKey, '12345678901'),
      });

      final preferences = await XSharedPreferences.getInstance();
      final rawPreferences = await SharedPreferences.getInstance();

      expect(preferences.getString('id'), isNull);
      expect(rawPreferences.containsKey(orphanedKey), isFalse);
      expect(secureValues[XSharedPreferences.KEY_CIPHER], isNotNull);
    },
  );

  test(
    'preserves the plaintext migration path when the key is missing',
    () async {
      upgradeState = 'ok';
      SharedPreferences.setMockInitialValues({'legacy_id': '12345678901'});

      final preferences = await XSharedPreferences.getInstance();
      final rawPreferences = await SharedPreferences.getInstance();

      expect(preferences.getString('legacy_id'), '12345678901');
      expect(rawPreferences.containsKey('legacy_id'), isFalse);
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
