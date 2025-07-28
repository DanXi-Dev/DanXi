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
import 'package:dan_xi/model/sticker_download_state.dart';
import 'package:dan_xi/model/remote_sticker.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:flutter/foundation.dart';

/// Manages individual sticker download states and coordinates background downloads
class StickerDownloadManager {
  static StickerDownloadManager? _instance;
  static StickerDownloadManager get instance => _instance ??= StickerDownloadManager._internal();
  
  StickerDownloadManager._internal();

  /// Map of sticker ID to download state notifier
  final Map<String, ValueNotifier<StickerDownloadState>> _stickerStates = {};
  
  /// Map of sticker ID to download info
  final Map<String, StickerDownloadInfo> _stickerInfo = {};
  
  /// Currently active download futures to prevent duplicate downloads
  final Map<String, Future<bool>> _activeDownloads = {};

  /// Get the download state notifier for a specific sticker
  ValueNotifier<StickerDownloadState> getStickerStateNotifier(String stickerId) {
    return _stickerStates[stickerId] ??= ValueNotifier(const StickerNotDownloaded());
  }

  /// Get the current download state for a sticker
  StickerDownloadState getStickerState(String stickerId) {
    return _stickerStates[stickerId]?.value ?? const StickerNotDownloaded();
  }

  /// Register a sticker with its metadata for potential download
  void registerSticker(RemoteSticker sticker) {
    _stickerInfo[sticker.id] = StickerDownloadInfo(
      stickerId: sticker.id,
      url: sticker.url,
      sha256: sticker.sha256,
      state: getStickerState(sticker.id),
    );
    
    // Check if sticker is already downloaded
    _checkStickerAvailability(sticker.id);
  }

  /// Check if a sticker file exists and update state accordingly
  Future<void> _checkStickerAvailability(String stickerId) async {
    final repository = AnnouncementRepository.getInstance();
    final filePath = await repository.getStickerFilePath(stickerId);
    
    if (filePath != null && await File(filePath).exists()) {
      _updateStickerState(stickerId, StickerDownloaded(filePath));
    }
  }

  /// Download a sticker if not already downloaded or downloading
  Future<bool> downloadSticker(String stickerId) async {
    // Check if already downloading
    final activeDownload = _activeDownloads[stickerId];
    if (activeDownload != null) {
      return activeDownload;
    }

    // Check if already downloaded
    final currentState = getStickerState(stickerId);
    if (currentState is StickerDownloaded) {
      return true;
    }

    final info = _stickerInfo[stickerId];
    if (info == null || info.url == null || info.sha256 == null) {
      _updateStickerState(stickerId, StickerDownloadFailed('Missing sticker metadata', DateTime.now()));
      return false;
    }

    // Start download
    _updateStickerState(stickerId, const StickerDownloading());
    
    final downloadFuture = _performDownload(stickerId, info.url!, info.sha256!);
    _activeDownloads[stickerId] = downloadFuture;
    
    try {
      final success = await downloadFuture;
      return success;
    } finally {
      _activeDownloads.remove(stickerId);
    }
  }

  /// Perform the actual download of a sticker
  Future<bool> _performDownload(String stickerId, String url, String expectedSha256) async {
    try {
      final repository = AnnouncementRepository.getInstance();
      final sticker = RemoteSticker(id: stickerId, url: url, sha256: expectedSha256);
      
      final success = await repository.downloadAndValidateSticker(sticker);
      
      if (success) {
        final filePath = await repository.getStickerFilePath(stickerId);
        if (filePath != null) {
          _updateStickerState(stickerId, StickerDownloaded(filePath));
          return true;
        }
      }
      
      _updateStickerState(stickerId, StickerDownloadFailed('Download failed', DateTime.now()));
      return false;
    } catch (e) {
      _updateStickerState(stickerId, StickerDownloadFailed(e.toString(), DateTime.now()));
      return false;
    }
  }

  /// Retry downloading a failed sticker
  Future<bool> retryDownload(String stickerId) async {
    final currentState = getStickerState(stickerId);
    if (currentState is! StickerDownloadFailed) {
      return false;
    }
    
    return downloadSticker(stickerId);
  }

  /// Update the state of a sticker and notify listeners
  void _updateStickerState(String stickerId, StickerDownloadState newState) {
    final notifier = getStickerStateNotifier(stickerId);
    notifier.value = newState;
    
    // Update info if exists
    final info = _stickerInfo[stickerId];
    if (info != null) {
      _stickerInfo[stickerId] = info.copyWith(state: newState);
    }
  }

  /// Get download info for a sticker
  StickerDownloadInfo? getStickerInfo(String stickerId) {
    return _stickerInfo[stickerId];
  }

  /// Get all registered sticker IDs
  List<String> get registeredStickerIds => _stickerInfo.keys.toList();

  /// Get count of stickers in each state
  Map<Type, int> getStateCounts() {
    final counts = <Type, int>{};
    for (final notifier in _stickerStates.values) {
      final stateType = notifier.value.runtimeType;
      counts[stateType] = (counts[stateType] ?? 0) + 1;
    }
    return counts;
  }

  /// Download all registered stickers that aren't already downloaded
  Future<void> downloadAllStickers() async {
    final downloadFutures = <Future<bool>>[];
    
    for (final stickerId in _stickerInfo.keys) {
      final state = getStickerState(stickerId);
      if (state is! StickerDownloaded) {
        downloadFutures.add(downloadSticker(stickerId));
      }
    }
    
    // Download in parallel
    await Future.wait(downloadFutures);
  }

  /// Clear all state (useful for testing or reset scenarios)
  void clearAllState() {
    _stickerStates.clear();
    _stickerInfo.clear();
    _activeDownloads.clear();
  }
}