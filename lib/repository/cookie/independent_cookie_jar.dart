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

import 'dart:io';

// ignore: implementation_imports
import 'package:cookie_jar/src/cookie_jar.dart';
// ignore: implementation_imports
import 'package:cookie_jar/src/serializable_cookie.dart';

typedef CookieStorageKey = ({
  bool domainCookie,
  String domain,
  String path,
  String name,
});

/// A copy of [DefaultCookieJar], but with an independent cookie storage.
class IndependentCookieJar implements CookieJar {
  /// A array to save cookies.
  ///
  /// [domains[0]] save the cookies with "domain" attribute.
  /// These cookie usually need to be shared among multiple domains.
  ///
  /// [domains[1]] save the cookies without "domain" attribute.
  /// These cookies are private for each host name.
  ///
  final List<
          Map<
              String?, //domain or host
              Map<
                  String, //path
                  Map<
                      String, //cookie name
                      SerializableCookie //cookie
                      >>>> _cookies =
      <Map<String?, Map<String, Map<String, SerializableCookie>>>>[
    <String?, Map<String, Map<String, SerializableCookie>>>{},
    <String?, Map<String, Map<String, SerializableCookie>>>{}
  ];

  IndependentCookieJar({this.ignoreExpires = false});

  Map<String?, Map<String, Map<String, SerializableCookie>>>
      get domainCookies => _cookies[0];

  Map<String?, Map<String, Map<String, SerializableCookie>>> get hostCookies =>
      _cookies[1];

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    final list = <Cookie>[];
    final urlPath = uri.path.isEmpty ? '/' : uri.path;
    // Load cookies without "domain" attribute, include port.
    final hostname = uri.host;
    for (final domain in hostCookies.keys) {
      if (hostname == domain) {
        final cookies =
            hostCookies[domain]!.cast<String, Map<String, dynamic>>();
        var keys = cookies.keys.toList()
          ..sort((a, b) => b.length.compareTo(a.length));
        for (final path in keys) {
          if (urlPath.toLowerCase().contains(path)) {
            final values = cookies[path]!;
            for (final key in values.keys) {
              final SerializableCookie cookie = values[key];
              if (_check(uri.scheme, cookie)) {
                if (list.indexWhere((e) => e.name == cookie.cookie.name) ==
                    -1) {
                  _onCookieLoaded((
                    domainCookie: false,
                    domain: hostname,
                    path: path,
                    name: key,
                  ));
                  list.add(cookie.cookie);
                }
              }
            }
          }
        }
      }
    }
    // Load cookies with "domain" attribute, Ignore port.
    domainCookies.forEach(
        (String? domain, Map<String, Map<String, SerializableCookie>> cookies) {
      if (uri.host.contains(domain!)) {
        cookies.forEach((String path, Map<String, SerializableCookie> values) {
          if (urlPath.toLowerCase().contains(path)) {
            values.forEach((String key, SerializableCookie v) {
              if (_check(uri.scheme, v)) {
                _onCookieLoaded((
                  domainCookie: true,
                  domain: domain,
                  path: path,
                  name: key,
                ));
                list.add(v.cookie);
              }
            });
          }
        });
      }
    });
    return list;
  }

  // A helper callback to let child classes do something when the cookie is read.
  void _onCookieLoaded(CookieStorageKey key) {}

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    for (final cookie in cookies) {
      await replaceCookie(cookieStorageKey(uri, cookie), cookie);
    }
  }

  CookieStorageKey cookieStorageKey(Uri uri, Cookie cookie) {
    String? domain = cookie.domain;
    final bool domainCookie = domain != null;
    // Save cookies with "domain" attribute
    if (domain != null) {
      if (domain.startsWith('.')) {
        domain = domain.substring(1);
      }
    } else {
      // Save cookies without "domain" attribute
      domain = uri.host;
    }
    return (
      domainCookie: domainCookie,
      domain: domain,
      path:
          cookie.path ??
          (domainCookie ? '/' : (uri.path.isEmpty ? '/' : uri.path)),
      name: cookie.name,
    );
  }

  Cookie? cookieForKey(CookieStorageKey key) {
    final store = key.domainCookie ? domainCookies : hostCookies;
    return store[key.domain]?[key.path]?[key.name]?.cookie;
  }

  Future<void> replaceCookie(CookieStorageKey key, Cookie? cookie) async {
    final index = key.domainCookie ? 0 : 1;
    final store = _cookies[index];
    if (cookie == null) {
      final pathMap = store[key.domain];
      final cookieMap = pathMap?[key.path];
      cookieMap?.remove(key.name);
      if (cookieMap?.isEmpty ?? false) pathMap?.remove(key.path);
      if (pathMap?.isEmpty ?? false) store.remove(key.domain);
      return;
    }

    var mapDomain = store[key.domain] ?? <String, Map<String, dynamic>>{};
    mapDomain = mapDomain.cast<String, Map<String, dynamic>>();

    final map = mapDomain[key.path] ?? <String, dynamic>{};
    map[key.name] = SerializableCookie(cookie);
    if (_isExpired(map[key.name])) {
      map.remove(key.name);
    }
    mapDomain[key.path] = map.cast<String, SerializableCookie>();
    store[key.domain] = mapDomain
        .cast<String, Map<String, SerializableCookie>>();
  }

  /// Delete cookies for specified [uri].
  /// This API will delete all cookies for the `uri.host`, it will ignored the `uri.path`.
  ///
  /// [withDomainSharedCookie] `true` will delete the domain-shared cookies.
  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    final host = uri.host;
    hostCookies.remove(host);
    if (withDomainSharedCookie) {
      domainCookies.removeWhere(
          (String? domain, Map<String, Map<String, SerializableCookie>> v) =>
              uri.host.contains(domain!));
    }
  }

  /// Delete all cookies in RAM
  @override
  Future<void> deleteAll() async {
    domainCookies.clear();
    hostCookies.clear();
  }

  bool _isExpired(SerializableCookie? cookie) {
    return ignoreExpires ? false : cookie!.isExpired();
  }

  bool _check(String scheme, SerializableCookie cookie) {
    return cookie.cookie.secure && scheme == 'https' || !_isExpired(cookie);
  }

  factory IndependentCookieJar.createFrom(IndependentCookieJar otherJar) =>
      IndependentCookieJar()..cloneFrom(otherJar);

  /// Clone cookies from [otherJar] to this jar.
  ///
  /// The original cookies in this jar will be cleared before cloning.
  void cloneFrom(IndependentCookieJar otherJar) {
    _deepClone(otherJar.domainCookies, domainCookies);
    _deepClone(otherJar.hostCookies, hostCookies);
  }

  static void _deepClone(
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

  @override
  final bool ignoreExpires;

  Set<CookieStorageKey> deleteCookiesByName(String name) {
    final deletedKeys = <CookieStorageKey>{};
    for (final domain in hostCookies.keys) {
      final cookies = hostCookies[domain]!;
      for (final path in cookies.keys) {
        final values = cookies[path]!;
        if (values.remove(name) != null) {
          deletedKeys.add((
            domainCookie: false,
            domain: domain!,
            path: path,
            name: name,
          ));
        }
      }
    }
    for (final domain in domainCookies.keys) {
      final cookies = domainCookies[domain]!;
      for (final path in cookies.keys) {
        final values = cookies[path]!;
        if (values.remove(name) != null) {
          deletedKeys.add((
            domainCookie: true,
            domain: domain!,
            path: path,
            name: name,
          ));
        }
      }
    }
    return deletedKeys;
  }
}

/// An isolated cookie snapshot that records the keys used during a login.
class TransactionalCookieJar extends IndependentCookieJar {
  final Set<CookieStorageKey> touchedKeys = <CookieStorageKey>{};

  TransactionalCookieJar.from(IndependentCookieJar source)
    : super(ignoreExpires: source.ignoreExpires) {
    cloneFrom(source);
  }

  @override
  void _onCookieLoaded(CookieStorageKey key) => touchedKeys.add(key);

  @override
  Future<void> replaceCookie(CookieStorageKey key, Cookie? cookie) {
    touchedKeys.add(key);
    return super.replaceCookie(key, cookie);
  }

  @override
  Set<CookieStorageKey> deleteCookiesByName(String name) {
    final deletedKeys = super.deleteCookiesByName(name);
    touchedKeys.addAll(deletedKeys);
    return deletedKeys;
  }
}
