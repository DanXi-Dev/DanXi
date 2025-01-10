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

/// According to the implementation of [CookieManager], having multiple [CookieManager]s on the same [Dio] doesn't work as expected (that is to say only the last will take effect).
/// This class is created to enable loading multiple [CookieJar]s on the same [Dio].
/// The cookies will be merged on request and broadcasted to every [CookieJar] on receive.
///
/// If the same cookie entries in different [CookieJar]s conflict with each other, the last [CookieJar] in list will take effect.
/// If you want some cookie jars to remain unchanged, see [ReadonlyCookieJar].
class ParallelCookieJars implements CookieJar {
  ParallelCookieJars(this.cookieJars);

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    for (var cookieJar in cookieJars) {
      await cookieJar.saveFromResponse(uri, cookies);
    }
  }

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    Map<String, Cookie> allCookies = {};

    // Entries from later cookie jars override earlier ones in the map
    for (var cookieJar in cookieJars) {
      final cookieEntries = await cookieJar.loadForRequest(uri);
      // May override older entries
      allCookies.addEntries(cookieEntries.map((e) => MapEntry(e.name, e)));
    }

    return allCookies.values.toList();
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    for (var cookieJar in cookieJars) {
      await cookieJar.delete(uri, withDomainSharedCookie);
    }
  }

  @override
  Future<void> deleteAll() async {
    for (var cookieJar in cookieJars) {
      await cookieJar.deleteAll();
    }
  }

  List<CookieJar> cookieJars = [];

  @override
  // Inherit property from the last [CookieJar]
  bool get ignoreExpires => cookieJars.last.ignoreExpires;
}
