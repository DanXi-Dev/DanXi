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
import 'package:json_annotation/json_annotation.dart';

part 'dashboard_card.g.dart';

@JsonSerializable()
class DashboardCard {
  final String? internalString;
  final String? title;
  final String? link;
  bool? enabled;

  DashboardCard(this.internalString, this.title, this.link, this.enabled);

  factory DashboardCard.fromJson(Map<String, dynamic> json) =>
      _$DashboardCardFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardCardToJson(this);

  bool get isSpecialCard =>
      internalString == Constant.FEATURE_NEW_CARD ||
      internalString == Constant.FEATURE_CUSTOM_CARD ||
      internalString == Constant.FEATURE_DIVIDER;
}
