/*
 *     Copyright (C) 2022  DanXi-Dev
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

import 'dart:convert';

import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Check whether a text is legal markdown document.
class MarkdownChecker implements MarkdownBuilderDelegate {
  const MarkdownChecker();

  static bool checkGrammar(BuildContext context, String text) {
    bool goodGrammar = false;
    try {
      _parseMarkdown(context, text);
      goodGrammar = true;
    } catch (_) {}
    return goodGrammar;
  }

  /// A default style sheet generator.
  static final MarkdownStyleSheet Function(
      BuildContext, MarkdownStyleSheetBaseTheme?) kFallbackStyle = (
    BuildContext context,
    MarkdownStyleSheetBaseTheme? baseTheme,
  ) {
    MarkdownStyleSheet result;
    switch (baseTheme) {
      case MarkdownStyleSheetBaseTheme.platform:
        result = (PlatformX.isIOS || PlatformX.isMacOS)
            ? MarkdownStyleSheet.fromCupertinoTheme(CupertinoTheme.of(context))
            : MarkdownStyleSheet.fromTheme(Theme.of(context));
        break;
      case MarkdownStyleSheetBaseTheme.cupertino:
        result =
            MarkdownStyleSheet.fromCupertinoTheme(CupertinoTheme.of(context));
        break;
      case MarkdownStyleSheetBaseTheme.material:
      default:
        result = MarkdownStyleSheet.fromTheme(Theme.of(context));
    }

    return result.copyWith(
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
    );
  };

  static List<Widget> _parseMarkdown(BuildContext context, String text) {
    final MarkdownStyleSheet fallbackStyleSheet = kFallbackStyle(context, null);
    final MarkdownStyleSheet styleSheet = fallbackStyleSheet.merge(null);

    final md.Document document = md.Document(
      blockSyntaxes: null,
      inlineSyntaxes: <md.InlineSyntax>[TaskListSyntax()],
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );

    // Parse the source Markdown data into nodes of an Abstract Syntax Tree.
    final List<String> lines = const LineSplitter().convert(text);
    final List<md.Node> astNodes = document.parseLines(lines);

    // Configure a Markdown widget builder to traverse the AST nodes and
    // create a widget tree based on the elements.
    final MarkdownBuilder builder = MarkdownBuilder(
      delegate: const MarkdownChecker(),
      selectable: false,
      styleSheet: styleSheet,
      checkboxBuilder: null,
      bulletBuilder: null,
      builders: {},
      paddingBuilders: {},
      fitContent: true,
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.baseline,
      onTapText: null,
      softLineBreak: false,
      imageDirectory: null,
      imageBuilder: null,
    );

    return builder.build(astNodes);
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () {};
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    code = code.replaceAll(RegExp(r'\n$'), '');
    return TextSpan(style: styleSheet.code, text: code);
  }
}
