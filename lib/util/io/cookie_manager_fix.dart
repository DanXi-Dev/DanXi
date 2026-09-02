/*
 *     Copyright (C) 2025  DanXi-Dev
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

import 'dart:io';

import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

/// Coordinates shared session cookies with isolated login transactions.
///
/// This class is used to ensure that [_cookieJar] is not overwritten by old in-flight requests when a new login occurs.
/// It maintains an [_epoch] counter that increments whenever login cookies are committed, and tracks the last epoch for each cookie storage key.
///
/// See https://github.com/DanXi-Dev/DanXi/issues/701 for more details.
class SessionCookieCoordinator {
  static const String _REQUEST_EPOCH = 'fudan_session_cookie_epoch';

  final IndependentCookieJar _cookieJar;
  final Mutex _mutex = Mutex();
  final Map<CookieStorageKey, int> _lastLoginChangeEpoch =
      <CookieStorageKey, int>{};
  int _epoch = 0;

  SessionCookieCoordinator(this._cookieJar);

  /// Atomic helper for reading cookie epoch and load cookies together.
  ///
  /// [loader] should be a function that loads cookies from the cookie jar, e.g. `cookieJar.loadForRequest(options.uri)`.
  Future<String> loadCookies(
    RequestOptions options,
    Future<String> Function() loader,
  ) => _mutex.protect(() async {
    options.extra.putIfAbsent(_REQUEST_EPOCH, () => _epoch);
    return loader();
  });

  /// Returns the epoch of the request [options], or null if not set.
  int? requestEpoch(RequestOptions options) =>
      options.extra[_REQUEST_EPOCH] as int?;

  bool hasAdvancedSince(int? epoch) => epoch != null && epoch < _epoch;

  /// Begins a new transaction for cookie changes.
  /// It copies the current [_cookieJar] and returns a [TransactionalCookieJar] that can be used to make changes in isolation.
  Future<TransactionalCookieJar> beginTransaction() =>
      _mutex.protect(() async => TransactionalCookieJar.from(_cookieJar));

  /// Commits the changes made in the [transaction] to the main [_cookieJar].
  ///
  /// This method should be called after a successful login.
  Future<void> commit(TransactionalCookieJar transaction) =>
      _mutex.protect(() => _commitTransactionWhileLocked(transaction));

  Future<void> _commitTransactionWhileLocked(
      TransactionalCookieJar transaction) async {
    final int nextEpoch = _epoch + 1;
    for (final key in transaction.touchedKeys) {
      await _cookieJar.replaceCookie(key, transaction.cookieForKey(key));
      _lastLoginChangeEpoch[key] = nextEpoch;
    }
    _epoch = nextEpoch;
  }

  /// Atomically replaces same-named cookies with [cookies] for the given [uri].
  ///
  /// It starts a temporary transaction and replays the changes in [cookies] to the main [_cookieJar].
  Future<void> importCookies(List<Cookie> cookies, Uri uri) =>
      _mutex.protect(() async {
        if (cookies.isEmpty) return;
        final transaction = TransactionalCookieJar.from(_cookieJar);

        // Remove previous cookies with the same names,
        // so that the identically named cookies with different domain
        // (e.g. `session_id` with *.fudan.edu.cn and id.fudan.edu.cn)
        // do not conflict with each other and cause false request failures.
        for (final name in cookies.map((cookie) => cookie.name).toSet()) {
          transaction.deleteCookiesByName(name);
        }

        await transaction.saveFromResponse(uri, cookies);
        await _commitTransactionWhileLocked(transaction);
      });

  /// Saves the [cookies] from the response to the cookie jar, but only if they have not been changed since the request [options] was made.
  /// For example, if:
  /// 1. A normal request A is made (epoch 0)
  /// 2. A login request B is made (epoch 0)
  /// 3. B commits and increments the epoch to 1
  /// 4. A completes and tries to save cookies. Then with this method, any cookie that was changed by B will not be updated again.
  Future<void> _saveResponseCookies(
    RequestOptions options,
    List<Uri> uris,
    List<Cookie> cookies,
  ) => _mutex.protect(() async {
    final int requestEpoch = options.extra[_REQUEST_EPOCH] as int? ?? _epoch;
    for (final uri in uris) {
      final acceptedCookies = cookies
          .where((cookie) {
            final key = _cookieJar.cookieStorageKey(uri, cookie);
            // We only save cookies that have not been touched by a more recent login transaction.
            return (_lastLoginChangeEpoch[key] ?? -1) <= requestEpoch;
          })
          .toList(growable: false);
      if (acceptedCookies.isNotEmpty) {
        await _cookieJar.saveFromResponse(uri, acceptedCookies);
      }
    }
  });

  Future<void> clear() => _mutex.protect(() async {
    await _cookieJar.deleteAll();
    _lastLoginChangeEpoch.clear();
    _epoch = 0;
  });
}

/// A more tolerant CookieManager that can handle some malformed `Set-Cookie`
/// headers.
///
/// For example, some servers (e.g. Fudan PE) may return invalid characters in cookie values,
/// which will cause the default [CookieManager] to throw an exception when validating.
/// This class with [TolerantCookie] can handle such cases more tolerantly.
class TolerantCookieManager extends CookieManager {
  static final _setCookieReg = RegExp('(?<=)(,)(?=[^;]+?=)');

  final SessionCookieCoordinator? _sessionCookies;

  TolerantCookieManager(
    super.cookieJar, {
    SessionCookieCoordinator? sessionCookies,
  }) : _sessionCookies = sessionCookies;

  @override
  Future<String> loadCookies(RequestOptions options) {
    final coordinator = _sessionCookies;
    return coordinator == null
        ? super.loadCookies(options)
        : coordinator.loadCookies(options, () => super.loadCookies(options));
  }

  /// Copied from [CookieManager.saveCookies].
  @override
  Future<void> saveCookies(Response<dynamic> response) async {
    final setCookies = response.headers[HttpHeaders.setCookieHeader];
    if (setCookies == null || setCookies.isEmpty) {
      return;
    }

    final List<Cookie> cookies = setCookies
        .map((str) => str.split(_setCookieReg))
        .expand((cookie) => cookie)
        .where((cookie) => cookie.isNotEmpty)
        .map((str) => TolerantCookie.fromSetCookieValue(str))
        .toList();
    // Saving cookies for the original site.
    // Spec: https://www.rfc-editor.org/rfc/rfc7231#section-7.1.2.
    final originalUri = response.requestOptions.uri;
    final realUri = originalUri.resolveUri(response.realUri);
    final uris = <Uri>[realUri];

    // Handle `Set-Cookie` when `followRedirects` is false
    // and the response returns a redirect status code.
    final statusCode = response.statusCode ?? 0;
    // 300 indicates the URL has multiple choices, so here we use list literal.
    final locations = response.headers[HttpHeaders.locationHeader] ?? [];
    // We don't want to explicitly consider recursive redirections
    // cookie handling here, because when `followRedirects` is set to false,
    // users will be available to handle cookies themselves.
    final redirected = statusCode >= 300 && statusCode < 400;
    if (redirected && locations.isNotEmpty) {
      final originalUri = response.realUri;
      // Resolves the location based on the current Uri.
      uris.addAll(locations.map(originalUri.resolve));
    }

    final coordinator = _sessionCookies;
    if (coordinator != null) {
      await coordinator._saveResponseCookies(
          response.requestOptions, uris, cookies);
    } else {
      await cookieJar.saveFromResponse(realUri, cookies);
      // Here: uris.skip(1) == locations.map(originalUri.resolve).
      await Future.wait(
        uris.skip(1).map((uri) => cookieJar.saveFromResponse(uri, cookies)),
      );
    }
  }
}

/// Copied from [_Cookie].
class TolerantCookie implements Cookie {
  String _name;
  String _value;
  @override
  DateTime? expires;
  @override
  int? maxAge;
  @override
  String? domain;
  String? _path;
  @override
  bool httpOnly = false;
  @override
  bool secure = false;
  @override
  SameSite? sameSite;

  TolerantCookie(String name, String value)
      : _name = _validateName(name),
        _value = _validateValue(value),
        httpOnly = true;

  @override
  String get name => _name;

  @override
  String get value => _value;

  @override
  String? get path => _path;

  @override
  set path(String? newPath) {
    _validatePath(newPath);
    _path = newPath;
  }

  @override
  set name(String newName) {
    _validateName(newName);
    _name = newName;
  }

  @override
  set value(String newValue) {
    _validateValue(newValue);
    _value = newValue;
  }

  TolerantCookie.fromSetCookieValue(String value)
      : _name = "",
        _value = "" {
    // Parse the 'set-cookie' header value.
    _parseSetCookieValue(value);
  }

  /// Parse a cookie date string.
  ///
  /// Copied from [HttpDate._parseCookieDate].
  static DateTime _parseCookieDate(String date) {
    const List<String> monthsLowerCase = [
      "jan",
      "feb",
      "mar",
      "apr",
      "may",
      "jun",
      "jul",
      "aug",
      "sep",
      "oct",
      "nov",
      "dec",
    ];

    int position = 0;

    Never error() {
      throw HttpException("Invalid cookie date $date");
    }

    bool isEnd() => position == date.length;

    bool isDelimiter(String s) {
      int char = s.codeUnitAt(0);
      if (char == 0x09) return true;
      if (char >= 0x20 && char <= 0x2F) return true;
      if (char >= 0x3B && char <= 0x40) return true;
      if (char >= 0x5B && char <= 0x60) return true;
      if (char >= 0x7B && char <= 0x7E) return true;
      return false;
    }

    bool isNonDelimiter(String s) {
      int char = s.codeUnitAt(0);
      if (char >= 0x00 && char <= 0x08) return true;
      if (char >= 0x0A && char <= 0x1F) return true;
      if (char >= 0x30 && char <= 0x39) return true; // Digit
      if (char == 0x3A) return true; // ':'
      if (char >= 0x41 && char <= 0x5A) return true; // Alpha
      if (char >= 0x61 && char <= 0x7A) return true; // Alpha
      if (char >= 0x7F && char <= 0xFF) return true; // Alpha
      return false;
    }

    bool isDigit(String s) {
      int char = s.codeUnitAt(0);
      if (char > 0x2F && char < 0x3A) return true;
      return false;
    }

    int getMonth(String month) {
      if (month.length < 3) return -1;
      return monthsLowerCase.indexOf(month.substring(0, 3));
    }

    int toInt(String s) {
      int index = 0;
      for (; index < s.length && isDigit(s[index]); index++) {}
      return int.parse(s.substring(0, index));
    }

    var tokens = <String>[];
    while (!isEnd()) {
      while (!isEnd() && isDelimiter(date[position])) {
        position++;
      }
      int start = position;
      while (!isEnd() && isNonDelimiter(date[position])) {
        position++;
      }
      tokens.add(date.substring(start, position).toLowerCase());
      while (!isEnd() && isDelimiter(date[position])) {
        position++;
      }
    }

    String? timeStr;
    String? dayOfMonthStr;
    String? monthStr;
    String? yearStr;

    for (var token in tokens) {
      if (token.isEmpty) continue;
      if (timeStr == null &&
          token.length >= 5 &&
          isDigit(token[0]) &&
          (token[1] == ":" || (isDigit(token[1]) && token[2] == ":"))) {
        timeStr = token;
      } else if (dayOfMonthStr == null && isDigit(token[0])) {
        dayOfMonthStr = token;
      } else if (monthStr == null && getMonth(token) >= 0) {
        monthStr = token;
      } else if (yearStr == null &&
          token.length >= 2 &&
          isDigit(token[0]) &&
          isDigit(token[1])) {
        yearStr = token;
      }
    }

    if (timeStr == null ||
        dayOfMonthStr == null ||
        monthStr == null ||
        yearStr == null) {
      error();
    }

    int year = toInt(yearStr);
    if (year >= 70 && year <= 99) {
      year += 1900;
    } else if (year >= 0 && year <= 69) {
      year += 2000;
    }
    if (year < 1601) error();

    int dayOfMonth = toInt(dayOfMonthStr);
    if (dayOfMonth < 1 || dayOfMonth > 31) error();

    int month = getMonth(monthStr) + 1;

    var timeList = timeStr.split(":");
    if (timeList.length != 3) error();
    int hour = toInt(timeList[0]);
    int minute = toInt(timeList[1]);
    int second = toInt(timeList[2]);
    if (hour > 23) error();
    if (minute > 59) error();
    if (second > 59) error();

    return DateTime.utc(year, month, dayOfMonth, hour, minute, second, 0);
  }

  // Parse a 'set-cookie' header value according to the rules in RFC 6265.
  void _parseSetCookieValue(String s) {
    int index = 0;

    bool done() => index == s.length;

    String parseName() {
      int start = index;
      while (!done()) {
        if (s[index] == "=") break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    String parseValue() {
      int start = index;
      while (!done()) {
        if (s[index] == ";") break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    void parseAttributes() {
      String parseAttributeName() {
        int start = index;
        while (!done()) {
          if (s[index] == "=" || s[index] == ";") break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      String parseAttributeValue() {
        int start = index;
        while (!done()) {
          if (s[index] == ";") break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      while (!done()) {
        String name = parseAttributeName();
        String value = "";
        if (!done() && s[index] == "=") {
          index++; // Skip the = character.
          value = parseAttributeValue();
        }
        if (name == "expires") {
          expires = _parseCookieDate(value);
        } else if (name == "max-age") {
          maxAge = int.parse(value);
        } else if (name == "domain") {
          domain = value;
        } else if (name == "path") {
          path = value;
        } else if (name == "httponly") {
          httpOnly = true;
        } else if (name == "secure") {
          secure = true;
        } else if (name == "samesite") {
          sameSite = switch (value) {
            "lax" => SameSite.lax,
            "none" => SameSite.none,
            "strict" => SameSite.strict,
            _ => throw HttpException(
                'SameSite value should be one of Lax, Strict or None.',
              ),
          };
        }
        if (!done()) index++; // Skip the ; character
      }
    }

    _name = _validateName(parseName());
    if (done() || _name.isEmpty) {
      throw HttpException("Failed to parse header value [$s]");
    }
    index++; // Skip the = character.
    _value = _validateValue(parseValue());
    if (done()) return;
    index++; // Skip the ; character.
    parseAttributes();
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb
      ..write(_name)
      ..write("=")
      ..write(_value);
    var expires = this.expires;
    if (expires != null) {
      sb
        ..write("; Expires=")
        ..write(HttpDate.format(expires));
    }
    if (maxAge != null) {
      sb
        ..write("; Max-Age=")
        ..write(maxAge);
    }
    if (domain != null) {
      sb
        ..write("; Domain=")
        ..write(domain);
    }
    if (path != null) {
      sb
        ..write("; Path=")
        ..write(path);
    }
    if (secure) sb.write("; Secure");
    if (httpOnly) sb.write("; HttpOnly");
    if (sameSite != null) sb.write("; $sameSite");

    return sb.toString();
  }

  static String _validateName(String newName) {
    const separators = [
      "(",
      ")",
      "<",
      ">",
      "@",
      ",",
      ";",
      ":",
      "\\",
      '"',
      "/",
      "[",
      "]",
      "?",
      "=",
      "{",
      "}",
    ];
    for (int i = 0; i < newName.length; i++) {
      int codeUnit = newName.codeUnitAt(i);
      if (codeUnit <= 32 ||
          codeUnit >= 127 ||
          separators.contains(newName[i])) {
        throw FormatException(
          "Invalid character in cookie name, code unit: '$codeUnit'",
          newName,
          i,
        );
      }
    }
    return newName;
  }

  static String _validateValue(String newValue) {
    // Per RFC 6265, consider surrounding "" as part of the value, but otherwise
    // double quotes are not allowed.
    int start = 0;
    int end = newValue.length;
    if (2 <= newValue.length &&
        newValue.codeUnits[start] == 0x22 &&
        newValue.codeUnits[end - 1] == 0x22) {
      start++;
      end--;
    }

    for (int i = start; i < end; i++) {
      int codeUnit = newValue.codeUnits[i];
      if (!(codeUnit == 0x21 ||
          (codeUnit >= 0x23 && codeUnit <= 0x2B) ||
          (codeUnit >= 0x2D && codeUnit <= 0x3A) ||
          (codeUnit >= 0x3C && codeUnit <= 0x5B) ||
          (codeUnit >= 0x5D && codeUnit <= 0x7E))) {
        debugPrint("Invalid code unit in cookie value: $codeUnit. Reset to empty string.");
        // If an invalid character is found, reset the value to an empty string.
        return "";
        // Be tolerant and do not throw an exception here!
        // throw FormatException(
        //   "Invalid character in cookie value, code unit: '$codeUnit'",
        //   newValue,
        //   i,
        // );
      }
    }
    return newValue;
  }

  static void _validatePath(String? path) {
    if (path == null) return;
    for (int i = 0; i < path.length; i++) {
      int codeUnit = path.codeUnitAt(i);
      // According to RFC 6265, semicolon and controls should not occur in the
      // path.
      // path-value = <any CHAR except CTLs or ";">
      // CTLs = %x00-1F / %x7F
      if (codeUnit < 0x20 || codeUnit >= 0x7f || codeUnit == 0x3b /*;*/) {
        throw FormatException(
          "Invalid character in cookie path, code unit: '$codeUnit'",
        );
      }
    }
  }
}
