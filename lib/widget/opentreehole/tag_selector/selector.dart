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

import 'dart:math';

import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/tag.dart';
import 'package:flutter/material.dart';

/*
Originally by @hemantkhorwal on Github.
Refactor a lot.
Redistribute via License GPL 3.0 instead of MIT.

Copyright (c) 2020 Hemant Khorwal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
* */

/// A container of [ChoiceChip], allowing users to choose from a list of [Tag]s.
class TagContainer extends StatefulWidget {
  final List<Tag>? tagList;
  final bool fillRandomColor;
  final int? defaultChoice;
  final bool singleChoice;
  final Color? fixedColor;
  final Color? iconColor;
  final double? iconSize;
  final double? fontSize;
  final Function? onChoice;
  final bool enabled;
  final bool wrapped;

  const TagContainer(
      {Key? key,
      required this.tagList,
      required this.fillRandomColor,
      this.singleChoice = false,
      this.defaultChoice = 0,
      this.onChoice,
      this.fixedColor,
      this.iconColor,
      this.iconSize,
      this.fontSize,
      this.enabled = true,
      this.wrapped = true})
      : assert(
            fillRandomColor || (fillRandomColor == false && fixedColor != null),
            "fixedColor can't be empty."),
        super(key: key);

  @override
  _TagContainerState createState() => _TagContainerState();
}

class _TagContainerState extends State<TagContainer> {
  List<Tag>? tagList;
  late bool fillRandomColor;
  List<String?> selectedCategories = [];
  static const List<Color> _RANDOM_COLORS = [
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.blueGrey,
    Colors.lightGreen,
  ];
  double? iconSize;
  double? fontSize;
  Color? iconColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    tagList = widget.tagList;
    widget.iconColor == null
        ? iconColor = Colors.white
        : iconColor = widget.iconColor;
    widget.fontSize == null ? fontSize = 16 : fontSize = widget.fontSize;
    widget.iconSize == null ? iconSize = 22 : iconSize = widget.iconSize;
    if (widget.defaultChoice! >= 0 && tagList!.length > widget.defaultChoice!) {
      tagList![widget.defaultChoice!].isSelected = true;
    }
    fillRandomColor = widget.fillRandomColor;
    fillRandomColor
        ? randomColorApplier()
        : fixedColorApplier(widget.fixedColor);
    return ThemedMaterial(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: widget.wrapped
                ? Wrap(
                    spacing: 8,
                    children: tagList!.map((e) => _buildTag(e)).toList(),
                  )
                : SingleChildScrollView(
                    primary: false,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tagList!
                          .map((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: _buildTag(e)))
                          .toList(),
                    ),
                  )));
  }

  Widget _buildTag(Tag data) {
    Color? showingColor = data.isSelected ? data.tagColor : Colors.grey.shade50;
    return ChoiceChip(
        label: Text(
          data.tagTitle!,
          style: TextStyle(
              color: (showingColor?.computeLuminance() ?? 0) >= 0.5
                  ? Colors.black
                  : Colors.white),
        ),
        selected: data.isSelected,
        selectedColor: data.tagColor,
        // backgroundColor: data.tagColor?.withOpacity(0.5),
        avatar: data.icon != null ? Icon(data.icon) : null,
        // When [widget.enabled] is false, set [onSelected] to null so that this chip will act as disabled.
        onSelected: widget.enabled
            ? (bool newValue) {
                if (!widget.enabled) return;
                if (data.isSelected && widget.singleChoice) return;
                setState(() {
                  data.isSelected = !data.isSelected;
                  if (data.isSelected && widget.singleChoice) {
                    selectedCategories.clear();
                    for (var element in tagList!) {
                      element.isSelected = false;
              }
              data.isSelected = true;
            }
            data.isSelected
                ? selectedCategories.add(data.tagTitle)
                : selectedCategories.remove(data.tagTitle);
          });
          if (data.isSelected && widget.onChoice != null) {
            widget.onChoice!(data, selectedCategories);
          }
        }
            : null);
  }

  int generateRandom(int old) {
    int newRandom = Random().nextInt(_RANDOM_COLORS.length - 1);
    if (old == newRandom) {
      generateRandom(old);
    }
    return newRandom;
  }

  void randomColorApplier() {
    int temp = _RANDOM_COLORS.length + 1;
    for (int i = 0; i <= tagList!.length - 1; i++) {
      temp = generateRandom(temp);
      tagList![i].tagColor = (_RANDOM_COLORS[temp]);
    }
  }

  fixedColorApplier(Color? fixedColor) {
    // for (int i = 0; i <= tagList.length - 1; i++) {
    //   tagList[i].tagColor = fixedColor;
    // }
    for (var element in tagList!) {
      element.tagColor = fixedColor;
    }
  }
}
