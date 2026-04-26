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
          wOptions: WindowsOptions(useBackwardCompatibility: true),
        );

  static XSharedPreferences? _instance;

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
            (_) =>
                PASSWORD_CANDIDATE[random.nextInt(PASSWORD_CANDIDATE.length)])
        .join();
    return key;
  }

  /// Returns the instance of [XSharedPreferences].
  static Future<XSharedPreferences> getInstance() async {
    if (_instance == null) {
      _instance = XSharedPreferences._();
      // initialize the key store if the key does not exist.
      bool hasKey = await _instance!._keyStore.containsKey(key: KEY_CIPHER);
      if (!hasKey) {
        await _instance!._keyStore
            .write(key: KEY_CIPHER, value: _generateKey());
      }
      String key = (await _instance!._keyStore.read(key: KEY_CIPHER))!;
      // initialize the encrypted preferences.
      await EncryptedSharedPreferences.initialize(key,
          encryptor: LegacyAESEncryptor());
      _instance!._preferences = EncryptedSharedPreferences.getInstance();
      // migrate the data from [SharedPreferences] to [EncryptedSharedPreferences]
      // if the data has not been flagged as migrated.
      if (_instance!.getBool(KEY_MIGRATED) != true) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        for (String oldKey in sharedPreferences.getKeys()) {
          dynamic value = sharedPreferences.get(oldKey);
          if (value is String) {
            await _instance!.setString(oldKey, value);
          } else if (value is int) {
            await _instance!.setInt(oldKey, value);
          } else if (value is double) {
            await _instance!.setDouble(oldKey, value);
          } else if (value is bool) {
            await _instance!.setBool(oldKey, value);
          } else if (value is List<String>) {
            await _instance!.setStringList(oldKey, value);
          }
          await sharedPreferences.remove(oldKey);
        }
        await _instance!.setBool(KEY_MIGRATED, true);
      }
    }
    return _instance!;
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

    return encryptService.decrypt(Encrypted.fromBase64(encryptedData),
        iv: initVector);
  }
}
