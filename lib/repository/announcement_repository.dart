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

import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/util/bmob/bmob/bmob_query.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    List<Announcement> list = await getAnnouncements();
    print(list);
    return list.length > 0 ? list[0] : null;
  }

  Future<List<Announcement>> getAnnouncements() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    BmobQuery<Announcement> query = BmobQuery<Announcement>()
        .setOrder("-createdAt")
        .addWhereGreaterThanOrEqualTo(
            "maxVersion", int.tryParse(packageInfo.buildNumber) ?? 0);
    return (await query.queryObjects())
        .map<Announcement>((e) => Announcement.fromJson(e))
        .toList();
  }
}
