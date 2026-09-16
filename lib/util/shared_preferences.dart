/*
 *     Copyright (C) 2023  DanXi-Dev
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
 *     along with thFlutterSecureStorageis program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:encrypt/encrypt.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter/foundation.dart'
    show
        TargetPlatform,
        debugPrint,
        defaultTargetPlatform,
        kIsWeb,
        visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences is a class to store simple data in key-value pairs.
///
/// [XSharedPreferences] combines the functionality of [FlutterSecureStorage] and [EncryptedSharedPreferences],
/// in order to provide a secure way to store data.
class XSharedPreferences {
  static const String KEY_CIPHER = "XSharedPreferences_cipher";
  static const String KEY_MIGRATED = "XSharedPreferences_migrated";
  static const String PASSWORD_CANDIDATE =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

  final FlutterSecureStorage _keyStore;
  late final EncryptedSharedPreferences _preferences;

  XSharedPreferences._()
    : _keyStore = const FlutterSecureStorage(
        aOptions: AndroidOptions(migrateWithBackup: true),
        wOptions: WindowsOptions(useBackwardCompatibility: true),
      );

  static XSharedPreferences? _instance;
  static Future<XSharedPreferences>? _initialization;

  static String _generateKey() {
    Random random;
    try {
      random = Random.secure();
    } catch (_) {
      random = Random();
    }
    // generate a 16-character random string using the characters [a-z0-9A-Z].
    String key = List.generate(
      16,
      (_) => PASSWORD_CANDIDATE[random.nextInt(PASSWORD_CANDIDATE.length)],
    ).join();
    return key;
  }

  /// Returns the instance of [XSharedPreferences].
  static Future<XSharedPreferences> getInstance() {
    final instance = _instance;
    if (instance != null) return Future.value(instance);

    return _initialization ??= _initialize();
  }

  static Future<XSharedPreferences> _initialize() async {
    try {
      final instance = XSharedPreferences._();
      final sharedPreferences = await SharedPreferences.getInstance();
      await instance._recoverFromUnreadableSecureStorage(sharedPreferences);

      String? key = await instance._keyStore.read(key: KEY_CIPHER);
      if (key == null) {
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            _containsOnlyLegacyEncryptedEntries(sharedPreferences)) {
          debugPrint(
            "Discarding encrypted preferences whose cipher key is missing.",
          );
          await _clearSharedPreferences(sharedPreferences);
        }
        key = _generateKey();
        await instance._keyStore.write(key: KEY_CIPHER, value: key);
      }
      // initialize the encrypted preferences.
      await EncryptedSharedPreferences.initialize(
        key,
        encryptor: LegacyAESEncryptor(),
      );
      instance._preferences = EncryptedSharedPreferences.getInstance();
      // migrate the data from [SharedPreferences] to [EncryptedSharedPreferences]
      // if the data has not been flagged as migrated.
      if (instance.getBool(KEY_MIGRATED) != true) {
        for (String oldKey in sharedPreferences.getKeys()) {
          dynamic value = sharedPreferences.get(oldKey);
          if (value is String) {
            await instance.setString(oldKey, value);
          } else if (value is int) {
            await instance.setInt(oldKey, value);
          } else if (value is double) {
            await instance.setDouble(oldKey, value);
          } else if (value is bool) {
            await instance.setBool(oldKey, value);
          } else if (value is List<String>) {
            await instance.setStringList(oldKey, value);
          }
          await sharedPreferences.remove(oldKey);
        }
        await instance.setBool(KEY_MIGRATED, true);
      }
      _instance = instance;
      return instance;
    } catch (_) {
      // Allow a later call to retry after a transient initialization failure.
      _initialization = null;
      rethrow;
    }
  }

  static bool _containsOnlyLegacyEncryptedEntries(
    SharedPreferences sharedPreferences,
  ) {
    final keys = sharedPreferences.getKeys();
    if (keys.isEmpty) return false;

    // Requiring the whole store to match the legacy CBC shape avoids deleting
    // plaintext preferences that still need the migration below.
    return keys.every((key) {
      if (!_looksLikeLegacyCiphertext(key)) return false;

      final value = sharedPreferences.get(key);
      if (value is String) {
        return value.isEmpty || _looksLikeLegacyCiphertext(value);
      }
      if (value is List<String>) {
        return value.every(
          (item) => item.isEmpty || _looksLikeLegacyCiphertext(item),
        );
      }
      return false;
    });
  }

  static bool _looksLikeLegacyCiphertext(String value) {
    try {
      final decoded = base64Decode(value);
      return decoded.isNotEmpty && decoded.length % 16 == 0;
    } on FormatException {
      return false;
    }
  }

  static Future<void> _clearSharedPreferences(
    SharedPreferences sharedPreferences,
  ) async {
    if (!await sharedPreferences.clear()) {
      throw StateError("Failed to clear unreadable SharedPreferences data.");
    }
  }

  Future<void> _recoverFromUnreadableSecureStorage(
    SharedPreferences sharedPreferences,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final status = await _keyStore.checkUpgradeStatus();
    if (!status.hasDataLoss) return;

    debugPrint(
      "Resetting unreadable secure preferences after storage upgrade: "
      "${status.reason.name}",
    );

    // The master key is already unavailable, so neither encrypted keys nor
    // values can be identified. All current DanXi SharedPreferences access goes
    // through this class, so reset the whole namespace with secure storage.
    await _clearSharedPreferences(sharedPreferences);
    await _keyStore.deleteAll();
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
    _initialization = null;
  }

  // Proxy methods for [EncryptedSharedPreferences]

  Future<bool> clear() async {
    bool success = await _preferences.clear();
    if (success) {
      // mark the data as migrated after clearing. Or the data written after clearing will be re-migrated.
      await _instance!.setBool(KEY_MIGRATED, true);
    }
    return success;
  }

  Future<bool> remove(String key) => _preferences.remove(key);

  FutureOr<Set<String>> getKeys() => _preferences.getKeys();

  Future<bool> setString(String dataKey, String? dataValue) =>
      _preferences.setString(dataKey, dataValue);

  Future<bool> setInt(String dataKey, int? dataValue) =>
      _preferences.setInt(dataKey, dataValue);

  Future<bool> setDouble(String dataKey, double? dataValue) =>
      _preferences.setDouble(dataKey, dataValue);

  Future<bool> setBool(String dataKey, bool? dataValue) =>
      _preferences.setBoolean(dataKey, dataValue);

  Future<bool> setStringList(String dataKey, List<String>? dataValue) =>
      setString(dataKey, jsonEncode(dataValue));

  Future<bool> setIntList(String dataKey, List<int>? dataValue) =>
      setString(dataKey, jsonEncode(dataValue));

  String? getString(String key) => _preferences.getString(key);

  int? getInt(String key) => _preferences.getInt(key);

  double? getDouble(String key) => _preferences.getDouble(key);

  bool? getBool(String key) => _preferences.getBoolean(key);

  List<int>? getIntList(String key) {
    String? value = getString(key);
    return value == null ? null : jsonDecode(value).cast<int>();
  }

  List<String>? getStringList(String key) {
    String? value = getString(key);
    return value == null ? null : jsonDecode(value).cast<String>();
  }

  bool containsKey(String key) {
    // FIXME: an ugly implementation. Call for the library to provide a better way.
    try {
      String? value = getString(key);
      return value != null;
    } catch (_) {
      return false;
    }
  }
}

/// @w568w (2024-11-26):
/// encrypt_shared_preferences quietly changed the default AES Encryptor to use SIC mode from CBC mode.
/// This is obviously a breaking change, but it is mentioned nowhere in the changelog. Average noob developer.
///
/// So this class is an implementation of the legacy AES Encryptor.
class LegacyAESEncryptor extends IEncryptor {
  @override
  String encrypt(String key, String plainText) {
    assert(key.length == 16);
    final cipherKey = Key.fromUtf8(key);
    final encryptService = Encrypter(AES(cipherKey, mode: AESMode.cbc));
    final initVector = IV.fromUtf8(key);

    Encrypted encryptedData = encryptService.encrypt(plainText, iv: initVector);
    return encryptedData.base64;
  }

  @override
  String decrypt(String key, String encryptedData) {
    assert(key.length == 16);
    final cipherKey = Key.fromUtf8(key);
    final encryptService = Encrypter(AES(cipherKey, mode: AESMode.cbc));
    final initVector = IV.fromUtf8(key);

    return encryptService.decrypt(
      Encrypted.fromBase64(encryptedData),
      iv: initVector,
    );
  }
}
