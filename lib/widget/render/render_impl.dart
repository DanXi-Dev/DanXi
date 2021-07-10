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

import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/render/base_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:dan_xi/widget/image_render_x.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

BaseRender kHtmlRender = (BuildContext context, String content,
    LinkTapCallback onTapImage, LinkTapCallback onTapLink) {
  double imageWidth = ViewportUtils.getMainNavigatorWidth(context) * 0.75;
  Style noPaddingStyle = Style(
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    fontSize: FontSize(16),
  );
  return Html(
    shrinkWrap: true,
    data: content,
    style: {
      "body": noPaddingStyle,
      "p": noPaddingStyle,
    },
    customImageRenders: {
      networkSourceMatcher(): networkImageClipRender(
          loadingWidget: () => Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  foregroundDecoration: BoxDecoration(color: Colors.black12),
                  width: imageWidth,
                  height: imageWidth,
                  child: Center(
                    child: PlatformCircularProgressIndicator(),
                  ),
                ),
              ),
          maxHeight: imageWidth),
    },
    onLinkTap: (url, _, __, ___) => onTapLink(url),
    onImageTap: (url, _, __, ___) => onTapImage(url),
  );
};
