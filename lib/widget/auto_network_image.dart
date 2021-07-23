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

import 'dart:math';
import 'dart:ui' as ui;

import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/image_render_x.dart';
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
  final GestureTapCallback onTap;

  AutoNetworkImage(
      {Key key,
      this.src,
      this.maxWidth,
      this.loadingWidget,
      this.errorWidget,
      this.onTap})
      : super(key: key);

  @override
  _AutoNetworkImageState createState() => _AutoNetworkImageState();
}

class _AutoNetworkImageState extends State<AutoNetworkImage> {
  List<int> _rawImage;
  Future<Size> _loadResult;

  Future<Size> loadImage(String url) async {
    if (_rawImage == null || _rawImage.isEmpty) {
      Response response = await widget.dio.get(url);
      _rawImage = response.data;
    }
    ui.Image image = await decodeImageFromList(_rawImage);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  @override
  void initState() {
    super.initState();
    _loadResult = loadImage(widget.src);
  }

  @override
  Widget build(BuildContext context) {
    return FutureWidget<Size>(
        future: _loadResult,
        successBuilder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
          double displayWidth = min(snapshot.data.width, widget.maxWidth);
          return GestureDetector(
            child: StdImageContainer(
              width: displayWidth,
              child: Image.memory(
                _rawImage,
                width: displayWidth,
                height: displayWidth,
                fit: BoxFit.fitHeight,
              ),
            ),
            onTap: widget.onTap,
          );
        },
        errorBuilder: widget.errorWidget ?? Container(),
        loadingBuilder: widget.loadingWidget ??
            Center(
              child: PlatformCircularProgressIndicator(),
            ));
  }
}
