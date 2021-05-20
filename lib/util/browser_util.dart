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

import 'package:dan_xi/repository/inpersistent_cookie_manager.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowserUtil {
  static InAppBrowserClassOptions options = InAppBrowserClassOptions(
      crossPlatform: InAppBrowserOptions(
          hideUrlBar: PlatformX
              .isAndroid), // TODO: No context here so can't use isMaterial
      ios: IOSInAppBrowserOptions(
        presentationStyle: IOSUIModalPresentationStyle.POPOVER,
      ),
      inAppWebViewGroupOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
      ));

  static openUrl(String url, NonpersistentCookieJar cookieJar) {
    if (PlatformX.isDesktop) {
      launch(url);
      return;
    }
    cookieJar.hostCookies.forEach((host, value) {
      value.forEach((path, value) {
        value.forEach((name, cookie) {
          CookieManager.instance().setCookie(
              url: Uri.parse(url),
              name: name,
              value: cookie.cookie.value,
              domain: cookie.cookie.domain,
              isSecure: cookie.cookie.secure);
        });
      });
    });
    cookieJar.domainCookies.forEach((host, value) {
      value.forEach((path, value) {
        value.forEach((name, cookie) {
          CookieManager.instance().setCookie(
              url: Uri.parse(url),
              name: name,
              value: cookie.cookie.value,
              domain: cookie.cookie.domain,
              isSecure: cookie.cookie.secure);
        });
      });
    });
    InAppBrowser().openUrlRequest(
        urlRequest: URLRequest(url: Uri.parse(url)), options: options);
  }
}
