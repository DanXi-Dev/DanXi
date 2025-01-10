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

// ignore: implementation_imports
import 'package:cookie_jar/cookie_jar.dart';
// ignore: implementation_imports
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';

/// A copy of [DefaultCookieJar], but denies any writing, to avoid being modified or overwritten by mistake.
/// Cookies could only be copied from another cookie jar.
class ReadonlyCookieJar extends DefaultCookieJar {
  // Clear all cookies stored in RAM
  Future<void> clearCookies() async {
    domainCookies.clear();
    hostCookies.clear();
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    // Do nothing
  }

  /// Readonly cookie jar does not allow the [delete] api
  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    // Do nothing
  }

  /// Readonly cookie jar does not allow the [deleteAll] api
  /// If you still want to clear all cookies stored, call [clearCookies] instead.
  @override
  Future<void> deleteAll() async {
    // Do nothing
  }

  /// Clone cookies from [otherJar] to this jar.
  ///
  /// The original cookies in this jar will be cleared before cloning.
  void cloneFrom(IndependentCookieJar otherJar) {
    _deepClone(otherJar.domainCookies, domainCookies);
    _deepClone(otherJar.hostCookies, hostCookies);
  }

  /// Clone cookies from [otherJar] to this jar.
  ///
  /// The original cookies in this jar will be cleared before cloning.
  void cloneFromDefault(DefaultCookieJar otherJar) {
    _deepClone(otherJar.domainCookies, domainCookies);
    _deepClone(otherJar.hostCookies, hostCookies);
  }

  static _deepClone(
      Map<String?, Map<String, Map<String, SerializableCookie>>> from,
      Map<String?, Map<String, Map<String, SerializableCookie>>> to) {
    to.clear();
    from.forEach((host, value) {
      to[host] = {};
      value.forEach((path, value) {
        to[host]![path] = {};
        value.forEach((cookieName, value) {
          to[host]![path]![cookieName] =
              SerializableCookie.fromJson(value.toJson());
        });
      });
    });
  }
}
