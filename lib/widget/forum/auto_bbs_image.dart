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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dan_xi/util/io/cache_manager_with_webvpn.dart';
import 'package:dan_xi/widget/forum/render/base_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:nil/nil.dart';

class BBSImagePlaceholder extends StatelessWidget {
  final Widget? child;
  final double? size;

  const BBSImagePlaceholder({super.key, this.child, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(64),
        foregroundDecoration: const BoxDecoration(color: Colors.black12),
        width: size,
        height: size,
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

/// A network image loader that will show the image from network, and
/// fit the image's size to at most [maxWidth].
class AutoBBSImage extends StatelessWidget {
  final String src;
  final double? maxWidth;
  final ImageTapCallback? onTapImage;

  const AutoBBSImage({super.key, required this.src, this.maxWidth, this.onTapImage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxHeight: maxWidth!),
        child: GestureDetector(
          child: Hero(
            transitionOnUserGestures: true,
            tag: key ?? this,
            child: CachedNetworkImage(
                imageUrl: src,
                width: maxWidth,
                height: maxWidth,
                cacheManager: DefaultCacheManagerWithWebvpn(),
                // Ensure shape is the same as the loading indicator
                fit: BoxFit.contain,
                errorWidget: (context, url, error) {
                  return BBSImagePlaceholder(
                    size: maxWidth,
                    child: Icon(PlatformIcons(context).error,
                        color: Theme.of(context).colorScheme.error),
                  );
                },
                progressIndicatorBuilder: (context, url, progress) {
                  return BBSImagePlaceholder(
                    size: maxWidth,
                    child: progress.progress == null
                        ? nil
                        : LinearProgressIndicator(
                            value: progress.progress,
                          ),
                  );
                }),
          ),
          onTap: () {
            if (onTapImage != null) onTapImage!(src, key ?? this);
          },
        ),
      ),
    );
  }
}
