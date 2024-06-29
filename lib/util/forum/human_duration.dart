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
import 'package:dan_xi/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Create human-readable duration, e.g.: 1 hour ago, 2 days ago
class HumanDuration {
  static String tryFormat(BuildContext context, DateTime? dateTime) {
    try {
      final Duration duration = DateTime.now().difference(dateTime!);
      if (duration.inSeconds < 1) {
        return S.of(context).moment_ago;
      } else if (duration.inMinutes < 1) {
        return S.of(context).second_ago(duration.inSeconds);
      } else if (duration.inHours < 1) {
        return S.of(context).minute_ago(duration.inMinutes);
      } else if (duration.inDays < 1) {
        return S.of(context).hour_ago(duration.inHours);
      } else if (duration.inDays <= 30) {
        return S.of(context).day_ago(duration.inDays);
      } else {
        return DateFormat("yyyy/MM/dd").format(dateTime.toLocal());
      }
    } catch (e) {
      return "";
    }
  }
}
