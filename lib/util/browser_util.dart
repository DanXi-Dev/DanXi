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

import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BrowserUtil {
  static InAppBrowserClassSettings getOptions(BuildContext context) =>
      InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(
            toolbarTopBackgroundColor: Theme.of(context).cardTheme.color,
            hideTitleBar: true,
            hideToolbarBottom: true,
          ),
          webViewSettings: InAppWebViewSettings(
            sharedCookiesEnabled: true,
            javaScriptEnabled: true,
            useOnDownloadStart: true,
            incognito: true,
          ));

  /// Open a URL in the browser.
  ///
  /// Note: any external links in the app should be opened using this method.
  ///
  /// If we are on mobile platforms and we need overall control over the browser
  /// (i.e. [cookieJar] is not null or [needAutoLogin] is true),
  /// we will use [InAppBrowser] to open the URL; otherwise, the url is processed
  /// by the system, using something like an external browser app.
  static Future<void> openUrl(String url, BuildContext? context,
      [IndependentCookieJar? cookieJar, bool needAutoLogin = false]) async {
    // Sanitize URL
    url = Uri.encodeFull(Uri.decodeFull(url));

    if ((cookieJar == null && needAutoLogin == false) || PlatformX.isDesktop) {
      bool launched =
          await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw "This URL cannot be launched.";
      }
      return;
    }

    if (cookieJar != null) {
      WebUri uri = WebUri(url);
      CookieManager.instance().deleteCookies(url: uri);
      if (uri.host.startsWith(Constant.UIS_HOST)) {
        cookieJar.hostCookies.forEach((host, value) {
          value.forEach((path, value) {
            value.forEach((name, cookie) {
              CookieManager.instance().setCookie(
                  url: uri,
                  name: name,
                  path: cookie.cookie.path!,
                  value: cookie.cookie.value,
                  domain: cookie.cookie.domain);
            });
          });
        });
        cookieJar.domainCookies.forEach((host, value) {
          value.forEach((path, value) {
            value.forEach((name, cookie) {
              CookieManager.instance().setCookie(
                  url: uri,
                  name: name,
                  path: cookie.cookie.path!,
                  value: cookie.cookie.value,
                  domain: cookie.cookie.domain);
            });
          });
        });
      } else {
        var cookies = await cookieJar.loadForRequest(uri);
        for (var cookie in cookies) {
          CookieManager.instance().setCookie(
              url: uri,
              name: cookie.name,
              path: cookie.path!,
              value: cookie.value,
              domain: cookie.domain);
        }
      }
    }
    CustomInAppBrowser().openUrlRequest(
        urlRequest: URLRequest(url: WebUri(url)),
        settings: getOptions(context!));
  }

  /// Open an [InAppBrowser] for manual enhanced authentication (2FA).
  ///
  /// The browser navigates to [url] (typically the service URL that triggers
  /// a redirect to id.fudan.edu.cn). Credentials are auto-injected when the
  /// login page loads. Once the browser lands on [targetHost], cookies are
  /// extracted and imported into [FudanSession], and the returned [Future]
  /// completes.
  static Future<void> openForAuthentication(
      String url, String targetHost, BuildContext context) {
    final completer = Completer<void>();

    final browser = AuthenticationInAppBrowser(
      targetHost: targetHost,
      completer: completer,
    );
    browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(url)),
      settings: InAppBrowserClassSettings(
        browserSettings: InAppBrowserSettings(
          toolbarTopBackgroundColor: Theme.of(context).cardTheme.color,
          hideTitleBar: true,
          hideToolbarBottom: true,
        ),
        webViewSettings: InAppWebViewSettings(
          sharedCookiesEnabled: true,
          javaScriptEnabled: true,
          // Must NOT be incognito so that CookieManager can read cookies.
          incognito: false,
        ),
      ),
    );

    return completer.future;
  }
}

class CustomInAppBrowser extends InAppBrowser {
  @override
  Future<GeolocationPermissionShowPromptResponse>
      androidOnGeolocationPermissionsShowPrompt(String origin) {
    if (origin == '''https://zlapp.fudan.edu.cn/''') {
      return Future.value(GeolocationPermissionShowPromptResponse(
          origin: origin, allow: true, retain: true));
    }
    // Only give geolocation permission on PAFD site
    return Future.value(GeolocationPermissionShowPromptResponse(
        origin: origin, allow: false, retain: false));
  }

  // Prompts the user with a In-App Review UI, when certain conditions are met.
  Future<void> requestStoreReviewWhenAppropriate() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      // Ensure requestReview is called only after the user used the app for a while
      // And ensure that the API is not called too frequently.
      // TODO: Any better ways to implement this?
      final XSharedPreferences preferences =
          await XSharedPreferences.getInstance();
      if (preferences.containsKey(SettingsProvider.KEY_FORUM_FOLDBEHAVIOR) ||
          preferences.containsKey(SettingsProvider.KEY_FORUM_SORTORDER)) {
        if (Random().nextDouble() > 0.997) inAppReview.requestReview();
      }
    }
  }

  @override
  void onDownloadStart(Uri url) {
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String uisLoginJavaScript(PersonInfo info) =>
      r'''try{
            document.getElementById('username').value = String.raw`''' +
      info.id! +
      r'''`;
            document.getElementById('password').value = String.raw`''' +
      info.password! +
      r'''`;
            document.forms[0].submit();
        }
        catch (e) {
            try{
                document.getElementById('mobileUsername').value = String.raw`''' +
      info.id! +
      r'''`;
                document.getElementById('mobilePassword').value = String.raw`''' +
      info.password! +
      r'''`;
                document.forms[0].submit();
            }
            catch (e) {
                console.log("Danta: Failed to auto login UIS", e);
            }
        }''';

  String idLoginJavaScript(PersonInfo info) =>
      r'''try{
            const usernameInput = document.getElementById('login-username');
            usernameInput.value = String.raw`''' +
      info.id! +
      r'''`;
            usernameInput.dispatchEvent(new Event('input'));
            
            const passwordInput = document.getElementById('login-password');
            passwordInput.value = String.raw`''' +
      info.password! +
      r'''`;
            passwordInput.dispatchEvent(new Event('input'));

            document.querySelector('.el-button.content_submit').click();
        }
        catch (e) {
            console.log("Danta: Failed to auto login UIS", e);
        }''';

  @override
  Future<dynamic> onLoadStop(url) async {
    if (url
            ?.toString()
            .startsWith("https://uis.fudan.edu.cn/authserver/login") ==
        true) {
      Future.delayed(const Duration(milliseconds: 1000)).then((_) =>
          webViewController?.evaluateJavascript(
              source: uisLoginJavaScript(StateProvider.personInfo.value!)));
    } else if (url?.toString().startsWith("https://id.fudan.edu.cn/") == true) {
      Future.delayed(const Duration(milliseconds: 1000)).then((_) =>
          webViewController?.evaluateJavascript(
              source: idLoginJavaScript(StateProvider.personInfo.value!)));
    }
  }

  @override
  void onExit() {
    // Request App Store/Google Play review after user closes the broswer.
    requestStoreReviewWhenAppropriate();
  }
}

/// An [InAppBrowser] that handles enhanced authentication (2FA) for Fudan
/// services. It auto-fills credentials on login pages and extracts cookies
/// once the user reaches the target service.
class AuthenticationInAppBrowser extends InAppBrowser {
  final String targetHost;
  final Completer<void> completer;

  AuthenticationInAppBrowser({
    required this.targetHost,
    required this.completer,
  });

  String _uisLoginJavaScript(PersonInfo info) =>
      r'''try{
            document.getElementById('username').value = String.raw`''' +
      info.id! +
      r'''`;
            document.getElementById('password').value = String.raw`''' +
      info.password! +
      r'''`;
            document.forms[0].submit();
        }
        catch (e) {
            try{
                document.getElementById('mobileUsername').value = String.raw`''' +
      info.id! +
      r'''`;
                document.getElementById('mobilePassword').value = String.raw`''' +
      info.password! +
      r'''`;
                document.forms[0].submit();
            }
            catch (e) {
                console.log("Danta: Failed to auto login UIS", e);
            }
        }''';

  String _idLoginJavaScript(PersonInfo info) =>
      r'''try{
            const usernameInput = document.getElementById('login-username');
            usernameInput.value = String.raw`''' +
      info.id! +
      r'''`;
            usernameInput.dispatchEvent(new Event('input'));
            
            const passwordInput = document.getElementById('login-password');
            passwordInput.value = String.raw`''' +
      info.password! +
      r'''`;
            passwordInput.dispatchEvent(new Event('input'));

            document.querySelector('.el-button.content_submit').click();
        }
        catch (e) {
            console.log("Danta: Failed to auto login", e);
        }''';

  @override
  Future<void> onLoadStop(WebUri? url) async {
    final info = StateProvider.personInfo.value;
    if (info == null) return;

    final urlStr = url?.toString() ?? '';

    if (urlStr.startsWith('https://uis.fudan.edu.cn/authserver/login')) {
      Future.delayed(const Duration(milliseconds: 1000)).then((_) =>
          webViewController?.evaluateJavascript(
              source: _uisLoginJavaScript(info)));
    } else if (urlStr.startsWith('https://id.fudan.edu.cn/')) {
      Future.delayed(const Duration(milliseconds: 1000)).then((_) =>
          webViewController?.evaluateJavascript(
              source: _idLoginJavaScript(info)));
    } else if (url?.host == targetHost) {
      // The user has completed 2FA and reached the target service.
      // Extract cookies and import them into FudanSession.
      await _extractAndImportCookies(url!);
      FudanSession.complete2FA();
      if (!completer.isCompleted) {
        completer.complete();
      }
      // flutter_inappwebview_linux 0.1.0-beta.1 has a bug where
      // InAppBrowser.close() returns NOT_IMPLEMENTED because
      // setInAppBrowserDelegate() is never called in setupWebView().
      // On Linux, skip close() and let the user close the window manually.
      if (!PlatformX.isLinux) {
        close();
      }
    }
  }

  static io.Cookie _toIoCookie(Cookie c) => io.Cookie(c.name, '${c.value}')
    ..domain = c.domain
    ..path = c.path ?? '/'
    ..secure = c.isSecure ?? false
    ..httpOnly = c.isHttpOnly ?? false
    ..expires = c.expiresDate != null
        ? DateTime.fromMillisecondsSinceEpoch(c.expiresDate!)
        : null;

  Future<void> _extractAndImportCookies(WebUri url) async {
    final cookieManager = CookieManager.instance();

    // Import cookies from the target service host.
    final targetCookies = await cookieManager.getCookies(url: url);
    final targetUri = Uri.parse(url.toString());
    await FudanSession.importCookies(
        targetCookies.map(_toIoCookie).toList(), targetUri);

    // Also import cookies from id.fudan.edu.cn to maintain the session.
    final idUrl = WebUri('https://${FudanAuthenticationAPIV2.idHost}/');
    final idCookies = await cookieManager.getCookies(url: idUrl);
    final idUri = Uri.parse(idUrl.toString());
    await FudanSession.importCookies(
        idCookies.map(_toIoCookie).toList(), idUri);
  }

  @override
  void onExit() {
    if (!completer.isCompleted) {
      final error = Exception('User closed the authentication browser');
      FudanSession.fail2FA(error, StackTrace.current);
      completer.completeError(error);
    }
  }
}
