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
import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/feature/aao_notice_feature.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/feature/bus_feature.dart';
import 'package:dan_xi/feature/custom_shortcut.dart';
import 'package:dan_xi/feature/dining_hall_crowdedness_feature.dart';
import 'package:dan_xi/feature/ecard_balance_feature.dart';
import 'package:dan_xi/feature/empty_classroom_feature.dart';
import 'package:dan_xi/feature/fudan_daily_feature.dart';
import 'package:dan_xi/feature/lan_connection_notification.dart';
import 'package:dan_xi/feature/next_course_feature.dart';
import 'package:dan_xi/feature/pe_feature.dart';
import 'package:dan_xi/feature/qr_feature.dart';
import 'package:dan_xi/feature/welcome_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/scroller_fix/primary_scroll_page.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/feature_item/feature_card_item.dart';
import 'package:dan_xi/widget/feature_item/feature_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';

class HomeSubpage extends PlatformSubpage with PageWithPrimaryScrollController {
  @override
  _HomeSubpageState createState() => _HomeSubpageState();

  HomeSubpage({Key key});

  @override
  String get debugTag => "HomePage";

  @override
  Create<String> get title => (cxt) => S.of(cxt).app_name;

  @override
  Create<List<AppBarButtonItem>> get leading => (cxt) => [
        AppBarButtonItem(
            S.of(cxt).developer_announcement(''),
            Icon(PlatformX.isMaterial(cxt)
                ? Icons.notifications
                : SFSymbols.bell_circle),
            () => smartNavigatorPush(cxt, '/announcement/list'))
      ];

  @override
  Create<List<AppBarButtonItem>> get trailing => (cxt) => [
        AppBarButtonItem(
            S.of(cxt).dashboard_layout,
            Text(
              S.of(cxt).edit,
              textScaleFactor: 1.2,
            ),
            () => smartNavigatorPush(cxt, '/dashboard/reorder').then(
                (value) => RefreshHomepageEvent(onlyIfQueued: true).fire()))
      ];
}

class RefreshHomepageEvent {
  final bool queueRefresh;
  final bool onlyIfQueued;

  RefreshHomepageEvent({this.queueRefresh = false, this.onlyIfQueued = false});
}

class _HomeSubpageState extends State<HomeSubpage>
    with AutomaticKeepAliveClientMixin {
  static final StateStreamListener _refreshSubscription = StateStreamListener();
  Map<String, Widget> widgetMap;
  bool isRefreshQueued = false;
  List<Feature> _notifications = [];

  @override
  void initState() {
    super.initState();
    // initPlatformState();
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshHomepageEvent>().listen((event) {
          if (event.queueRefresh)
            isRefreshQueued = true;
          else if (event.onlyIfQueued) {
            isRefreshQueued = false;
            refreshSelf();
          } else {
            _rebuild();
            refreshSelf();
          }
        }),
        hashCode);
  }

  void checkConnection() {
    FudanAAORepository.getInstance()
        .checkConnection(StateProvider.personInfo.value)
        .then((connected) {
      if (connected) {
        removeNotification(LanConnectionNotification());
      } else {
        addNotification(LanConnectionNotification());
      }
    });
  }

  @override
  void didChangeDependencies() {
    _rebuild();
    super.didChangeDependencies();
  }

  /// This function refreshes the content of Dashboard
  /// Call this when new (online) data should be loaded.
  void _rebuild() {
    checkConnection();
    widgetMap = {
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
      'new_card': Container(),
      'qr_feature': FeatureListItem(
        feature: QRFeature(),
      ),
      'pe_feature': FeatureListItem(
        feature: PEFeature(),
      ),
      'bus_feature': FeatureListItem(
        feature: BusFeature(),
      ),
    };
  }

  @override
  void dispose() {
    super.dispose();
    _refreshSubscription.cancel();
  }

  void addNotification(Feature feature) {
    if (_notifications.any((element) =>
        element.runtimeType.toString() == feature.runtimeType.toString()))
      return;
    _notifications.add(feature);
    refreshSelf();
  }

  void removeNotification(Feature feature) {
    _notifications.removeWhere((element) =>
        feature.runtimeType.toString() == element.runtimeType.toString());
    refreshSelf();
  }

  List<Widget> _buildCards(List<DashboardCard> widgetSequence) {
    List<Widget> _widgets = [];
    _widgets.addAll(_notifications.map((e) => FeatureCardItem(
          feature: e,
          onDismissed: () => _notifications.remove(e),
        )));
    List<Widget> _currentCardChildren = [];
    widgetSequence.forEach((element) {
      if (!element.enabled) return;
      if (element.internalString == 'new_card') {
        if (_currentCardChildren.isEmpty) return;
        _widgets.add(Card(
          child: Column(
            children: _currentCardChildren,
          ),
        ));
        _currentCardChildren = [];
      } else if (element.internalString == 'custom_card') {
        _currentCardChildren.add(FeatureListItem(
          feature:
              CustomShortcutFeature(title: element.title, link: element.link),
        ));
      } else {
        // Skip incompatible items
        if (widgetMap[element.internalString] is FeatureContainer) {
          FeatureContainer container =
              widgetMap[element.internalString] as FeatureContainer;
          if (!checkFeature(
              container.childFeature, StateProvider.personInfo.value.group)) {
            return;
          }
        }
        _currentCardChildren.add(widgetMap[element.internalString]);
      }
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
    super.build(context);
    List<DashboardCard> widgetList =
        SettingsProvider.getInstance().dashboardWidgetsSequence;
    return SafeArea(
        child: RefreshIndicator(
            color: Theme.of(context).accentColor,
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              _rebuild();
              refreshSelf();
            },
            child: Material(
                child: ListView(
              controller: widget.primaryScrollController(context),
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(4),
              children: _buildCards(widgetList),
            ))));
  }

  @override
  bool get wantKeepAlive => true;
}
