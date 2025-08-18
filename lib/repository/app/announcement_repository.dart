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
  static const String _CACHE_KEY_STICKERS = "remote_sticker_cache";

  AnnouncementRepository._();
  static const _URL =
      "https://danxi-static.fduhole.com/tmp_wait_for_json_editor.toml";

  static final _instance = AnnouncementRepository._();

  factory AnnouncementRepository.getInstance() => _instance;
  Map<String, dynamic>? _tomlCache;
  List<RemoteSticker>? _cachedStickers;
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
    final dir = await getApplicationSupportDirectory();
    _cacheDirectory = "${dir.path}/remote_stickers";
    await Directory(_cacheDirectory!).create(recursive: true);
    return _cacheDirectory!;
  }

  List<RemoteSticker>? getStickersFromCache() {
    if (_tomlCache == null) {
      return null;
    }
    // Get stickers directly from TOML cache
    final stickerList = _tomlCache!['sticker'] as List?;
    if (stickerList == null) return null;
    
    try {
      return stickerList.map((data) => RemoteSticker.fromToml(data as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<List<RemoteSticker>> loadStickersFromNetwork() async {
    // Ensure TOML is loaded
    if (_tomlCache == null) {
      await loadAnnouncements();
    }
    
    // Get stickers directly from the main TOML file
    final stickers = getStickersFromCache();
    return stickers ?? [];
  }

  Future<List<RemoteSticker>> getCachedStickers() async {
    if (_cachedStickers != null) return _cachedStickers!;
    
    final prefs = await XSharedPreferences.getInstance();
    final cachedData = prefs.getString(_CACHE_KEY_STICKERS);
    
    if (cachedData != null) {
      final List<dynamic> jsonList = json.decode(cachedData);
      _cachedStickers = jsonList.map((json) => RemoteSticker.fromJson(json)).toList();
      return _cachedStickers!;
    }
    
    return [];
  }

  Future<void> saveCachedStickers(List<RemoteSticker> stickers) async {
    _cachedStickers = stickers;
    final prefs = await XSharedPreferences.getInstance();
    final jsonString = json.encode(stickers.map((s) => s.toJson()).toList());
    await prefs.setString(_CACHE_KEY_STICKERS, jsonString);
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

  Future<bool> _validateStickerFile(String filePath, String expectedSha256) async {
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
      final networkStickers = getStickersFromCache() ?? [];
      if (networkStickers.isEmpty) {
        return await getCachedStickers();
      }
      
      final cachedStickers = await getCachedStickers();
      
      final Map<String, RemoteSticker> cachedMap = {
        for (var sticker in cachedStickers) sticker.id: sticker
      };
      
      final List<RemoteSticker> toDownload = [];
      final List<RemoteSticker> toRevalidate = [];
      
      for (final networkSticker in networkStickers) {
        final cached = cachedMap[networkSticker.id];
        
        if (cached == null) {
          toDownload.add(networkSticker);
        } else if (cached.sha256 != networkSticker.sha256) {
          toRevalidate.add(networkSticker);
        } else {
          final filePath = await getStickerFilePath(networkSticker.id);
          if (filePath == null || !await _validateStickerFile(filePath, networkSticker.sha256)) {
            toRevalidate.add(networkSticker);
          }
        }
      }
      
      for (final sticker in [...toDownload, ...toRevalidate]) {
        await downloadAndValidateSticker(sticker);
      }
      
      await saveCachedStickers(networkStickers);
      return networkStickers;
    } catch (e) {
      return await getCachedStickers();
    }
  }

  Future<List<RemoteSticker>> getAvailableStickers() async {
    // Ensure announcements are loaded first
    if (_tomlCache == null) {
      await loadAnnouncements();
    }
    
    final cached = await getCachedStickers();
    if (cached.isEmpty) {
      return await syncStickers();
    }
    return cached;
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
