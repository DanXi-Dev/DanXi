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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/widget/opentreehole/login_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

const kCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
  UserGroup.FUDAN_POSTGRADUATE_STUDENT,
  UserGroup.FUDAN_STAFF,
  UserGroup.SJTU_STUDENT,
  UserGroup.VISITOR
];

class DankeSubPage extends PlatformSubpage<DankeSubPage> {
  @override
  DankeSubPageState createState() => DankeSubPageState();

  const DankeSubPage({Key? key}) : super(key: key);

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).danke);
}

class DankeSubPageState extends PlatformSubpageState<DankeSubPage> {
  // Future<void> setLoginCookie(String access, String refresh) async {
  //   CookieManager cookieManager = CookieManager.instance();

  //   final expiresDate =
  //       DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch;
  //   final url = Uri.https("https://danke.fduhole.com/");

  //   await cookieManager.setCookie(
  //     url: url,
  //     name: "access",
  //     value: access,
  //     expiresDate: expiresDate,
  //     isSecure: true,
  //   );
  //   await cookieManager.setCookie(
  //     url: url,
  //     name: "refresh",
  //     value: refresh,
  //     expiresDate: expiresDate,
  //     isSecure: true,
  //   );
  // }

  @override
  Widget buildPage(BuildContext context) {
    InAppWebViewOptions settings =
        InAppWebViewOptions(userAgent: Constant.version);

    return SafeArea(
      child: InAppWebView(
        initialOptions: InAppWebViewGroupOptions(crossPlatform: settings),
        initialUrlRequest: URLRequest(
            url: Uri.https('danke.fduhole.com', '/jump', {
          'access': OpenTreeHoleRepository.getInstance().provider.token?.access,
          'refresh':
              OpenTreeHoleRepository.getInstance().provider.token?.refresh
        })),
        // onWebViewCreated: (InAppWebViewController controller) async {
        //   if (OpenTreeHoleRepository.getInstance().provider.isUserInitialized) {
        //     await setLoginCookie(
        //         OpenTreeHoleRepository.getInstance().provider.token!.access!,
        //         OpenTreeHoleRepository.getInstance().provider.token!.refresh!);
        //   }
        // },
      ),
    );
  }
}
