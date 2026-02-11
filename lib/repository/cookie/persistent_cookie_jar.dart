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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:cookie_jar/src/serializable_cookie.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/util/shared_preferences.dart';

/// A [IndependentCookieJar] that persists cookies to [XSharedPreferences].
///
/// Cookies are serialized to JSON and stored under [KEY_SESSION_COOKIES].
/// A debounce timer coalesces rapid writes into a single persist operation.
class PersistentCookieJar extends IndependentCookieJar {
  static const String KEY_SESSION_COOKIES = "session_cookies";

  final XSharedPreferences _preferences;
  Timer? _debounceTimer;
  bool _dirty = false;

  PersistentCookieJar(this._preferences);

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    await super.saveFromResponse(uri, cookies);
    _scheduleSave();
  }

  @override
  Future<void> deleteAll() async {
    await super.deleteAll();
    _debounceTimer?.cancel();
    _dirty = false;
    await _preferences.remove(KEY_SESSION_COOKIES);
  }

  /// Restore cookies from [XSharedPreferences].
  ///
  /// This is a synchronous operation because [XSharedPreferences.getString]
  /// reads from an in-memory cache that was populated during initialization.
  /// Expired cookies are filtered out during restoration.
  void restore() {
    String? json = _preferences.getString(KEY_SESSION_COOKIES);
    if (json == null) return;
    try {
      Map<String, dynamic> data =
          jsonDecode(json) as Map<String, dynamic>;
      _restoreCookieMap(data['domain'], domainCookies);
      _restoreCookieMap(data['host'], hostCookies);
    } catch (_) {}
  }

  /// Force an immediate persist if there are pending changes.
  ///
  /// Call this when the app is about to enter the background to ensure
  /// no cookie data is lost if the process is killed.
  Future<void> forceSave() async {
    if (!_dirty) return;
    _debounceTimer?.cancel();
    await _persistToDisk();
  }

  void _scheduleSave() {
    _dirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _persistToDisk();
    });
  }

  Future<void> _persistToDisk() async {
    _dirty = false;
    String json = jsonEncode(_toJson());
    await _preferences.setString(KEY_SESSION_COOKIES, json);
  }

  Map<String, dynamic> _toJson() {
    return <String, dynamic>{
      'domain': _serializeCookieMap(domainCookies),
      'host': _serializeCookieMap(hostCookies),
    };
  }

  static Map<String, dynamic> _serializeCookieMap(
      Map<String?, Map<String, Map<String, SerializableCookie>>> map) {
    Map<String, dynamic> result = <String, dynamic>{};
    map.forEach((String? domain, Map<String, Map<String, SerializableCookie>> pathMap) {
      if (domain == null) return;
      Map<String, dynamic> pathResult = <String, dynamic>{};
      pathMap.forEach((String path, Map<String, SerializableCookie> cookieMap) {
        Map<String, String> cookieResult = <String, String>{};
        cookieMap.forEach((String name, SerializableCookie cookie) {
          if (!cookie.isExpired()) {
            cookieResult[name] = cookie.toJson();
          }
        });
        if (cookieResult.isNotEmpty) {
          pathResult[path] = cookieResult;
        }
      });
      if (pathResult.isNotEmpty) {
        result[domain] = pathResult;
      }
    });
    return result;
  }

  static void _restoreCookieMap(
      dynamic jsonData,
      Map<String?, Map<String, Map<String, SerializableCookie>>> target) {
    if (jsonData is! Map<String, dynamic>) return;
    jsonData.forEach((String domain, dynamic pathMap) {
      if (pathMap is! Map<String, dynamic>) return;
      target[domain] = <String, Map<String, SerializableCookie>>{};
      pathMap.forEach((String path, dynamic cookieMap) {
        if (cookieMap is! Map<String, dynamic>) return;
        target[domain]![path] = <String, SerializableCookie>{};
        cookieMap.forEach((String name, dynamic cookieStr) {
          if (cookieStr is! String) return;
          try {
            SerializableCookie cookie =
                SerializableCookie.fromJson(cookieStr);
            if (!cookie.isExpired()) {
              target[domain]![path]![name] = cookie;
            }
          } catch (_) {}
        });
      });
    });
  }
}
