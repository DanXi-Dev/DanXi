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

class RemoteSticker {
  /// Sticker identifier (e.g., "dx_heart")
  final String name;
  
  /// Display name for the sticker
  final String displayName;
  
  /// URL to the sticker image
  final String imageUrl;
  
  /// Optional category for grouping stickers
  final String? category;

  const RemoteSticker({
    required this.name,
    required this.displayName,
    required this.imageUrl,
    this.category,
  });

  factory RemoteSticker.fromJson(Map<String, dynamic> json) {
    return RemoteSticker(
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      imageUrl: json['image_url'] as String,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
      'image_url': imageUrl,
      if (category != null) 'category': category,
    };
  }

  @override
  String toString() {
    return 'RemoteSticker{name: $name, displayName: $displayName, imageUrl: $imageUrl, category: $category}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteSticker &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class StickerPackage {
  /// Version of the sticker package
  final String version;
  
  /// List of stickers in this package
  final List<RemoteSticker> stickers;
  
  /// Optional description
  final String? description;
  
  /// Last updated timestamp
  final String? updatedAt;

  const StickerPackage({
    required this.version,
    required this.stickers,
    this.description,
    this.updatedAt,
  });

  factory StickerPackage.fromJson(Map<String, dynamic> json) {
    return StickerPackage(
      version: json['version'] as String,
      stickers: (json['stickers'] as List<dynamic>)
          .map((e) => RemoteSticker.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'stickers': stickers.map((e) => e.toJson()).toList(),
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'StickerPackage{version: $version, stickers: ${stickers.length}, description: $description, updatedAt: $updatedAt}';
  }
}