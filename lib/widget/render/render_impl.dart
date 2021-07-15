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

import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/auto_network_image.dart';
import 'package:dan_xi/widget/render/base_render.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:dan_xi/widget/image_render_x.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

const double kFontSize = 16.0;

BaseRender kHtmlRender = (BuildContext context, String content,
    LinkTapCallback onTapImage, LinkTapCallback onTapLink) {
  double imageWidth = ViewportUtils.getMainNavigatorWidth(context) * 0.75;
  Style noPaddingStyle = Style(
    margin: EdgeInsets.zero,
    padding: EdgeInsets.zero,
    fontSize: FontSize(kFontSize),
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

MarkdownStyleSheet _getMarkdownStyleSheetFromPlatform(BuildContext context) {
  if (PlatformX.isCupertino(context)) {
    return MarkdownStyleSheet.fromCupertinoTheme(CupertinoTheme.of(context));
  } else {
    return MarkdownStyleSheet.fromTheme(Theme.of(context));
  }
}

MarkdownStyleSheet _fontSizeOverride(
    MarkdownStyleSheet sheet, double fontSize) {
  return sheet.copyWith(
    p: sheet.p?.copyWith(fontSize: fontSize),
    a: sheet.a?.copyWith(fontSize: fontSize),
    em: sheet.em?.copyWith(fontSize: fontSize),
    strong: sheet.strong?.copyWith(fontSize: fontSize),
    del: sheet.del?.copyWith(fontSize: fontSize),
    blockquote: sheet.blockquote?.copyWith(fontSize: fontSize),
    listBullet: sheet.listBullet?.copyWith(fontSize: fontSize),
    checkbox: sheet.checkbox?.copyWith(fontSize: fontSize),
  );
}

BaseRender kMarkdownRender = (BuildContext context, String content,
    LinkTapCallback onTapImage, LinkTapCallback onTapLink) {
  double imageWidth = ViewportUtils.getMainNavigatorWidth(context) * 0.75;

  return MarkdownBody(
    data: content,
    styleSheet: _fontSizeOverride(
        _getMarkdownStyleSheetFromPlatform(context), kFontSize),
    onTapLink: (String text, String href, String title) =>
        onTapLink?.call(href),
    imageBuilder: (Uri uri, String title, String alt) {
      if (uri != null && uri.toString() != null) {
        return Center(
          child: AutoNetworkImage(
            src: uri.toString(),
            maxWidth: imageWidth,
            loadingWidget: Center(
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
            onTap: () => onTapImage?.call((uri.toString())),
          ),
        );
      }
      return Container();
    },
  );
};
