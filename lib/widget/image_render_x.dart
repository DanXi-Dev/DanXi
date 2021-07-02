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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/image_render.dart';

///Copy of [ImageRender] methods. Use image clip to restrain the height of the image.
String _src(Map<String, String> attributes) {
  return attributes["src"];
}

String _alt(Map<String, String> attributes) {
  return attributes["alt"];
}

double _height(Map<String, String> attributes) {
  final heightString = attributes["height"];
  return heightString == null
      ? heightString as double
      : double.tryParse(heightString);
}

double _width(Map<String, String> attributes) {
  final widthString = attributes["width"];
  return widthString == null
      ? widthString as double
      : double.tryParse(widthString);
}

double _aspectRatio(
    Map<String, String> attributes, AsyncSnapshot<Size> calculated) {
  final heightString = attributes["height"];
  final widthString = attributes["width"];
  if (heightString != null && widthString != null) {
    final height = double.tryParse(heightString);
    final width = double.tryParse(widthString);
    return height == null || width == null
        ? calculated.data.aspectRatio
        : width / height;
  }
  return calculated.data.aspectRatio;
}

ImageRender networkImageClipRender({
  Map<String, String> headers,
  String Function(String) mapUrl,
  double width,
  double maxHeight,
  Widget Function(String) altWidget,
  Widget Function() loadingWidget,
}) =>
    (context, attributes, element) {
      final src = mapUrl?.call(_src(attributes)) ?? _src(attributes);
      precacheImage(
        NetworkImage(
          src,
          headers: headers,
        ),
        context.buildContext,
        onError: (exception, StackTrace stackTrace) {
          context.parser.onImageError?.call(exception, stackTrace);
        },
      );
      Completer<Size> completer = Completer();
      Image image = Image.network(src, frameBuilder: (ctx, child, frame, _) {
        if (frame == null) {
          if (!completer.isCompleted) {
            completer.completeError("error");
          }
          return child;
        } else {
          return child;
        }
      });

      image.image.resolve(ImageConfiguration()).addListener(
            ImageStreamListener((ImageInfo image, bool synchronousCall) {
              var myImage = image.image;
              Size size =
                  Size(myImage.width.toDouble(), myImage.height.toDouble());
              if (!completer.isCompleted) {
                completer.complete(size);
              }
            }, onError: (object, stacktrace) {
              if (!completer.isCompleted) {
                completer.completeError(object);
              }
            }),
          );

      return FutureBuilder<Size>(
        future: completer.future,
        builder: (BuildContext buildContext, AsyncSnapshot<Size> snapshot) {
          if (snapshot.hasData) {
            var realWidth = width ?? _width(attributes) ?? snapshot.data.width;
            var realHeight = _height(attributes) ?? snapshot.data.height;
            if (maxHeight != null && realHeight > maxHeight)
              realHeight = maxHeight;
            return Container(
              constraints:
                  BoxConstraints(maxWidth: realWidth, maxHeight: realHeight),
              child: Image.network(
                src,
                fit: BoxFit.fitWidth,
                headers: headers,
                width: realWidth,
                height: realHeight,
                frameBuilder: (ctx, child, frame, _) {
                  if (frame == null) {
                    return altWidget?.call(_alt(attributes)) ??
                        Text(_alt(attributes) ?? "",
                            style: context.style.generateTextStyle());
                  }
                  return child;
                },
              ),
            );
          } else if (snapshot.hasError) {
            return altWidget?.call(_alt(attributes)) ??
                Text(_alt(attributes) ?? "",
                    style: context.style.generateTextStyle());
          } else {
            return loadingWidget?.call() ?? const CircularProgressIndicator();
          }
        },
      );
    };
