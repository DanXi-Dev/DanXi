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

import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:dan_xi/page/image_viewer.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/image_render_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
//import 'package:flutter_html/flutter_html.dart';
//import 'package:flutter_html/style.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:markdown_widget/markdown_widget.dart';

class SmartRenderer extends StatelessWidget {
  final String content;
  const SmartRenderer({Key key, this.content}) : super(key: key);

  /// Determine if content is HTML (or Markdown)
  bool isContentHtml(String content) {
    if (RegExp(r"<.*?>.*?</.*?>").hasMatch(content)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    OnTap onLinkTap = (url, _, __, ___) {
      if (ImageViewerPage.isImage(url)) {
        smartNavigatorPush(context, '/image/detail', arguments: {'url': url});
      } else {
        BrowserUtil.openUrl(url, context);
      }
    };
    double imageWidth = ViewportUtils.getMainNavigatorWidth(context) * 0.75;
    /*if (isContentHtml(content))
      return Html(
        shrinkWrap: true,
        data: preprocessContentForDisplay(content),
        style: {
          "body": Style(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            fontSize: FontSize(16),
          ),
          "p": Style(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            fontSize: FontSize(16),
          ),
        },
        customImageRenders: {
          networkSourceMatcher(): networkImageClipRender(
              loadingWidget: () => Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      foregroundDecoration:
                          BoxDecoration(color: Colors.black12),
                      width: imageWidth,
                      height: imageWidth,
                      child: Center(
                        child: PlatformCircularProgressIndicator(),
                      ),
                    ),
                  ),
              maxHeight: imageWidth),
        },
        onLinkTap: onLinkTap,
        onImageTap: onLinkTap,
      );
    else*/
    return MarkdownWidget(
      data: content,
      styleConfig: StyleConfig(
        imgBuilder: (String url, attributes) {
          return Image.network(
            url,
            width: imageWidth,
            height: imageWidth,
            loadingBuilder: (_, __, ___) => Center(
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
          );
        },
      ),
    );
  }
}
