/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/feature/ecard_balance_feature.dart';
import 'package:dan_xi/feature/fudan_daily_feature.dart';
import 'package:dan_xi/feature/welcome_feature.dart';
import 'package:dan_xi/feature/wlan_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/main.dart' as main_qr;
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/widget/feature_item/feature_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:screen/screen.dart';

class HomeSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  _HomeSubpageState createState() => _HomeSubpageState();

  HomeSubpage({Key key});
}

class _HomeSubpageState extends State<HomeSubpage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  //Get current brightness with _brightness
  double _brightness = 1.0;

  initPlatformState() async {
    double brightness = await Screen.brightness;
    setState(() {
      _brightness = brightness;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    PersonInfo info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;
    return RefreshIndicator(
        onRefresh: () async => refreshSelf(),
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              children: <Widget>[
                Card(
                    child: Column(
                  children: [
                    FeatureListItem(feature: WelcomeFeature()),
                    Divider(),
                    FeatureListItem(feature: WlanFeature()),
                    FeatureListItem(feature: EcardBalanceFeature()),
                    ListTile(
                      leading: Icon(Icons.stacked_line_chart),
                      title: Text(S.of(context).dining_hall_crowdedness),
                      onTap: () {
                        Navigator.of(context).pushNamed("/card/crowdData",
                            arguments: {"personInfo": info});
                      },
                    )
                  ],
                )),
                Card(child: FeatureListItem(feature: FudanDailyFeature())),
                Card(
                  child: ListTile(
                    title: Text(S.of(context).fudan_qr_code),
                    leading: const Icon(Icons.qr_code),
                    subtitle: Text(S.of(context).tap_to_view),
                    onTap: () {
                      main_qr.QR.showQRCode(context, info, _brightness);
                    },
                  ),
                )
              ],
            )));
  }
}
