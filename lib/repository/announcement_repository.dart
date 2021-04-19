/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/model/announcement.dart';
import 'package:data_plugin/bmob/bmob_query.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementRepository {
  static const KEY_SEEN_ANNOUNCEMENT = "seen_announcement";

  AnnouncementRepository._();

  static final _instance = AnnouncementRepository._();

  factory AnnouncementRepository.getInstance() => _instance;

  Future<Announcement> getLastNewAnnouncement() async {
    Announcement announcement = await getLastAnnouncement();
    if (announcement == null) return null;
    var pre = await SharedPreferences.getInstance();
    List<String> list = [];
    if (pre.containsKey(KEY_SEEN_ANNOUNCEMENT)) {
      list = pre.getStringList(KEY_SEEN_ANNOUNCEMENT);
      if (list.any((element) => element == announcement.objectId)) {
        return null;
      } else {
        list.add(announcement.objectId);
        pre.setStringList(KEY_SEEN_ANNOUNCEMENT, list);
        return announcement;
      }
    } else {
      list.add(announcement.objectId);
      pre.setStringList(KEY_SEEN_ANNOUNCEMENT, list);
      return announcement;
    }
  }

  Future<Announcement> getLastAnnouncement() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    BmobQuery query = BmobQuery<Announcement>()
        .setOrder("-createdAt")
        .addWhereGreaterThanOrEqualTo(
            "maxVersion", int.parse(packageInfo.buildNumber));
    var list = await query.queryObjects();
    if (list.length > 0) {
      return Announcement.fromJson(list[0]);
    } else {
      return null;
    }
  }
}
