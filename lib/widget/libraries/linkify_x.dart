/*
 *     Copyright (C) 2023  DanXi-Dev
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

import 'package:dan_xi/common/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

/// [Linkify] with a default link theme.
///
/// It is sad that [Linkify] hardcoded the link style in its source code, so we
/// have to create a new class to override it.
class LinkifyX extends Linkify {
  const LinkifyX({
    Key? key,
    required String text,
    void Function(LinkableElement)? onOpen,
    TextAlign textAlign = TextAlign.start,
    double textScaleFactor = 1.0,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
    TextStyle? style,
  }) : super(
          key: key,
          text: text,
          linkStyle: Constant.LINKIFY_THEME,
          onOpen: onOpen,
          textAlign: textAlign,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          overflow: overflow,
          style: style,
        );
}

class SelectableLinkifyX extends SelectableLinkify {
  const SelectableLinkifyX({
    Key? key,
    required String text,
    void Function(LinkableElement)? onOpen,
    TextAlign textAlign = TextAlign.start,
    double textScaleFactor = 1.0,
    int? maxLines,
    TextStyle? style,
  }) : super(
          key: key,
          text: text,
          linkStyle: Constant.LINKIFY_THEME,
          onOpen: onOpen,
          textAlign: textAlign,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          style: style,
        );
}
