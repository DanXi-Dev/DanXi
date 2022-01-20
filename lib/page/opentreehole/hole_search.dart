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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing the reports for administrators.
class OTSearchPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const OTSearchPage({Key? key, this.arguments}) : super(key: key);

  @override
  _OTSearchPageState createState() => _OTSearchPageState();
}

class _OTSearchPageState extends State<OTSearchPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text(S.of(context).messages),
        ),
        trailingActions: const [],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Hero(
              transitionOnUserGestures: true,
              tag: 'OTSearchWidget',
              child: OTSearchWidget(),
            ),
            /*Expanded(
              child: SingleChildScrollView(
                child: ListView(
                  children: [],
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
