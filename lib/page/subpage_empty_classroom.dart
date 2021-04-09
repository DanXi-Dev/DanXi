/*
 *     Copyright (C) 2021 kavinzhao
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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';

class EmptyClassroomSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  _EmptyClassroomSubpageState createState() => _EmptyClassroomSubpageState();

  EmptyClassroomSubpage({Key key});
}

class _EmptyClassroomSubpageState extends State<EmptyClassroomSubpage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);


    //WebView
    InAppBrowserClassOptions options = InAppBrowserClassOptions(
        crossPlatform: InAppBrowserOptions(hideUrlBar: false),
        inAppWebViewGroupOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(javaScriptEnabled: true)));
    final InAppBrowser browser = new InAppBrowser();

    return RefreshIndicator(
        onRefresh: () async => refreshSelf(),
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              padding: EdgeInsets.all(4),
              children: <Widget>[
                Card(
                  child: ListTile(
                    title: Text(S.of(context).empty_classrooms),
                    leading: PlatformX.isAndroid
                        ? const Icon(Icons.book)
                        : const Icon(SFSymbols.book),
                    subtitle: Text(S.of(context).tap_to_view),
                    onTap: () {
                      browser.openUrlRequest(
                          urlRequest: URLRequest(url: Uri.parse("http://map.fudan.edu.cn/src/paike/index.php")),
                          options: options);
                    },
                  ),
                )
              ],
            )));
  }
}
