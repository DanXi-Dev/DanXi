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
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementRepository {
  static const KEY_SEEN_ANNOUNCEMENT = "seen_announcement";
  static const _ID_START_DATE = -1;
  static const _ID_LATEST_VERSION = -2;
  static const _ID_CHANGE_LOG = -3;

  AnnouncementRepository._();

  static final _instance = AnnouncementRepository._();

  factory AnnouncementRepository.getInstance() => _instance;
  List<Announcement>? _announcementCache;

  Future<bool?> loadData() async {
    BmobQuery query = BmobQuery<Announcement>().setOrder("-createdAt");
    _announcementCache = (await query.queryObjects())!
        .map<Announcement>((e) => Announcement.fromJson(e))
        .toList();
    return true;
  }

  Future<Announcement?> getLastNewAnnouncement() async {
    Announcement? announcement = getLastAnnouncement();
    if (announcement == null) return null;
    SharedPreferences pre = await SharedPreferences.getInstance();
    List<String>? list = [];
    if (pre.containsKey(KEY_SEEN_ANNOUNCEMENT)) {
      list = pre.getStringList(KEY_SEEN_ANNOUNCEMENT)!;
      if (list.any(((element) => element == announcement.objectId))) {
        return null;
      } else {
        list.add(announcement.objectId!);
        pre.setStringList(KEY_SEEN_ANNOUNCEMENT, list as List<String>);
        return announcement;
      }
    } else {
      list.add(announcement.objectId!);
      pre.setStringList(KEY_SEEN_ANNOUNCEMENT, list as List<String>);
      return announcement;
    }
  }

  Announcement? getLastAnnouncement() {
    List<Announcement> list = getAnnouncements();
    return list.length > 0 ? list[0] : null;
  }

  List<Announcement> getAnnouncements() {
    final version = int.tryParse("1") ?? 0;
    return _announcementCache
        .filter((element) => element.maxVersion! >= version);
  }

  List<Announcement> getAllAnnouncements() =>
      _announcementCache.filter((element) => element.maxVersion! >= 0);

  DateTime getStartDate() => DateTime.parse(_announcementCache!
      .firstWhere((element) => element.maxVersion == _ID_START_DATE)
      .content!);

  UpdateInfo checkVersion() => UpdateInfo(
      _announcementCache!
          .firstWhere((element) => element.maxVersion == _ID_LATEST_VERSION)
          .content,
      _announcementCache!
          .firstWhere((element) => element.maxVersion == _ID_CHANGE_LOG)
          .content);
}

class UpdateInfo {
  final String? latestVersion;
  final String? changeLog;

  @override
  String toString() {
    return 'UpdateInfo{latestVersion: $latestVersion, changeLog: $changeLog}';
  }

  UpdateInfo(this.latestVersion, this.changeLog);

  bool isAfter(int major, int minor, int patch) {
    List<int?> versions =
        latestVersion!.split(".").map((e) => int.tryParse(e)).toList();
    if (versions[0]! > major)
      return true;
    else if (versions[0]! < major) return false;

    if (versions[1]! > minor)
      return true;
    else if (versions[1]! < minor) return false;

    if (versions[2]! > patch) return true;

    return false;
  }
}
