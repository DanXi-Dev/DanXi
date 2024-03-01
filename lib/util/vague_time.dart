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

/// VagueTime is a data class of time & date, which contains incomplete time fields to be
/// filled later.
///
/// It is useful to represent some schedule (e.g. 8:00 everyday).
class VagueTime implements Comparable<VagueTime> {
  final int? year, month, day, hour, minute, second, millisecond, microsecond;

  const VagueTime(
      {this.year,
      this.month,
      this.day,
      this.hour,
      this.minute,
      this.second,
      this.millisecond,
      this.microsecond});

  factory VagueTime.onlyHHmm(String hhmm) {
    var splitTime = hhmm.split(":");
    return VagueTime(
        hour: int.parse(splitTime[0]), minute: int.parse(splitTime[1]));
  }

  factory VagueTime.onlyMMdd(String mmdd) {
    var splitTime = mmdd.split("-");
    return VagueTime(
        month: int.parse(splitTime[0]), day: int.parse(splitTime[1]));
  }

  /// Merge the unfilled field with [exactDate], and return the filled time.
  DateTime toExactTime([DateTime? exactDate]) {
    exactDate ??= DateTime.now();
    return DateTime(
        year ?? exactDate.year,
        month ?? exactDate.month,
        day ?? exactDate.day,
        hour ?? exactDate.hour,
        minute ?? exactDate.minute,
        second ?? exactDate.second,
        millisecond ?? exactDate.millisecond,
        microsecond ?? exactDate.microsecond);
  }

  /// Compare to decide if it is matched with given [time].
  /// If matched, return true.
  bool match(DateTime time) => !((year != null && year != time.year) ||
      (month != null && month != time.month) ||
      (day != null && day != time.day) ||
      (hour != null && hour != time.hour) ||
      (minute != null && minute != time.minute) ||
      (second != null && second != time.second) ||
      (millisecond != null && millisecond != time.millisecond) ||
      (microsecond != null && microsecond != time.microsecond));

  @override
  int compareTo(VagueTime other) =>
      toExactTime().compareTo(other.toExactTime());
}
