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

import 'package:dan_xi/feature/feature_map.dart';
import 'package:dan_xi/feature/lan_connection_notification.dart';
import 'package:dan_xi/provider/notification_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A Feature is a functional item shown on the dashboard, with which user interacts via tapping.
///
///
/// ## Note: A Checklist After Creating a New [Feature]
/// (For a Notification (see [LanConnectionNotification] as an example), you don't need to do any of these!)
///
/// 1. Register it in [FeatureMap].
/// 2. Insert it at a appropriate position to [Constant.defaultDashboardCardList].
///
/// See also:
/// - [NotificationProvider], a provider to hold a list of notifications.
abstract class Feature {
  /// Request [FeatureContainer] to update the widget status since they're changed.
  @nonVirtual
  notifyUpdate() => container.doUpdate();

  bool get clickable => false;

  bool get loadOnTap => true;

  Widget? get icon => null;

  String? get mainTitle;

  String? get subTitle => null;

  String? get tertiaryTitle => null;

  Widget? get customSubtitle => null;

  Widget? get trailing => null;

  EdgeInsets? get padding => null;

  bool get removable => false;

  late FeatureContainerState container;

  BuildContext? context;

  void buildFeature([Map<String, dynamic>? arguments]) {}

  /// Called when FeatureContainer invokes [initState].
  void initFeature() {}

  /// Called when Feature is clicked.
  void onTap() {}

  void onEvent(FeatureEvent event) {}
}

/// FeatureContainer is a container to render the feature as a list item.
/// Usually is a class of [State<StatefulWidget>]
mixin FeatureContainerState {
  void doUpdate();
}

mixin FeatureContainer {
  Feature get childFeature;
}

enum FeatureEvent { CREATE, REMOVE }
