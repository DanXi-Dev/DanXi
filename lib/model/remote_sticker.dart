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

import 'package:json_annotation/json_annotation.dart';

part 'remote_sticker.g.dart';

@JsonSerializable()
class RemoteSticker {
  final String id;
  final String url;
  final String sha256;

  RemoteSticker({
    required this.id,
    required this.url,
    required this.sha256,
  });

  factory RemoteSticker.fromJson(Map<String, dynamic> json) =>
      _$RemoteStickerFromJson(json);

  Map<String, dynamic> toJson() => _$RemoteStickerToJson(this);

  factory RemoteSticker.fromToml(Map<String, dynamic> tomlData) {
    return RemoteSticker(
      id: tomlData['id'] as String,
      url: tomlData['url'] as String,
      sha256: tomlData['sha256'] as String,
    );
  }
}