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

import 'package:dan_xi/model/sticker/remote_sticker.dart';
import 'package:dan_xi/repository/app/sticker_repository.dart';

enum Stickers {
  dx_angry,
  dx_call,
  dx_cate,
  dx_dying,
  dx_egg,
  dx_fright,
  dx_heart,
  dx_hug,
  dx_overwhelm,
  dx_roll,
  dx_roped,
  dx_sleep,
  dx_swim,
  dx_thrill,
  dx_touch_fish,
  dx_twin,
  dx_kiss,
  dx_onlooker,
  dx_craving,
  dx_caught,
  dx_worn,
  dx_murderous,
  dx_confused,
  dx_like;
}

/// Get local asset path for a sticker
String? getStickerAssetPath(String stickerName) {
  try {
    Stickers sticker =
        Stickers.values.firstWhere((e) => e.name.toString() == stickerName);
    return "assets/graphics/stickers/${sticker.name}.webp";
  } catch (error) {
    return null;
  }
}

/// Get remote sticker information
RemoteSticker? getRemoteSticker(String stickerName) {
  return StickerRepository.getInstance().getRemoteSticker(stickerName);
}

/// Check if a sticker is available (either local or remote)
bool isStickerAvailable(String stickerName) {
  return getStickerAssetPath(stickerName) != null || 
         getRemoteSticker(stickerName) != null;
}

/// Get all available stickers (both local and remote)
List<StickerInfo> getAllAvailableStickers() {
  final List<StickerInfo> allStickers = [];
  
  // Add local stickers
  for (final sticker in Stickers.values) {
    allStickers.add(StickerInfo(
      name: sticker.name,
      displayName: sticker.name.replaceAll('_', ' ').toUpperCase(),
      isLocal: true,
      assetPath: getStickerAssetPath(sticker.name),
    ));
  }
  
  // Add remote stickers
  final remoteStickers = StickerRepository.getInstance().getAllRemoteStickers();
  for (final remoteSticker in remoteStickers) {
    // Skip if already exists as local sticker
    if (Stickers.values.any((s) => s.name == remoteSticker.name)) {
      continue;
    }
    
    allStickers.add(StickerInfo(
      name: remoteSticker.name,
      displayName: remoteSticker.displayName,
      isLocal: false,
      imageUrl: remoteSticker.imageUrl,
      category: remoteSticker.category,
    ));
  }
  
  return allStickers;
}

/// Information about a sticker (local or remote)
class StickerInfo {
  final String name;
  final String displayName;
  final bool isLocal;
  final String? assetPath;
  final String? imageUrl;
  final String? category;
  
  const StickerInfo({
    required this.name,
    required this.displayName,
    required this.isLocal,
    this.assetPath,
    this.imageUrl,
    this.category,
  });
  
  @override
  String toString() {
    return 'StickerInfo{name: $name, displayName: $displayName, isLocal: $isLocal}';
  }
}
