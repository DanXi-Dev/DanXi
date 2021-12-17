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

import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/opentreehole/auto_bbs_image.dart';
import 'package:dan_xi/widget/opentreehole/render/base_render.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

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

BaseRender kMarkdownRender = (BuildContext context, String? content,
    ImageTapCallback? onTapImage, LinkTapCallback? onTapLink) {
  double imageWidth = ViewportUtils.getMainNavigatorWidth(context) * 0.75;

  return MarkdownBody(
    softLineBreak: true,
    selectable: true,
    data: content!,
    styleSheet: _fontSizeOverride(
        _getMarkdownStyleSheetFromPlatform(context), kFontSize),
    onTapLink: (String text, String? href, String title) =>
        onTapLink?.call(href),
    inlineSyntaxes: [LatexSyntax(), LatexMultiLineSyntax(), MentionSyntax()],
    builders: {
      'tex': MarkdownLatexSupport(),
      'texLine': MarkdownLatexMultiLineSupport(),
      'floor_mention': MarkdownFloorMentionSupport(),
      'hole_mention': MarkdownHoleMentionSupport(),
    },
    imageBuilder: (Uri uri, String? title, String? alt) {
      return Center(
        child: AutoBBSImage(
            src: uri.toString(), maxWidth: imageWidth, onTapImage: onTapImage),
      );
    },
  );
};

class MarkdownLatexSupport extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Math.tex(element.textContent);
  }
}

class MarkdownLatexMultiLineSupport extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [Math.tex(element.textContent)],
    );
  }
}

class MarkdownFloorMentionSupport extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return OTFloorMentionWidget(
        future: OpenTreeHoleRepository.getInstance()
            .loadSpecificFloor(int.parse(element.textContent)));
  }
}

class MarkdownHoleMentionSupport extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return OTFloorMentionWidget(
        future: OpenTreeHoleRepository.getInstance()
            .loadSpecificHole(int.parse(element.textContent))
            .then((value) => value.floors!.first_floor!));
  }
}

BaseRender kMarkdownSelectorRender = (BuildContext context, String? content,
    ImageTapCallback? onTapImage, LinkTapCallback? onTapLink) {
  return Markdown(
    softLineBreak: true,
    selectable: true,
    data: content!,
    styleSheet: _fontSizeOverride(
        _getMarkdownStyleSheetFromPlatform(context), kFontLargerSize),
    onTapLink: (String text, String? href, String title) =>
        onTapLink?.call(href),
    imageBuilder: (Uri uri, String? title, String? alt) => const SizedBox(),
  );
};

class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(?<!\$)\$([^\$]+?)\$(?!\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    var tex = match[1]!;
    parser.addNode(md.Element.text("tex", tex));
    return true;
  }
}

class LatexMultiLineSyntax extends md.InlineSyntax {
  LatexMultiLineSyntax() : super(r'\$\$([^\$]*?)\$\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    var tex = match[1]!;
    parser.addNode(md.Element.empty("br"));
    parser.addNode(md.Element.text("texLine", tex));
    parser.addNode(md.Element.empty("br"));
    return true;
  }
}

const MENTION_REGEX_STRING = r'(#{1,2})([0-9]+)';

class MentionSyntax extends md.InlineSyntax {
  MentionSyntax() : super(MENTION_REGEX_STRING);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final type = match[1]!;
    final mention = match[2]!;
    if (type == "#") {
      parser.addNode(md.Element.text("hole_mention", mention));
      return true;
    } else if (type == "##") {
      parser.addNode(md.Element.text("floor_mention", mention));
      return true;
    }
    return false;
  }
}
