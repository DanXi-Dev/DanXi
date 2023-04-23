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
import 'package:dan_xi/feature/bus_feature.dart';
import 'package:dan_xi/feature/custom_shortcut.dart';
import 'package:dan_xi/feature/dining_hall_crowdedness_feature.dart';
import 'package:dan_xi/feature/dorm_electricity_feature.dart';
import 'package:dan_xi/feature/ecard_balance_feature.dart';
import 'package:dan_xi/feature/empty_classroom_feature.dart';
import 'package:dan_xi/feature/fudan_library_crowdedness_feature.dart';
import 'package:dan_xi/feature/lan_connection_notification.dart';
import 'package:dan_xi/feature/next_course_feature.dart';
import 'package:dan_xi/feature/pe_feature.dart';
import 'package:dan_xi/feature/qr_feature.dart';
import 'package:dan_xi/feature/welcome_feature.dart';
import 'package:dan_xi/generated/l10n.dart';

/// Save information of every feature.
///
/// Some special features are ignored, like [CustomShortcutFeature] or [LanConnectionNotification].
/// They are generated at runtime and have overall compatibility.

class FeatureMap {
  /// Register all features with [registerFeature].
  ///
  /// Should be invoked only once at startup.
  static registerAllFeatures() {
    registerFeature(
        "bus_feature", () => BusFeature(), (cxt) => S.of(cxt).bus_query);
    registerFeature(
        "dining_hall_crowdedness_feature",
        () => DiningHallCrowdednessFeature(),
        (cxt) => S.of(cxt).dining_hall_crowdedness);
    registerFeature("dorm_electricity_feature", () => DormElectricityFeature(),
        (cxt) => S.of(cxt).dorm_electricity);
    registerFeature("ecard_balance_feature", () => EcardBalanceFeature(),
        (cxt) => S.of(cxt).ecard_balance);
    registerFeature("empty_classroom_feature", () => EmptyClassroomFeature(),
        (cxt) => S.of(cxt).empty_classrooms);
    registerFeature(
        "fudan_library_crowdedness_feature",
        () => FudanLibraryCrowdednessFeature(),
        (cxt) => S.of(cxt).fudan_library_crowdedness);
    registerFeature("next_course_feature", () => NextCourseFeature(),
        (cxt) => S.of(cxt).today_course);
    registerFeature(
        "pe_feature", () => PEFeature(), (cxt) => S.of(cxt).pe_exercises);
    registerFeature(
        "qr_feature", () => QRFeature(), (cxt) => S.of(cxt).fudan_qr_code);
    registerFeature("welcome_feature", () => WelcomeFeature(),
        (cxt) => S.of(cxt).welcome_feature);
    registerFeature("aao_notice_feature", () => FudanAAONoticesFeature(),
        (cxt) => S.of(cxt).fudan_aao_notices);
  }
}
