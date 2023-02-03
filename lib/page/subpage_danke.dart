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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class DankeSubPage extends PlatformSubpage<DankeSubPage> {
  @override
  DankeSubPageState createState() => DankeSubPageState();

  const DankeSubPage({Key? key}) : super(key: key);

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).danke);
}

class DankeSubPageState extends PlatformSubpageState<DankeSubPage> {
  InAppWebViewController? webViewController;

  @override
  Widget buildPage(BuildContext context) {
    InAppWebViewOptions settings =
        InAppWebViewOptions(userAgent: Constant.version);

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          if (webViewController != null &&
              await webViewController!.canGoBack()) {
            await webViewController!.goBack();
            return false;
          }
          return true;
        },
        child: InAppWebView(
          initialOptions: InAppWebViewGroupOptions(crossPlatform: settings),
          initialUrlRequest: URLRequest(
              url: Uri.https('danke.fduhole.com', '/jump', {
            'access': SettingsProvider.getInstance().fduholeToken?.access,
            'refresh': SettingsProvider.getInstance().fduholeToken?.refresh,
          })),
          onWebViewCreated: (InAppWebViewController controller) {
            webViewController = controller;
          },
        ),
      ),
    );
  }
}
