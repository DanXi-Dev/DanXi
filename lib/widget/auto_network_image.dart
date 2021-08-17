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
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A network image loader that will show the image from network, and
/// fit the image's size to at most [maxWidth].
class AutoNetworkImage extends StatefulWidget {
  @protected
  final Dio dio = Dio(BaseOptions(responseType: ResponseType.bytes));
  final String src;
  final double maxWidth;
  final Widget loadingWidget;
  final Widget errorWidget;
  final ImageTapCallback onTapImage;

  AutoNetworkImage(
      {Key key,
      this.src,
      this.maxWidth,
      this.loadingWidget,
      this.errorWidget,
      this.onTapImage})
      : super(key: key);

  @override
  _AutoNetworkImageState createState() => _AutoNetworkImageState();
}

class _AutoNetworkImageState extends State<AutoNetworkImage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        constraints: BoxConstraints(maxHeight: widget.maxWidth),
        child: GestureDetector(
          child: CachedNetworkImage(
            imageUrl: widget.src,
            width: widget.maxWidth,
            fit: BoxFit.contain,
            progressIndicatorBuilder: (_, __, ___) =>
                widget.loadingWidget ??
                Center(
                  child: PlatformCircularProgressIndicator(),
                ),
          ),
          onTap: () => widget.onTapImage(widget.src),
        ),
      ),
    );
  }
}
