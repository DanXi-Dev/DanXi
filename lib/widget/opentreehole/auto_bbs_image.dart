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
import 'package:dan_xi/widget/render/base_render.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class BBSImagePlaceholder extends StatelessWidget {
  final Widget? child;
  final double? size;

  const BBSImagePlaceholder({Key? key, this.child, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(64),
        foregroundDecoration: BoxDecoration(color: Colors.black12),
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
class AutoBBSImage extends StatefulWidget {
  @protected
  final Dio dio = Dio(BaseOptions(responseType: ResponseType.bytes));
  final String? src;
  final double? maxWidth;
  final ImageTapCallback? onTapImage;

  AutoBBSImage({Key? key, this.src, this.maxWidth, this.onTapImage})
      : super(key: key);

  @override
  _AutoBBSImageState createState() => _AutoBBSImageState();
}

class _AutoBBSImageState extends State<AutoBBSImage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxHeight: widget.maxWidth!),
        child: GestureDetector(
          child: CachedNetworkImage(
              imageUrl: widget.src!,
              width: widget.maxWidth,
              height: widget
                  .maxWidth, // Ensure shape is the same as the loading indicator
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => BBSImagePlaceholder(
                    size: widget.maxWidth,
                    child: Icon(PlatformIcons(context).error,
                        color: Theme.of(context).errorColor),
                  ),
              progressIndicatorBuilder: (context, url, progress) {
                return BBSImagePlaceholder(
                  size: widget.maxWidth,
                  child: progress.progress == null
                      ? Container()
                      : LinearProgressIndicator(
                          value: progress.progress,
                        ),
                );
              }),
          onTap: () => widget.onTapImage!(widget.src),
        ),
      ),
    );
  }
}
