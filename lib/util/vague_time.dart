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
/// filled later. It is useful to represent some schedule(e.g. 8:00 everyday).
class VagueTime implements Comparable<VagueTime> {
  int? year, month, day, hour, minute, second, millisecond, microsecond;

  VagueTime(
      {this.year,
      this.month,
      this.day,
      this.hour,
      this.minute,
      this.second,
      this.millisecond,
      this.microsecond});

  factory VagueTime.onlyMMSS(String mmss) {
    var splitTime = mmss.split(":");
    return VagueTime(
        hour: int.parse(splitTime[0]), minute: int.parse(splitTime[1]));
  }

  /// Merge the unfilled field with [exactDate], and return the filled time.
  DateTime toExactTime([DateTime? exactDate]) {
    if (exactDate == null) exactDate = DateTime.now();
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

  @override
  int compareTo(VagueTime other) =>
      toExactTime().compareTo(other.toExactTime());
}
