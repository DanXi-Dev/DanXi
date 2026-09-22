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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences is a class to store simple data in key-value pairs.
///
/// [XSharedPreferences] combines the functionality of [FlutterSecureStorage] and [EncryptedSharedPreferences],
/// in order to provide a secure way to store data.
class XSharedPreferences {
  static const String KEY_CIPHER = "XSharedPreferences_cipher";
  static const String KEY_MIGRATED = "XSharedPreferences_migrated";
  static const String _fallbackFileName = "danxi_shared_preferences.json";
  static const String PASSWORD_CANDIDATE =
      "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

  FlutterSecureStorage? _keyStore;
  late final _PreferenceBackend _backend;

  XSharedPreferences._();

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
      (_) => PASSWORD_CANDIDATE[random.nextInt(PASSWORD_CANDIDATE.length)],
    ).join();
    return key;
  }

  /// Returns the instance of [XSharedPreferences].
  static Future<XSharedPreferences> getInstance() async {
    if (_instance == null) {
      _instance = XSharedPreferences._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    if (_shouldUseFileFallback) {
      _backend = await _FilePreferenceBackend.create();
      return;
    }

    try {
      _keyStore = const FlutterSecureStorage(
        wOptions: WindowsOptions(useBackwardCompatibility: true),
      );
      bool hasKey = await _keyStore!.containsKey(key: KEY_CIPHER);
      if (!hasKey) {
        await _keyStore!.write(key: KEY_CIPHER, value: _generateKey());
      }
      String key = (await _keyStore!.read(key: KEY_CIPHER))!;
      await EncryptedSharedPreferences.initialize(
        key,
        encryptor: LegacyAESEncryptor(),
      );
      final preferences = EncryptedSharedPreferences.getInstance();
      _backend = _EncryptedPreferenceBackend(preferences);

      if (getBool(KEY_MIGRATED) != true) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        for (String oldKey in sharedPreferences.getKeys()) {
          dynamic value = sharedPreferences.get(oldKey);
          if (value is String) {
            await setString(oldKey, value);
          } else if (value is int) {
            await setInt(oldKey, value);
          } else if (value is double) {
            await setDouble(oldKey, value);
          } else if (value is bool) {
            await setBool(oldKey, value);
          } else if (value is List<String>) {
            await setStringList(oldKey, value);
          }
          await sharedPreferences.remove(oldKey);
        }
        await setBool(KEY_MIGRATED, true);
      }
    } catch (_) {
      _backend = await _FilePreferenceBackend.create();
    }
  }

  static bool get _shouldUseFileFallback =>
      !Platform.isWindows &&
      (Platform.operatingSystem == 'ohos' ||
       Platform.operatingSystem == 'harmonyos');

  // Proxy methods for [EncryptedSharedPreferences]

  Future<bool> clear() async {
    bool success = await _backend.clear();
    if (success) {
      // mark the data as migrated after clearing. Or the data written after clearing will be re-migrated.
      await _instance!.setBool(KEY_MIGRATED, true);
    }
    return success;
  }

  Future<bool> remove(String key) => _backend.remove(key);

  FutureOr<Set<String>> getKeys() => _backend.getKeys();

  Future<bool> setString(String dataKey, String? dataValue) =>
      _backend.setString(dataKey, dataValue);

  Future<bool> setInt(String dataKey, int? dataValue) =>
      _backend.setInt(dataKey, dataValue);

  Future<bool> setDouble(String dataKey, double? dataValue) =>
      _backend.setDouble(dataKey, dataValue);

  Future<bool> setBool(String dataKey, bool? dataValue) =>
      _backend.setBool(dataKey, dataValue);

  Future<bool> setStringList(String dataKey, List<String>? dataValue) =>
      setString(dataKey, jsonEncode(dataValue));

  Future<bool> setIntList(String dataKey, List<int>? dataValue) =>
      setString(dataKey, jsonEncode(dataValue));

  String? getString(String key) => _backend.getString(key);

  int? getInt(String key) => _backend.getInt(key);

  double? getDouble(String key) => _backend.getDouble(key);

  bool? getBool(String key) => _backend.getBool(key);

  List<int>? getIntList(String key) {
    String? value = getString(key);
    return value == null ? null : jsonDecode(value).cast<int>();
  }

  List<String>? getStringList(String key) {
    String? value = getString(key);
    return value == null ? null : jsonDecode(value).cast<String>();
  }

  bool containsKey(String key) {
    return _backend.containsKey(key);
  }
}

abstract class _PreferenceBackend {
  Future<bool> clear();

  Future<bool> remove(String key);

  Set<String> getKeys();

  Future<bool> setString(String dataKey, String? dataValue);

  Future<bool> setInt(String dataKey, int? dataValue);

  Future<bool> setDouble(String dataKey, double? dataValue);

  Future<bool> setBool(String dataKey, bool? dataValue);

  String? getString(String key);

  int? getInt(String key);

  double? getDouble(String key);

  bool? getBool(String key);

  bool containsKey(String key);
}

class _EncryptedPreferenceBackend implements _PreferenceBackend {
  final EncryptedSharedPreferences _preferences;

  _EncryptedPreferenceBackend(this._preferences);

  @override
  Future<bool> clear() => _preferences.clear();

  @override
  bool containsKey(String key) => _preferences.getKeys().contains(key);

  @override
  double? getDouble(String key) => _preferences.getDouble(key);

  @override
  bool? getBool(String key) => _preferences.getBoolean(key);

  @override
  int? getInt(String key) => _preferences.getInt(key);

  @override
  Set<String> getKeys() => _preferences.getKeys();

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  @override
  Future<bool> setBool(String dataKey, bool? dataValue) =>
      _preferences.setBoolean(dataKey, dataValue);

  @override
  Future<bool> setDouble(String dataKey, double? dataValue) =>
      _preferences.setDouble(dataKey, dataValue);

  @override
  Future<bool> setInt(String dataKey, int? dataValue) =>
      _preferences.setInt(dataKey, dataValue);

  @override
  Future<bool> setString(String dataKey, String? dataValue) =>
      _preferences.setString(dataKey, dataValue);
}

class _FilePreferenceBackend implements _PreferenceBackend {
  final File _file;
  Map<String, dynamic> _cache;

  _FilePreferenceBackend._(this._file, this._cache);

  static Future<_FilePreferenceBackend> create() async {
    final directory = await _resolveDirectory();
    try {
      await directory.create(recursive: true);
    } catch (_) {
      final fallback = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}.danxi',
      );
      await fallback.create(recursive: true);
      return _FilePreferenceBackend._(
        File(
          '${fallback.path}${Platform.pathSeparator}${XSharedPreferences._fallbackFileName}',
        ),
        <String, dynamic>{},
      );
    }
    final file = File(
      '${directory.path}${Platform.pathSeparator}${XSharedPreferences._fallbackFileName}',
    );
    if (!await file.exists()) {
      await file.writeAsString('{}');
      return _FilePreferenceBackend._(file, <String, dynamic>{});
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _FilePreferenceBackend._(file, decoded);
      }
    } catch (_) {}

    await file.writeAsString('{}');
    return _FilePreferenceBackend._(file, <String, dynamic>{});
  }

  static Future<Directory> _resolveDirectory() async {
    final envCandidates = <String?>[
      Platform.environment['DANXI_APP_DATA_DIR'],
      Platform.environment['HOME'],
      Platform.environment['TMPDIR'],
    ];

    for (final candidate in envCandidates) {
      if (candidate == null || candidate.isEmpty) continue;
      final directory = Directory(candidate);
      try {
        await directory.create(recursive: true);
        return Directory('${directory.path}${Platform.pathSeparator}.danxi');
      } catch (_) {}
    }

    try {
      final appDir = await getApplicationSupportDirectory();
      return Directory(appDir.path);
    } catch (_) {}

    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}.danxi',
    );
  }

  Future<bool> _persist() async {
    try {
      await _file.writeAsString(jsonEncode(_cache));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> clear() async {
    _cache = <String, dynamic>{};
    return _persist();
  }

  @override
  bool containsKey(String key) => _cache.containsKey(key);

  @override
  double? getDouble(String key) {
    final value = _cache[key];
    return value is num ? value.toDouble() : null;
  }

  @override
  bool? getBool(String key) {
    final value = _cache[key];
    return value is bool ? value : null;
  }

  @override
  int? getInt(String key) {
    final value = _cache[key];
    return value is num ? value.toInt() : null;
  }

  @override
  Set<String> getKeys() => _cache.keys.toSet();

  @override
  String? getString(String key) {
    final value = _cache[key];
    return value is String ? value : null;
  }

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    return _persist();
  }

  @override
  Future<bool> setBool(String dataKey, bool? dataValue) async {
    if (dataValue == null) {
      return remove(dataKey);
    }
    _cache[dataKey] = dataValue;
    return _persist();
  }

  @override
  Future<bool> setDouble(String dataKey, double? dataValue) async {
    if (dataValue == null) {
      return remove(dataKey);
    }
    _cache[dataKey] = dataValue;
    return _persist();
  }

  @override
  Future<bool> setInt(String dataKey, int? dataValue) async {
    if (dataValue == null) {
      return remove(dataKey);
    }
    _cache[dataKey] = dataValue;
    return _persist();
  }

  @override
  Future<bool> setString(String dataKey, String? dataValue) async {
    if (dataValue == null) {
      return remove(dataKey);
    }
    _cache[dataKey] = dataValue;
    return _persist();
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
