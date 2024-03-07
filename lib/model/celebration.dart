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

import 'package:dan_xi/util/vague_time.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lunar/calendar/Lunar.dart';

part 'celebration.g.dart';

@JsonSerializable()
class Celebration {
  /// Type of celebration [date].
  ///
  /// 1: Chinese lunar festival(e.g. date = 春节)
  /// 2: Chinese lunar date(e.g. date = 01-01)
  /// 3: Standard date(e.g. date = 01-01)
  final int type;

  final String date;

  final List<String> celebrationWords;

  /// Return whether the [date] corresponds with [dateTime].
  bool match(DateTime dateTime) {
    switch (type) {
      case 1:
        return Lunar.fromDate(dateTime).getFestivals().contains(date);
      case 2:
        var lunarDate = Lunar.fromDate(dateTime);
        var splitTime = date.split("-");
        return lunarDate.getMonth() == int.parse(splitTime[0]) &&
            lunarDate.getDay() == int.parse(splitTime[1]);
      case 3:
        return VagueTime.onlyMMdd(date).match(dateTime);
    }
    return false;
  }

  const Celebration(this.type, this.date, this.celebrationWords);

  Map<String, dynamic> toJson() => _$CelebrationToJson(this);

  factory Celebration.fromJson(Map<String, dynamic> json) =>
      _$CelebrationFromJson(json);
}
