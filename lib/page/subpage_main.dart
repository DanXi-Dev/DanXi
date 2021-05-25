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
import 'package:dan_xi/feature/aao_notice_feature.dart';
import 'package:dan_xi/feature/dining_hall_crowdedness_feature.dart';
import 'package:dan_xi/feature/ecard_balance_feature.dart';
import 'package:dan_xi/feature/empty_classroom_feature.dart';
import 'package:dan_xi/feature/fudan_daily_feature.dart';
import 'package:dan_xi/feature/next_course_feature.dart';
import 'package:dan_xi/feature/qr_feature.dart';
import 'package:dan_xi/feature/welcome_feature.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/feature_item/feature_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  bool get needBottomPadding => true;

  @override
  _HomeSubpageState createState() => _HomeSubpageState();

  HomeSubpage({Key key});
}

class RefreshHomepageEvent {}

class _HomeSubpageState extends State<HomeSubpage> {
  static final StateStreamListener _refreshSubscription = StateStreamListener();
  SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshHomepageEvent>().listen((_) {
          refreshSelf();
        }),
        hashCode);
  }

  @override
  void didChangeDependencies() {
    _preferences = Provider.of<SharedPreferences>(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    _refreshSubscription.cancel();
  }

  //Get current brightness with _brightness
  double _brightness = 1.0;

  double get brightness => _brightness;

  initPlatformState() async {
    _brightness = await ScreenProxy.brightness;
  }

  // TODO: Looks like all widgets are built when creating this map
  // Is there a way to create them only when needed?
  static Map<String, Widget> widgetMap = {
    'welcome_feature': FeatureListItem(
      feature: WelcomeFeature(),
    ),
    'next_course_feature': FeatureListItem(
      feature: NextCourseFeature(),
    ),
    'divider': Divider(),
    'ecard_balance_feature': FeatureListItem(
      feature: EcardBalanceFeature(),
    ),
    'dining_hall_crowdedness_feature': FeatureListItem(
      feature: DiningHallCrowdednessFeature(),
    ),
    'aao_notice_feature': FeatureListItem(
      feature: FudanAAONoticesFeature(),
    ),
    'empty_classroom_feature': FeatureListItem(
      feature: EmptyClassroomFeature(),
    ),
    'fudan_daily_feature': FeatureListItem(
      feature: FudanDailyFeature(),
    ),
    'seperate_card': Container(),
    'qr_feature': FeatureListItem(
      feature: QRFeature(),
    ),
  };

  List<Widget> _buildCards(List<String> widgetSequence) {
    List<Widget> _widgets = [];
    List<Widget> _currentCardChildren = [];
    widgetSequence.forEach((element) {
      if (element == 'seperate_card') {
        _widgets.add(Card(
          child: Column(
            children: _currentCardChildren,
          ),
        ));
        _currentCardChildren = [];
      }
      _currentCardChildren.add(widgetMap[element]);
    });
    if (_currentCardChildren.isNotEmpty) {
      _widgets.add(Card(
        child: Column(
          children: _currentCardChildren,
        ),
      ));
    }
    return _widgets;
  }

  @override
  Widget build(BuildContext context) {
    List<String> widgetList =
        SettingsProvider.of(_preferences).dashboardWidgetsSequence;
    return RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          refreshSelf();
        },
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView(
              padding: EdgeInsets.all(4),
              children: _buildCards(widgetList),
            )));
  }
}
