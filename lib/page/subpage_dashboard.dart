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
import 'package:dan_xi/feature/dorm_electricity_feature.dart';
import 'package:dan_xi/feature/ecard_balance_feature.dart';
import 'package:dan_xi/feature/empty_classroom_feature.dart';
import 'package:dan_xi/feature/fudan_daily_feature.dart';
import 'package:dan_xi/feature/fudan_library_crowdedness_feature.dart';
import 'package:dan_xi/feature/lan_connection_notification.dart';
import 'package:dan_xi/feature/next_course_feature.dart';
import 'package:dan_xi/feature/pe_feature.dart';
import 'package:dan_xi/feature/qr_feature.dart';
import 'package:dan_xi/feature/welcome_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/ad_manager.dart';
import 'package:dan_xi/provider/notification_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/library_repository.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/feature_item/feature_card_item.dart';
import 'package:dan_xi/widget/feature_item/feature_list_item.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class HomeSubpage extends PlatformSubpage<HomeSubpage> {
  @override
  HomeSubpageState createState() => HomeSubpageState();

  const HomeSubpage({Key? key}) : super(key: key);

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).dashboard);

  @override
  Create<List<AppBarButtonItem>> get leading => (cxt) => [
        AppBarButtonItem(
            S.of(cxt).developer_announcement(''),
            Icon(PlatformX.isMaterial(cxt)
                ? Icons.notifications
                : CupertinoIcons.bell_circle),
            () => smartNavigatorPush(cxt, '/announcement/list'))
      ];

  @override
  Create<List<AppBarButtonItem>> get trailing => (cxt) => [
        AppBarButtonItem(
            S.of(cxt).dashboard_layout,
            Text(S.of(cxt).edit, textScaleFactor: 1.2),
            () => smartNavigatorPush(cxt, '/dashboard/reorder').then(
                (value) => RefreshHomepageEvent(onlyRefreshOrder: true).fire()))
      ];
}

class RefreshHomepageEvent {
  /// Tell the page not to rebuild all features, just update the order or visibility of them.
  final bool onlyRefreshOrder;

  RefreshHomepageEvent({this.onlyRefreshOrder = false});
}

class HomeSubpageState extends PlatformSubpageState<HomeSubpage> {
  static final StateStreamListener<RefreshHomepageEvent> _refreshSubscription =
      StateStreamListener();
  late Map<String, Widget> widgetMap;

  Future<BannerAd?>? bannerAd;
  late NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();
    _notificationProvider = context.read<NotificationProvider>();
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshHomepageEvent>().listen((event) {
          if (event.onlyRefreshOrder) {
            refreshSelf();
          } else {
            triggerRebuildFeatures();
          }
        }),
        hashCode);
    bannerAd = AdManager.loadBannerAd(0); // 0 for main page
    _rebuildFeatures();
  }

  void checkConnection() {
    FudanLibraryRepository.getInstance().checkConnection().then((connected) {
      if (connected) {
        _notificationProvider.removeNotification(LanConnectionNotification());
      } else {
        _notificationProvider.addNotification(LanConnectionNotification());
      }
    });
  }

  /// This function rebuilds the content of Dashboard.
  ///
  /// Only call this when new (online) data should be loaded.
  void _rebuildFeatures() {
    checkConnection();
    widgetMap = {
      'welcome_feature': FeatureListItem(feature: WelcomeFeature()),
      'next_course_feature': FeatureListItem(feature: NextCourseFeature()),
      'divider': const Divider(),
      'ecard_balance_feature': FeatureListItem(feature: EcardBalanceFeature()),
      'dining_hall_crowdedness_feature':
          FeatureListItem(feature: DiningHallCrowdednessFeature()),
      'fudan_library_crowdedness_feature':
          FeatureListItem(feature: FudanLibraryCrowdednessFeature()),
      'aao_notice_feature': FeatureListItem(feature: FudanAAONoticesFeature()),
      'empty_classroom_feature':
          FeatureListItem(feature: EmptyClassroomFeature()),
      'fudan_daily_feature': FeatureListItem(feature: FudanDailyFeature()),
      'new_card': const SizedBox(),
      'qr_feature': FeatureListItem(feature: QRFeature()),
      'pe_feature': FeatureListItem(feature: PEFeature()),
      'bus_feature': FeatureListItem(feature: BusFeature()),
      'dorm_electricity_feature':
          FeatureListItem(feature: DormElectricityFeature()),
    };
  }

  @override
  void dispose() {
    super.dispose();
    _refreshSubscription.cancel();
  }

  List<Widget> _buildCards(List<DashboardCard> widgetSequence) {
    List<Widget> widgets = [
      AutoBannerAdWidget(
        bannerAd: bannerAd,
      )
    ];
    NotificationProvider provider = context.watch<NotificationProvider>();
    widgets.addAll(provider.notifications.map((e) => FeatureCardItem(
          feature: e,
          onDismissed: () => provider.removeNotification(e),
        )));
    List<Widget> currentCardChildren = [];
    for (var element in widgetSequence) {
      if (!element.enabled!) continue;
      if (element.internalString == 'new_card') {
        if (currentCardChildren.isEmpty) continue;
        widgets.add(Card(
          child: Column(
            children: currentCardChildren,
          ),
        ));
        currentCardChildren = [];
      } else if (element.internalString == 'custom_card') {
        currentCardChildren.add(FeatureListItem(
          feature:
              CustomShortcutFeature(title: element.title, link: element.link),
        ));
      } else {
        // Skip incompatible items
        if (widgetMap[element.internalString!] is FeatureContainer) {
          FeatureContainer container =
              widgetMap[element.internalString!] as FeatureContainer;
          if (!checkFeature(
              container.childFeature, StateProvider.personInfo.value!.group)) {
            continue;
          }
        }
        currentCardChildren.add(widgetMap[element.internalString!]!);
      }
    }
    if (currentCardChildren.isNotEmpty) {
      widgets.add(Card(
        child: Column(
          children: currentCardChildren,
        ),
      ));
    }
    return widgets;
  }

  /// Tell the page to refresh all shown features and rebuild itself.
  void triggerRebuildFeatures() {
    _rebuildFeatures();
    refreshSelf();
  }

  @override
  Widget buildPage(BuildContext context) {
    List<DashboardCard> widgetList =
        SettingsProvider.getInstance().dashboardWidgetsSequence;
    return WithScrollbar(
        controller: PrimaryScrollController.of(context),
        child: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).padding.top,
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              LimitedQueuedInterceptor.getInstance().dropAllRequest();
              triggerRebuildFeatures();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: _buildCards(widgetList),
            )));
  }
}
