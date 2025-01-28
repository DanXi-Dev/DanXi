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

import 'dart:ffi';

import 'package:dan_xi/util/win32/shell.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const MAX_ITEMLENGTH = 1024;
const WCHAR_SIZE = 4;

class RegistryKeyValuePair {
  final String key;
  final String value;

  const RegistryKeyValuePair(this.key, this.value);
}

/// Read / write Windows Registry.
///
/// Mostly referred to the official [examples](https://github.com/timsneath/win32/blob/main/example/registry.dart).
/// We badly need a Windows developer :(
class Registry {
  /// Get handle of the [key] in the registry root [hive].
  static int getRegistryKeyHandle(int hive, String key) {
    final phKey = calloc<HANDLE>();
    final lpKeyPath = key.toNativeUtf16();
    try {
      if (RegOpenKeyEx(hive, lpKeyPath, 0, REG_SAM_FLAGS.KEY_READ, phKey) !=
          WIN32_ERROR.ERROR_SUCCESS) {
        throw Exception("Can't open registry key");
      }
      return phKey.value;
    } finally {
      free(phKey);
      free(lpKeyPath);
    }
  }

  /// Get a String Key-Value Pair at [hKey].
  static String getStringKey(int hKey, String keyName) {
    final pvData = calloc<BYTE>(MAX_ITEMLENGTH);
    final pcbData = calloc<DWORD>()..value = MAX_ITEMLENGTH;
    try {
      int status = RegGetValue(hKey, nullptr, keyName.toNativeUtf16(),
          REG_ROUTINE_FLAGS.RRF_RT_REG_SZ, nullptr, pvData, pcbData);
      switch (status) {
        case WIN32_ERROR.ERROR_SUCCESS:
          return pvData.cast<Utf16>().toDartString();
        default:
          throw Exception('unknown error $status');
      }
    } finally {
      free(pvData);
      free(pcbData);
    }
  }

  /// Enumerate the [index]-th Key-Value pair in a key opened as [hKey].
  ///
  /// If index > number of values, return null.
  ///
  /// If the [index]-th pair is not a String ([REG_VALUE_TYPE.REG_SZ])
  /// or the value length is more than [MAX_ITEMLENGTH], throw an exception.
  static RegistryKeyValuePair? enumerateKey(int hKey, int index) {
    final lpValueName = wsalloc(MAX_PATH);
    final lpcchValueName = calloc<DWORD>()..value = MAX_PATH;
    final lpType = calloc<DWORD>();
    final lpData = calloc<BYTE>(MAX_ITEMLENGTH);
    final lpcbData = calloc<DWORD>()..value = MAX_ITEMLENGTH;

    try {
      final status = RegEnumValue(hKey, index, lpValueName, lpcchValueName,
          nullptr, lpType, lpData, lpcbData);

      switch (status) {
        case WIN32_ERROR.ERROR_SUCCESS:
          if (lpType.value != REG_VALUE_TYPE.REG_SZ) {
            throw Exception('Non-string content.');
          }
          return RegistryKeyValuePair(
              lpValueName.toDartString(), lpData.cast<Utf16>().toDartString());

        case WIN32_ERROR.ERROR_MORE_DATA:
          throw Exception('An item required more than $MAX_ITEMLENGTH bytes.');

        case WIN32_ERROR.ERROR_NO_MORE_ITEMS:
          return null;

        default:
          throw Exception('unknown error');
      }
    } finally {
      free(lpValueName);
      free(lpcchValueName);
      free(lpType);
      free(lpData);
      free(lpcbData);
    }
  }

  /// Set a String Key-Value Pair at [hKey].
  static void setStringValue(int hKey, String keyName, String value) {
    Pointer<Utf16> nativeValue = value.toNativeUtf16();
    int status = RegSetValueEx(
        hKey,
        keyName.toNativeUtf16(),
        0,
        REG_VALUE_TYPE.REG_SZ,
        nativeValue.cast<Uint8>(),
        nativeValue.length * WCHAR_SIZE);
    switch (status) {
      case WIN32_ERROR.NO_ERROR:
        break;
      case WIN32_ERROR.ERROR_ACCESS_DENIED:
        throw Exception("Access denied");
    }
  }

  /// Set a String Key-Value Pair at [keyPath], with shell administrator permission.
  static void setStringValueA(String keyPath, String keyName, String value) {
    Win32Shell.executeShell("reg",
        param: 'add "$keyPath" /v $keyName /t reg_sz /d $value /f',
        runAsAdmin: true);
  }

  /// Delete a String Key-Value Pair at [hKey].
  static void deleteStringKey(int hKey, String keyName) {
    int status = RegDeleteValue(hKey, keyName.toNativeUtf16());
    switch (status) {
      case WIN32_ERROR.NO_ERROR:
        break;
      case WIN32_ERROR.ERROR_ACCESS_DENIED:
        throw Exception("Access denied");
    }
  }

  /// Delete a String Key-Value Pair at [hKey], with shell administrator permission.
  static void deleteStringKeyA(String keyPath, String keyName) {
    Win32Shell.executeShell("reg",
        param: 'delete "$keyPath" /v $keyName /f', runAsAdmin: true);
  }
}
