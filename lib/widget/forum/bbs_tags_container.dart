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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:flutter/cupertino.dart';

/// A wrapped container for [OTTag].
class BBSTagsContainer extends StatefulWidget {
  final List<OTTag>? tags;
  final OnTapTag? onTap;

  const BBSTagsContainer({super.key, required this.tags, this.onTap});

  @override
  BBSTagsContainerState createState() => BBSTagsContainerState();
}

class BBSTagsContainerState extends State<BBSTagsContainer> {
  final FocusNode _searchFocus = FocusNode();
  List<OTTag>? filteredTags;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        if (_searchFocus.hasFocus) _searchFocus.unfocus();
      },
      child: Column(
        children: [
          CupertinoSearchTextField(
            focusNode: _searchFocus,
            onChanged: (filter) {
              setState(() {
                filteredTags = widget.tags!
                    .where((value) => value.name!
                        .toLowerCase()
                        .contains(filter.toLowerCase()))
                    .toList();
              });
            },
          ),
          Wrap(
              children: (filteredTags ?? widget.tags)!
                  .map(
                    (e) => Padding(
                        padding: const EdgeInsets.only(top: 16, right: 12),
                        child: RoundChip(
                            label: Constant.withZwb(e.name),
                            color: e.color,
                            onTap: () => widget.onTap?.call(e))),
                  )
                  .toList())
        ],
      ),
    );
  }
}

typedef OnTapTag = void Function(OTTag tag);
