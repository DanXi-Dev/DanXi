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

import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/stickers.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/forum/auto_bbs_image.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:dan_xi/widget/forum/render/base_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/atom-one-dark.dart';
import 'package:flutter_highlighting/themes/atom-one-light.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:highlighting/languages/all.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nil/nil.dart';

const double kFontSize = 16.0;
const double kFontLargerSize = 24.0;
/*BaseRender kHtmlRender = (BuildContext context, String? content,
    ImageTapCallback? onTapImage, LinkTapCallback? onTapLink) {
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
    onLinkTap: (url, _, __, ___) => onTapLink?.call(url),
    customImageRenders: {
      networkSourceMatcher(): (context, attributes, element) {
        return Center(
          child: AutoBBSImage(
              src: attributes['src'],
              maxWidth: imageWidth,
              onTapImage: onTapImage),
        );
      },
    },
  );
};*/

MarkdownStyleSheet _getMarkdownStyleSheetFromPlatform(BuildContext context) =>
    MarkdownStyleSheet.fromTheme(Theme.of(context));

// Override the font size and background of blockquote
MarkdownStyleSheet _markdownStyleOverride(
    MarkdownStyleSheet sheet, double? fontSize) {
  return sheet.copyWith(
    p: sheet.p?.copyWith(fontSize: fontSize),
    a: sheet.a?.copyWith(fontSize: fontSize),
    em: sheet.em?.copyWith(fontSize: fontSize),
    strong: sheet.strong?.copyWith(fontSize: fontSize),
    del: sheet.del?.copyWith(fontSize: fontSize),
    blockquote: sheet.blockquote?.copyWith(fontSize: fontSize),
    blockquoteDecoration: BoxDecoration(
      color: PlatformX.isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100,
      borderRadius: BorderRadius.circular(2.0),
    ),
    listBullet: sheet.listBullet?.copyWith(fontSize: fontSize),
    checkbox: sheet.checkbox?.copyWith(fontSize: fontSize),
  );
}

/// Markdown render creator.
///
/// [defaultFontSize] is the default font size of the markdown content. If it is
/// null, the default font size of theme will be used.
final kMarkdownRenderFactory = (double? defaultFontSize) =>
    (BuildContext context,
        String? content,
        ImageTapCallback? onTapImage,
        LinkTapCallback? onTapLink,
        bool translucentCard,
        bool isPreviewWidget) {
      double imageWidth = ViewportUtils.getMainNavigatorWidth(context) * 0.75;
      final imageBuilder = (Uri uri, String? title, String? alt) {
        String url = uri.toString();
        // render stickers first
        if (url.startsWith("danxi_")) {
          // backward compatibility: <=1.4.3, danxi_ is used; after that, dx_ is used
          url = url.replaceFirst("danxi_", "dx_");
        }
        if (url.startsWith("dx_")) {
          var asset = getStickerAssetPath(url);
          // print(asset);
          if (asset != null) {
            return Image.asset(
              asset,
              width: 50,
              height: 50,
            );
          }
        }

        return Center(
          child: AutoBBSImage(
              key: UniqueKey(),
              src: url,
              maxWidth: imageWidth,
              onTapImage: onTapImage),
        );
      };

      return MarkdownBody(
          softLineBreak: true,
          data: content!,
          styleSheet: _markdownStyleOverride(
              _getMarkdownStyleSheetFromPlatform(context), defaultFontSize),
          onTapLink: (String text, String? href, String title) =>
              onTapLink?.call(href),
          inlineSyntaxes: [
            LatexSyntax(),
            LatexMultiLineSyntax(),
            MentionSyntax(),
            AuditSyntax()
          ],
          builders: {
            HighlightBuilder.tag: HighlightBuilder(
                PlatformX.isDarkMode ? atomOneDarkTheme : atomOneLightTheme),
            MarkdownLatexSupport.tag: MarkdownLatexSupport(),
            MarkdownLatexMultiLineSupport.tag: MarkdownLatexMultiLineSupport(),
            MarkdownFloorMentionSupport.tag:
                MarkdownFloorMentionSupport(translucentCard, isPreviewWidget),
            MarkdownHoleMentionSupport.tag:
                MarkdownHoleMentionSupport(translucentCard, isPreviewWidget),
          },
          imageBuilder: imageBuilder);
    };

final BaseRender kMarkdownRender = kMarkdownRenderFactory(kFontSize);

final BaseRender kPlainRender = (BuildContext context,
    String? content,
    ImageTapCallback? onTapImage,
    LinkTapCallback? onTapLink,
    bool translucentCard,
    bool isPreviewWidget) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Text(content ?? "")],
  );
};

final BaseRender kMarkdownSelectorRender = (BuildContext context,
    String? content,
    ImageTapCallback? onTapImage,
    LinkTapCallback? onTapLink,
    bool translucentCard,
    bool isPreviewWidget) {
  return SelectionArea(
    child: Markdown(
      softLineBreak: true,
      data: content!,
      styleSheet: _markdownStyleOverride(
          _getMarkdownStyleSheetFromPlatform(context), kFontLargerSize),
      onTapLink: (String text, String? href, String title) =>
          onTapLink?.call(href),
      imageBuilder: (Uri uri, String? title, String? alt) => nil,
    ),
  );
};

// Refer to: https://github.com/flutter/flutter/issues/81755#issuecomment-807917577
class HighlightBuilder extends MarkdownElementBuilder {
  static const String tag = "code";
  final Map<String, TextStyle>? theme;
  final TextStyle? textStyle;

  HighlightBuilder([this.theme, this.textStyle]);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = 'plaintext';
    final pattern = RegExp(r'^language-(.+)$');
    if (element.attributes['class'] != null &&
        pattern.hasMatch(element.attributes['class']!)) {
      language = pattern.firstMatch(element.attributes['class']!)?.group(1) ??
          'plaintext';
    }
    return HighlightView(element.textContent.trim(),
        // Avoid null error if language doesn't exist
        languageId:
            builtinLanguages.containsKey(language) ? language : 'plaintext',
        theme: theme ?? {},
        padding: const EdgeInsets.all(8),
        textStyle: textStyle ??
            const TextStyle(fontFamily: 'Monospace', fontSize: 16.0));
  }
}

class MarkdownLatexSupport extends MarkdownElementBuilder {
  static const String tag = "tex";

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) =>
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(element.textContent));
}

class MarkdownLatexMultiLineSupport extends MarkdownElementBuilder {
  static const String tag = "texLine";

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(element.textContent),
      ),
    );
  }
}

class MarkdownFloorMentionSupport extends MarkdownElementBuilder {
  static const String tag = "floorMention";

  final bool hasBackgroundImage;
  final bool isPreviewWidget;

  MarkdownFloorMentionSupport(this.hasBackgroundImage, this.isPreviewWidget);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (isPreviewWidget) {
      return OTMentionPreviewWidget(
        id: int.parse(element.textContent),
        type: OTMentionType.FLOOR,
        hasBackgroundImage: hasBackgroundImage,
      );
    } else {
      return OTFloorMentionWidget(
        future: ForumRepository.getInstance()
            .loadFloorById(int.parse(element.textContent)),
        hasBackgroundImage: hasBackgroundImage,
      );
    }
  }
}

class MarkdownHoleMentionSupport extends MarkdownElementBuilder {
  static const String tag = "holeMention";

  final bool hasBackgroundImage;
  final bool isPreviewWidget;

  MarkdownHoleMentionSupport(this.hasBackgroundImage, this.isPreviewWidget);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (isPreviewWidget) {
      return OTMentionPreviewWidget(
        id: int.parse(element.textContent),
        type: OTMentionType.HOLE,
        hasBackgroundImage: hasBackgroundImage,
      );
    } else {
      return OTFloorMentionWidget(
        future: ForumRepository.getInstance()
            .loadHoleById(int.parse(element.textContent))
            .then((value) => value?.floors?.first_floor),
        hasBackgroundImage: hasBackgroundImage,
      );
    }
  }
}

class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(?<!\$)\$([^\$]+?)\$(?!\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    var tex = match[1]!;
    parser.addNode(md.Element.text(MarkdownLatexSupport.tag, tex));
    return true;
  }
}

class LatexMultiLineSyntax extends md.InlineSyntax {
  LatexMultiLineSyntax() : super(r'\$\$([^\$]*?)\$\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    var tex = match[1]!;
    parser.addNode(md.Element(
        "p", [md.Element.text(MarkdownLatexMultiLineSupport.tag, tex)]));
    return true;
  }
}

class MentionSyntax extends md.InlineSyntax {
  MentionSyntax() : super(r'(#{1,2})([0-9]+)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final type = match[1]!;
    final mention = match[2]!;
    if (type == "#") {
      parser.addNode(md.Element.text(MarkdownHoleMentionSupport.tag, mention));
      return true;
    } else if (type == "##") {
      parser.addNode(md.Element.text(MarkdownFloorMentionSupport.tag, mention));
      return true;
    }
    return false;
  }
}

class AuditSyntax extends md.InlineSyntax {
  AuditSyntax() : super(r'<audit>([^\$]*?)</audit>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    var sensitiveString = match[1]!;
    parser.addNode(md.Element.text("mark", sensitiveString));
    return true;
  }
}
