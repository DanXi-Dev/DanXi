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

import 'dart:convert';

import 'package:beautiful_soup_dart/src/extensions.dart';
import 'package:dan_xi/common/pubspec.yaml.g.dart';
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/model/celebration.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementRepository {
  static const KEY_SEEN_ANNOUNCEMENT = "seen_announcement";
  static const _ID_START_DATE = -1;
  static const _ID_LATEST_VERSION = -2;
  static const _ID_CHANGE_LOG = -3;
  static const _ID_CELEBRATION = -4;
  static const _ID_EXTRA_DATA = -5;

  AnnouncementRepository._();

  static const _URL = "https://danxi-static.fduhole.com/all.json";

  static final _instance = AnnouncementRepository._();

  factory AnnouncementRepository.getInstance() => _instance;
  List<Announcement>? _announcementCache;

  Future<bool?> loadAnnouncements() async {
    final Response<List<dynamic>> response = await Dio().get(_URL);
    _announcementCache =
        response.data?.map((e) => Announcement.fromJson(e)).toList() ?? [];
    return _announcementCache?.isNotEmpty ?? false;
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
        pre.setStringList(KEY_SEEN_ANNOUNCEMENT, list);
        return announcement;
      }
    } else {
      list.add(announcement.objectId!);
      pre.setStringList(KEY_SEEN_ANNOUNCEMENT, list);
      return announcement;
    }
  }

  Announcement? getLastAnnouncement() {
    List<Announcement> list = getAnnouncements();
    return list.firstOrNull;
  }

  List<Announcement> getAnnouncements() {
    final version = int.tryParse(build.first) ?? 0;
    return _announcementCache
        .filter((element) => element.maxVersion! >= version);
  }

  List<Announcement> getAllAnnouncements() =>
      _announcementCache.filter((element) => element.maxVersion! >= 0);

  @Deprecated(
      "Never use single startDate any more. Call getStartDates() instead")
  DateTime getStartDate() => DateTime.parse(_announcementCache!
      .firstWhere((element) => element.maxVersion == _ID_START_DATE)
      .content!);

  TimeTableExtra? getStartDates() {
    return getExtra()?.timetable;
  }

  String? getUserAgent() {
    return getExtra()?.userAgent;
  }

  List<String?>? getStopWords() {
    return getExtra()?.stopWords;
  }

  List<BannerExtra?>? getBannerExtras() {
    return getExtra()?.banners;
  }

  Extra? getExtra() {
    return _announcementCache.apply((p0) => Extra.fromJson(jsonDecode(p0
        .firstWhere((element) => element.maxVersion == _ID_EXTRA_DATA)
        .content!)));
  }

  UpdateInfo checkVersion() {
    return UpdateInfo(
        _announcementCache!
            .firstWhere((element) => element.maxVersion == _ID_LATEST_VERSION)
            .content,
        _announcementCache!
            .firstWhere((element) => element.maxVersion == _ID_CHANGE_LOG)
            .content);
  }

  List<Celebration> getCelebrations() {
    List celebrationJson = jsonDecode(_announcementCache!
        .firstWhere((element) => element.maxVersion == _ID_CELEBRATION)
        .content!);
    return celebrationJson.map((e) => Celebration.fromJson(e)).toList();
  }
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
    if (versions[0]! > major) {
      return true;
    } else if (versions[0]! < major) {
      return false;
    }

    if (versions[1]! > minor) {
      return true;
    } else if (versions[1]! < minor) {
      return false;
    }

    if (versions[2]! > patch) return true;

    return false;
  }
}
