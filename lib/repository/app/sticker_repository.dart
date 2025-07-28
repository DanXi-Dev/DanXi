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
import 'package:dan_xi/model/sticker/remote_sticker.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class StickerRepository extends BaseRepositoryWithDio {
  static const String _STICKER_API_URL = "https://danxi-static.fduhole.com/stickers/manifest.json";
  static const String _CACHED_VERSION_KEY = "cached_sticker_version";
  static const String _CACHED_PACKAGE_KEY = "cached_sticker_package";
  
  StickerRepository._();
  
  static final _instance = StickerRepository._();
  
  factory StickerRepository.getInstance() => _instance;
  
  @override
  String get linkHost => "danxi-static.fduhole.com";
  
  StickerPackage? _cachedPackage;
  
  /// Check if stickers need to be updated and fetch them if necessary
  Future<bool> checkAndUpdateStickers() async {
    try {
      // Fetch the latest manifest
      final Response<dynamic> response = await dio.get(_STICKER_API_URL);
      final Map<String, dynamic> manifestData = response.data as Map<String, dynamic>;
      
      final newPackage = StickerPackage.fromJson(manifestData);
      
      // Check if we need to update
      final prefs = await XSharedPreferences.getInstance();
      final cachedVersion = prefs.getString(_CACHED_VERSION_KEY);
      
      if (cachedVersion != newPackage.version) {
        // Version changed, update cache
        await _cachePackage(newPackage);
        await prefs.setString(_CACHED_VERSION_KEY, newPackage.version);
        _cachedPackage = newPackage;
        
        // Pre-cache images in the background
        precacheImages();
        
        return true; // Updated
      }
      
      // Load from cache if not already loaded
      if (_cachedPackage == null) {
        await _loadCachedPackage();
        // Pre-cache images if we loaded from cache
        if (_cachedPackage != null) {
          precacheImages();
        }
      }
      
      return false; // No update needed
    } catch (e) {
      // If fetch fails, try to load from cache
      if (_cachedPackage == null) {
        await _loadCachedPackage();
      }
      return false;
    }
  }
  
  /// Get the current sticker package
  StickerPackage? getStickerPackage() {
    return _cachedPackage;
  }
  
  /// Get a specific remote sticker by name
  RemoteSticker? getRemoteSticker(String name) {
    if (_cachedPackage == null) return null;
    
    try {
      return _cachedPackage!.stickers.firstWhere((sticker) => sticker.name == name);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all available remote stickers
  List<RemoteSticker> getAllRemoteStickers() {
    return _cachedPackage?.stickers ?? [];
  }
  
  /// Check if there are any remote stickers available
  bool hasRemoteStickers() {
    return _cachedPackage != null && _cachedPackage!.stickers.isNotEmpty;
  }
  
  /// Get cached image for a sticker URL
  Future<String?> getCachedImagePath(String imageUrl) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(imageUrl);
      return file.path;
    } catch (e) {
      return null;
    }
  }
  
  /// Pre-cache all sticker images for better performance
  Future<void> precacheImages() async {
    if (_cachedPackage == null) return;
    
    // Cache images in the background without blocking
    for (final sticker in _cachedPackage!.stickers) {
      // Don't wait for each image, just start the download
      DefaultCacheManager().getSingleFile(sticker.imageUrl).catchError((e) {
        // Ignore individual failures silently
      });
    }
  }
  
  /// Cache the sticker package to local storage
  Future<void> _cachePackage(StickerPackage package) async {
    final prefs = await XSharedPreferences.getInstance();
    final packageJson = jsonEncode(package.toJson());
    await prefs.setString(_CACHED_PACKAGE_KEY, packageJson);
  }
  
  /// Load the cached sticker package from local storage
  Future<void> _loadCachedPackage() async {
    try {
      final prefs = await XSharedPreferences.getInstance();
      final packageJson = prefs.getString(_CACHED_PACKAGE_KEY);
      
      if (packageJson != null) {
        final packageData = jsonDecode(packageJson) as Map<String, dynamic>;
        _cachedPackage = StickerPackage.fromJson(packageData);
      }
    } catch (e) {
      // Ignore cache loading errors
      _cachedPackage = null;
    }
  }
  
  /// Clear all cached sticker data
  Future<void> clearCache() async {
    final prefs = await XSharedPreferences.getInstance();
    await prefs.remove(_CACHED_VERSION_KEY);
    await prefs.remove(_CACHED_PACKAGE_KEY);
    _cachedPackage = null;
    
    // Clear image cache as well
    await DefaultCacheManager().emptyCache();
  }
}