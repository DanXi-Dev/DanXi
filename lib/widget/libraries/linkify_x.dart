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
    super.key,
    required super.text,
    super.onOpen,
    super.textAlign,
    super.textScaleFactor,
    super.maxLines,
    TextOverflow super.overflow,
    super.style,
  }) : super(
          linkStyle: Constant.LINKIFY_THEME,
        );
}

class SelectableLinkifyX extends SelectableLinkify {
  const SelectableLinkifyX({
    super.key,
    required super.text,
    super.onOpen,
    TextAlign super.textAlign = TextAlign.start,
    super.textScaleFactor,
    super.maxLines,
    super.style,
  }) : super(
          linkStyle: Constant.LINKIFY_THEME,
        );
}
