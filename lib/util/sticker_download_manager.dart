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

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dan_xi/model/remote_sticker.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sticker_download_manager.g.dart';

@Riverpod(keepAlive: true)
Future<List<RemoteSticker>> availableStickers(Ref ref) async {
  return await AnnouncementRepository.getInstance().getAvailableStickers();
}

@Riverpod(keepAlive: true)
Future<String> stickerFilePath(Ref ref, String stickerId) async {
  final path = await _buildStickerFilePath(stickerId);
  final stickers = await ref.watch(availableStickersProvider.future);
  final sticker = stickers.firstWhere((sticker) => sticker.id == stickerId);
  final valid = await _validateSticker(path, sticker.sha256);
  if (valid) return path;
  // If not valid, we need to download it
  await _performDownload(sticker);
  return path;
}

final _dio = DioUtils.newDioWithProxy();

Future<void> _performDownload(RemoteSticker sticker) async {
  final response = await _dio.get<Uint8List>(
    sticker.url,
    options: Options(responseType: ResponseType.bytes),
  );

  if (response.data == null) {
    throw Exception('No data received');
  }

  final actualSha256 = sha256.convert(response.data!).toString();
  if (actualSha256 != sticker.sha256) {
    throw Exception('SHA256 mismatch');
  }

  final path = await _buildStickerFilePath(sticker.id);
  final file = File(path);
  await file.writeAsBytes(response.data!);
}

Future<bool> _validateSticker(String path, String expectedSha256) async {
  final file = File(path);
  if (!await file.exists()) return false;
  final bytes = await file.readAsBytes();
  final actualSha256 = sha256.convert(bytes).toString();
  return actualSha256 == expectedSha256;
}

Future<String> _buildStickerFilePath(String stickerId) async {
  final dir = await getApplicationCacheDirectory();
  final stickerDir = "${dir.path}/remote_stickers";
  await Directory(stickerDir).create(recursive: true);
  return "$stickerDir/$stickerId.webp";
}