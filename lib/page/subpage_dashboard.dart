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
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/feature/custom_shortcut.dart';
import 'package:dan_xi/feature/lan_connection_notification.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/notification_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/empty_classroom_repository.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/feature_item/feature_card_item.dart';
import 'package:dan_xi/widget/feature_item/feature_list_item.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HomeSubpage extends PlatformSubpage<HomeSubpage> {
  @override
  HomeSubpageState createState() => HomeSubpageState();

  const HomeSubpage({super.key});

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
            Text(S.of(cxt).edit, textScaler: TextScaler.linear(1.2)),
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
    _rebuildFeatures();
  }

  void checkConnection() {
    EmptyClassroomRepository.getInstance().checkConnection().then((connected) {
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
    // Get all feature builders from [featureFactory] and build them.
    widgetMap = featureFactory.map((key, value) => MapEntry(
        key,
        FeatureListItem(
          feature: value(),
        )));
    // Add other custom widgets, such as [Divider].
    widgetMap.addAll({
      Constant.FEATURE_DIVIDER: const Divider(),
    });
  }

  @override
  void dispose() {
    super.dispose();
    _refreshSubscription.cancel();
  }

  List<Widget> _buildCards(List<DashboardCard> widgetSequence) {
    List<Widget> widgets = [];
    NotificationProvider provider = context.watch<NotificationProvider>();
    widgets.addAll(provider.notifications.map((e) => FeatureCardItem(
          feature: e,
          onDismissed: () async {
            final name = e.runtimeType.toString();
            provider.removeNotification(e);
            // Ask the user if he/she wants to hide the notification permanently.
            bool? hide = await Noticing.showConfirmationDialog(
                context, S.of(context).hide_notification_description,
                isConfirmDestructive: true);
            if (hide == true && mounted) {
              final provider = context.read<SettingsProvider>();
              final oldList = provider.hiddenNotifications;
              oldList.add(name);
              provider.hiddenNotifications = oldList;
            }
          },
        )));
    List<Widget> currentCardChildren = [];
    for (var element in widgetSequence) {
      if (element.enabled != true) continue;
      if (element.internalString == Constant.FEATURE_NEW_CARD) {
        if (currentCardChildren.isEmpty) continue;
        widgets.add(Card(
          child: Column(
            children: currentCardChildren,
          ),
        ));
        currentCardChildren = [];
      } else if (element.internalString == Constant.FEATURE_CUSTOM_CARD) {
        currentCardChildren.add(FeatureListItem(
          feature:
              CustomShortcutFeature(title: element.title, link: element.link),
        ));
      } else {
        // Skip incompatible items
        var widget = widgetMap[element.internalString!];
        if (widget == null) continue;
        if (widget is FeatureContainer) {
          FeatureContainer container = widget as FeatureContainer;
          if (!checkFeature(
              container.childFeature, StateProvider.personInfo.value!.group)) {
            continue;
          }
        }
        currentCardChildren.add(widget);
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
