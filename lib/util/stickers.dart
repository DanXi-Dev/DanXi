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

import 'dart:io';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/sticker_download_manager.dart';

Future<String?> getStickerPath(String stickerName) async {
  final repository = AnnouncementRepository.getInstance();
  final remotePath = await repository.getStickerFilePath(stickerName);
  
  // If file exists, return it
  if (remotePath != null && await File(remotePath).exists()) {
    return remotePath;
  }
  
  // If file doesn't exist, trigger download through download manager
  final downloadManager = StickerDownloadManager.instance;
  downloadManager.downloadSticker(stickerName);
  
  // Return null for now - the download will happen in background
  // Widgets should listen to the download manager's state notifiers
  return null;
}
