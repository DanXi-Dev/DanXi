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

import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/feature/aao_notice_feature.dart';
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
import 'package:dan_xi/model/person.dart';

/// Save information of every feature.
///
/// Some special features are ignored, like [CustomShortcutFeature] or [LanConnectionNotification].
/// They are generated at runtime and have overall compatibility.

class FeatureMap {
  /// Register all features with [registerFeature].
  ///
  /// Should be invoked only once at startup.
  static registerAllFeatures() {
    registerFeature(FudanAAONoticesFeature());
    registerFeature(DiningHallCrowdednessFeature());
    registerFeature(EcardBalanceFeature());
    registerFeature(EmptyClassroomFeature());
    registerFeature(FudanDailyFeature());
    registerFeature(NextCourseFeature());
    registerFeature(PEFeature());
    registerFeature(QRFeature());
    registerFeature(WelcomeFeature(), groups: UserGroup.values);
  }
}
