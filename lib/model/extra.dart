/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'package:dan_xi/model/person.dart';
import 'package:json_annotation/json_annotation.dart';

part 'extra.g.dart';

@JsonSerializable()
class TimeTableExtra {
  /// The semester's start date of Fudan Undergraduates.
  List<TimeTableStartTimeItem>? fdu_ug;

  TimeTableExtra(this.fdu_ug);

  factory TimeTableExtra.fromJson(Map<String, dynamic> json) =>
      _$TimeTableExtraFromJson(json);

  Map<String, dynamic> toJson() => _$TimeTableExtraToJson(this);

  String? parseStartDate(UserGroup group, String semesterId) {
    List<TimeTableStartTimeItem>? items;
    switch (group) {
      case UserGroup.FUDAN_UNDERGRADUATE_STUDENT:
        items = fdu_ug;
        break;
      case UserGroup.VISITOR:
      case UserGroup.FUDAN_POSTGRADUATE_STUDENT:
      case UserGroup.FUDAN_STAFF:
      case UserGroup.SJTU_STUDENT:
        break;
    }
    var item = items?.firstWhere((element) => element.id == semesterId,
        orElse: () => TimeTableStartTimeItem(null, null));
    return item?.startDate;
  }
}

@JsonSerializable()
class TimeTableStartTimeItem {
  String? id;
  String? startDate;

  TimeTableStartTimeItem(this.id, this.startDate);

  factory TimeTableStartTimeItem.fromJson(Map<String, dynamic> json) =>
      _$TimeTableStartTimeItemFromJson(json);

  Map<String, dynamic> toJson() => _$TimeTableStartTimeItemToJson(this);
}

@JsonSerializable()
class BannerExtra {
  final String title;
  final String actionName;
  final String action;

  BannerExtra(this.title, this.actionName, this.action);

  factory BannerExtra.fromJson(Map<String, dynamic> json) =>
      _$BannerExtraFromJson(json);

  Map<String, dynamic> toJson() => _$BannerExtraToJson(this);
}
