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

/// Represents the download state of an individual sticker
sealed class StickerDownloadState {
  const StickerDownloadState();
}

/// Sticker has not been downloaded yet
class StickerNotDownloaded extends StickerDownloadState {
  const StickerNotDownloaded();
}

/// Sticker is currently being downloaded
class StickerDownloading extends StickerDownloadState {
  final double? progress;
  
  const StickerDownloading({this.progress});
}

/// Sticker has been successfully downloaded and is available
class StickerDownloaded extends StickerDownloadState {
  final String filePath;
  
  const StickerDownloaded(this.filePath);
}

/// Sticker download failed
class StickerDownloadFailed extends StickerDownloadState {
  final String error;
  final DateTime timestamp;
  
  const StickerDownloadFailed(this.error, this.timestamp);
}

/// Information about a sticker's download status and metadata
class StickerDownloadInfo {
  final String stickerId;
  final String? url;
  final String? sha256;
  final StickerDownloadState state;
  
  const StickerDownloadInfo({
    required this.stickerId,
    this.url,
    this.sha256,
    required this.state,
  });
  
  StickerDownloadInfo copyWith({
    String? stickerId,
    String? url,
    String? sha256,
    StickerDownloadState? state,
  }) {
    return StickerDownloadInfo(
      stickerId: stickerId ?? this.stickerId,
      url: url ?? this.url,
      sha256: sha256 ?? this.sha256,
      state: state ?? this.state,
    );
  }
}