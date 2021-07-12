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

import 'dart:math';

import 'package:dan_xi/master_detail/master_detail_utils.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/inpersistent_cookie_manager.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowserUtil {
  // Popover crashes on iPad
  static InAppBrowserClassOptions getOptions(BuildContext context) =>
      isTablet(context)
          ? InAppBrowserClassOptions(
              inAppWebViewGroupOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true, useOnDownloadStart: true),
            ))
          : InAppBrowserClassOptions(
              android: AndroidInAppBrowserOptions(hideTitleBar: true),
              ios: IOSInAppBrowserOptions(
                presentationStyle: IOSUIModalPresentationStyle.POPOVER,
              ),
              inAppWebViewGroupOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                    javaScriptEnabled: true, useOnDownloadStart: true),
              ));

  static openUrl(String url, BuildContext context,
      [NonpersistentCookieJar cookieJar]) {
    // Sanitize URL
    url = Uri.encodeFull(url);

    if (cookieJar == null || PlatformX.isDesktop) {
      launch(url, enableJavaScript: true);
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
    CustomInAppBrowser().openUrlRequest(
        urlRequest: URLRequest(url: Uri.parse(url)),
        options: getOptions(context));
  }
}

class CustomInAppBrowser extends InAppBrowser {
  @override
  Future<GeolocationPermissionShowPromptResponse>
      androidOnGeolocationPermissionsShowPrompt(String origin) {
    if (origin == '''https://zlapp.fudan.edu.cn/''')
      return Future.value(GeolocationPermissionShowPromptResponse(
          origin: origin, allow: true, retain: true));
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
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      if (preferences.containsKey(SettingsProvider.KEY_FDUHOLE_FOLDBEHAVIOR) ||
          preferences.containsKey(SettingsProvider.KEY_FDUHOLE_SORTORDER)) {
        if (Random().nextDouble() > 0.997) inAppReview.requestReview();
      }
    }
  }

  @override
  void onDownloadStart(Uri uri) {
    launch(uri.toString());
  }

  @override
  void onExit() {
    // Request App Store/Google Play review after user closes the broswer.
    requestStoreReviewWhenAppropriate();
  }
}
