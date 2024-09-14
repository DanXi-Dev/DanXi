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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/common/pubspec.yaml.g.dart';
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/model/celebration.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:toml/toml.dart';

class AnnouncementRepository {
  static const KEY_SEEN_ANNOUNCEMENT = "seen_announcement";

  AnnouncementRepository._();
  static const _URL =
      "https://danxi-static.fduhole.com/tmp_wait_for_json_editor.toml";

  static final _instance = AnnouncementRepository._();

  factory AnnouncementRepository.getInstance() => _instance;
  Map<String, dynamic>? _tomlCache;

  Future<bool?> loadAnnouncements() async {
    final Response<dynamic> response =
        await DioUtils.newDioWithProxy().get(_URL);
    _tomlCache = TomlDocument.parse(response.data).toMap();
    return _tomlCache?.isNotEmpty ?? false;
  }

  Future<Announcement?> getLastNewAnnouncement() async {
    Announcement? announcement = getLastAnnouncement();
    if (announcement == null) return null;
    XSharedPreferences pre = await XSharedPreferences.getInstance();
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
    final version = int.tryParse(Pubspec.version.build.single) ?? 0;
    if (_tomlCache!['dev_notice'] == null) {
      return [];
    }
    final list = (_tomlCache!['dev_notice'] as List<Map<String, dynamic>>)
        .where((element) => (element['maxVersion'] as int) >= version)
        .toList();
    return list.map<Announcement>((e) => Announcement.fromToml(e)).toList();
  }

  List<Announcement> getAllAnnouncements() {
    if (_tomlCache!['dev_notice'] == null) {
      return [];
    }
    return _tomlCache!['dev_notice']
        .map<Announcement>((e) => Announcement.fromToml(e))
        .toList();
  }

  TimeTableExtra? getStartDates() {
    final fduUg = _tomlCache!['semester_start_date']
        .entries
        .map<TimeTableStartTimeItem>(
            (entry) => TimeTableStartTimeItem(entry.key, entry.value))
        .toList();
    return TimeTableExtra(fduUg);
  }

  String? getUserAgent() {
    return _tomlCache!['user_agent'];
  }

  List<String?>? getStopWords() {
    return _tomlCache!['stop_words'].cast<String>();
  }

  List<BannerExtra?>? getBannerExtras() {
    return _tomlCache!['banners']
        .map<BannerExtra>((banner) =>
            BannerExtra(banner['title'], banner['button'], banner['action']))
        .toList();
  }

  List<String?>? getCareWords() {
    return _tomlCache!['care_words'].cast<String>();
  }

  UpdateInfo checkVersion() {
    return UpdateInfo(
        _tomlCache!['latest_version']['flutter'], _tomlCache!['change_log']);
  }

  Celebration parseCelebration(Map<String, dynamic> m) {
    String date = m['date'];
    int type = date.contains('-') ? 3 : 1;
    return Celebration(type, date, m['words'].cast<String>());
  }

  List<Celebration> getCelebrations() {
    return _tomlCache!['celebrations']
        .map<Celebration>((e) => parseCelebration(e))
        .toList();
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
