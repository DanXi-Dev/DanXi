/*
 *     Copyright (C) 2024  DanXi-Dev
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

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// Exactly the same as [DefaultCacheManager], but also implements proxy support.
///
/// Note: It uses the same key as [DefaultCacheManager], so you can even
/// manage the cache of this class with [DefaultCacheManager].
class DefaultCacheManagerWithProxy extends CacheManager with ImageCacheManager {
  static const key = DefaultCacheManager.key;

  static final DefaultCacheManagerWithProxy _instance =
      DefaultCacheManagerWithProxy._();

  factory DefaultCacheManagerWithProxy() {
    return _instance;
  }

  DefaultCacheManagerWithProxy._()
      : super(Config(key, fileService: _buildProxiedHttpFileService()));

  static _buildProxiedHttpFileService() {
    String? proxy = SettingsProvider.getInstance().proxy;
    if (PlatformX.isWeb) {
      return HttpFileService();
    } else {
      return HttpFileService(
          httpClient: IOClient(HttpClient()
            ..findProxy = (uri) => proxy != null ? "PROXY $proxy" : "DIRECT"));
    }
  }
}
