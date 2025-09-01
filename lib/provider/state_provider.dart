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

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/remote_sticker.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/sticker_download_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Manage global states of the app.
///
/// Code Structural Warning:
/// You should ONLY directly refer to this class in the codes of
/// Application layer, rather than in any classes of Util, Model or Repository.
/// Do NOT break the decoupling of the project!
class StateProvider {
  /// The user's basic information.
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
  static final ValueNotifier<PersonInfo?> personInfo = ValueNotifier(null);
  static bool needScreenshotWarning = false;
  static bool isForeground = true;
  static bool showingScreenshotWarning = false;

  static String? onlineUserAgent;

  /// Available stickers loaded from the server.
  static final ValueNotifier<List<RemoteSticker>?> availableStickers = ValueNotifier(null);
  static final ValueNotifier<bool> stickersLoading = ValueNotifier(false);
  static final ValueNotifier<dynamic> stickersError = ValueNotifier(null);

  /// Load available stickers from the server.
  static Future<void> loadAvailableStickers() async {
    if (stickersLoading.value) return; // Prevent duplicate loading
    
    stickersLoading.value = true;
    stickersError.value = null;
    
    try {
      final stickers = await AnnouncementRepository.getInstance().getAvailableStickers();
      availableStickers.value = stickers;
      
      // Register all stickers with the download manager for background downloading
      final downloadManager = StickerDownloadManager.instance;
      for (final sticker in stickers) {
        downloadManager.registerSticker(sticker);
      }
      
      // Start background downloads for all stickers that aren't already downloaded
      downloadManager.downloadAllStickers();
    } catch (error) {
      stickersError.value = error;
    } finally {
      stickersLoading.value = false;
    }
  }

  /// Refresh available stickers.
  static Future<void> refreshAvailableStickers() async {
    availableStickers.value = null;
    await loadAvailableStickers();
  }

  static void initialize(BuildContext context) {
    ForumProvider provider = context.read<ForumProvider>();
    provider.currentDivisionId = null;
    isLoggedIn.value = false;
    personInfo.value = null;
    isForeground = true;
    needScreenshotWarning = showingScreenshotWarning = false;
    provider.editorCache.clear();
    
    // Reset sticker state
    availableStickers.value = null;
    stickersLoading.value = false;
    stickersError.value = null;
    
    // Clear download manager state
    StickerDownloadManager.instance.clearAllState();
  }
}
