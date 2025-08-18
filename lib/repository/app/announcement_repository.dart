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
import 'dart:io';
import 'dart:typed_data';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:crypto/crypto.dart';
import 'package:dan_xi/common/pubspec.yaml.g.dart';
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/model/celebration.dart';
import 'package:dan_xi/model/remote_sticker.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:toml/toml.dart';

class AnnouncementRepository {
  static const KEY_SEEN_ANNOUNCEMENT = "seen_announcement";

  AnnouncementRepository._();
  static const _URL =
      "https://danxi-static.fduhole.com/tmp_wait_for_json_editor.toml";

  static final _instance = AnnouncementRepository._();

  factory AnnouncementRepository.getInstance() => _instance;
  Map<String, dynamic>? _tomlCache;
  String? _cacheDirectory;

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
    List<Announcement>? list = getAnnouncements();
    return list?.firstOrNull;
  }

  List<Announcement>? getAnnouncements() {
    if (_tomlCache == null) {
      return null;
    }

    final version = int.tryParse(Pubspec.version.build.single) ?? 0;
    if (_tomlCache!['dev_notice'] == null) {
      return [];
    }
    final list = (_tomlCache!['dev_notice'] as List<Map<String, dynamic>>)
        .where((element) => (element['build'] as int) >= version)
        .toList();
    final announcements =
        list.map<Announcement>((e) => Announcement.fromToml(e)).toList();
    announcements.sort((a, b) =>
        (DateTime.parse(b.updatedAt!)).compareTo(DateTime.parse(a.updatedAt!)));
    return announcements;
  }

  List<Announcement>? getAllAnnouncements() {
    if (_tomlCache == null) {
      return null;
    }

    if (_tomlCache!['dev_notice'] == null) {
      return [];
    }
    final announcements = _tomlCache!['dev_notice']
        .map<Announcement>((e) => Announcement.fromToml(e))
        .toList();
    announcements?.sort((a, b) =>
        (DateTime.parse(b.updatedAt!)).compareTo(DateTime.parse(a.updatedAt!)));
    return announcements;
  }

  TimeTableExtra? getStartDates() {
    if (_tomlCache == null) {
      return null;
    }

    final fduUg = _tomlCache!['semester_start_date']
        .entries
        .map<TimeTableStartTimeItem>(
            (entry) => TimeTableStartTimeItem(entry.key, entry.value))
        .toList();
    return TimeTableExtra(fduUg);
  }

  String? getUserAgent() {
    if (_tomlCache == null) {
      return null;
    }

    return _tomlCache!['user_agent'];
  }

  List<String?>? getStopWords() {
    if (_tomlCache == null) {
      return null;
    }

    return _tomlCache!['stop_words'].cast<String>();
  }

  List<BannerExtra?>? getBannerExtras() {
    if (_tomlCache == null) {
      return null;
    }

    return _tomlCache!['banners']
        .map<BannerExtra>((banner) =>
            BannerExtra(banner['title'], banner['button'], banner['action']))
        .toList();
  }

  List<String?>? getCareWords() {
    if (_tomlCache == null) {
      return null;
    }

    return _tomlCache!['care_words'].cast<String>();
  }

  UpdateInfo? checkVersion() {
    if (_tomlCache == null) {
      return null;
    }

    return UpdateInfo(
        _tomlCache!['latest_version']['flutter'], _tomlCache!['change_log']);
  }

  Celebration parseCelebration(Map<String, dynamic> m) {
    String date = m['date'];
    int type = date.contains('-') ? 3 : 1;
    return Celebration(type, date, m['words'].cast<String>());
  }

  List<Celebration>? getCelebrations() {
    if (_tomlCache == null) {
      return null;
    }

    return _tomlCache!['celebrations']
        .map<Celebration>((e) => parseCelebration(e))
        .toList();
  }

  List<int> getHighlightedTagIds() {
    if (_tomlCache == null) {
      return [];
    }

    return _tomlCache!['highlight_tag_ids'].cast<int>();
  }

  // Cloud Sticker Methods
  Future<String> get _stickerCacheDir async {
    if (_cacheDirectory != null) return _cacheDirectory!;
    final dir = await getApplicationCacheDirectory();
    _cacheDirectory = "${dir.path}/remote_stickers";
    await Directory(_cacheDirectory!).create(recursive: true);
    return _cacheDirectory!;
  }



  Future<List<String>> getCachedStickerIds() async {
    final cacheDir = await _stickerCacheDir;
    final directory = Directory(cacheDir);

    if (!directory.existsSync()) {
      return [];
    }

    return directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.webp'))
        .map((file) {
      final fileName = file.path.split(Platform.pathSeparator).last;
      return fileName.substring(
          0, fileName.length - 5); // Remove .webp extension
    }).toList();
  }

  Future<String?> getStickerFilePath(String stickerId) async {
    final cacheDir = await _stickerCacheDir;
    final file = File("$cacheDir/$stickerId.webp");
    return file.existsSync() ? file.path : null;
  }

  Future<String> _calculateSha256(Uint8List data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  Future<bool> _validateStickerFile(
      String filePath, String expectedSha256) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;

      final data = await file.readAsBytes();
      final actualSha256 = await _calculateSha256(data);
      return actualSha256 == expectedSha256;
    } catch (e) {
      return false;
    }
  }

  Future<bool> downloadAndValidateSticker(RemoteSticker sticker) async {
    try {
      final response = await DioUtils.newDioWithProxy().get<Uint8List>(
        sticker.url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) return false;

      final actualSha256 = await _calculateSha256(response.data!);
      if (actualSha256 != sticker.sha256) {
        return false;
      }

      final cacheDir = await _stickerCacheDir;
      final file = File("$cacheDir/${sticker.id}.webp");
      await file.writeAsBytes(response.data!);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<RemoteSticker>> syncStickers() async {
    try {
      // Ensure announcements are loaded first
      if (_tomlCache == null) {
        await loadAnnouncements();
      }

      // Get stickers from TOML
      final stickerList = _tomlCache!['sticker'] as List?;
      final networkStickers = stickerList != null
          ? stickerList.map((data) => RemoteSticker.fromToml(data as Map<String, dynamic>)).toList()
          : <RemoteSticker>[];
      
      if (networkStickers.isEmpty) {
        return [];
      }

      for (final networkSticker in networkStickers) {
        final filePath = await getStickerFilePath(networkSticker.id);

        // Download if not cached or if validation fails
        if (filePath == null ||
            !await _validateStickerFile(filePath, networkSticker.sha256)) {
          await downloadAndValidateSticker(networkSticker);
        }
      }

      return networkStickers;
    } catch (e) {
      final stickerList = _tomlCache?['sticker'] as List?;
      return stickerList != null
          ? stickerList.map((data) => RemoteSticker.fromToml(data as Map<String, dynamic>)).toList()
          : <RemoteSticker>[];
    }
  }

  Future<List<RemoteSticker>> getAvailableStickers() async {
    // Ensure announcements are loaded first
    if (_tomlCache == null) {
      await loadAnnouncements();
    }

    // Get stickers from TOML
    final stickerList = _tomlCache!['sticker'] as List?;
    final networkStickers = stickerList != null
        ? stickerList.map((data) => RemoteSticker.fromToml(data as Map<String, dynamic>)).toList()
        : <RemoteSticker>[];
    
    final cachedStickerIds = await getCachedStickerIds();

    // Return only stickers that are both defined in TOML and have cached files
    return networkStickers.where((sticker) {
      return cachedStickerIds.contains(sticker.id);
    }).toList();
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

  bool isAfter(Version version) => Version.parse(latestVersion!) > version;
}
