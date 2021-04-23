/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/tag_selector/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
class TagContainer extends StatefulWidget {
  final List<Tag> tagList;
  final bool fillRandomColor;
  final int defaultChoice;
  final bool singleChoice;
  final Color fixedColor;
  final Color iconColor;
  final double iconSize;
  final double fontSize;
  final Function onChoice;
  final bool enabled;
  final bool wrapped;

  TagContainer(
      {Key key,
      @required this.tagList,
      @required this.fillRandomColor,
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
            "fixedColor can't be empty.");

  @override
  _TagContainerState createState() => _TagContainerState();
}

class _TagContainerState extends State<TagContainer> {
  List<Tag> tagList;
  bool fillRandomColor;
  List<String> selectedCategories = [];
  static const List<Color> _RANDOM_COLORS = [
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.lightBlueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.blueGrey,
    Colors.lightGreen,
  ];
  double iconSize;
  double fontSize;
  Color iconColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    this.tagList = widget.tagList;
    widget.iconColor == null
        ? this.iconColor = Colors.white
        : this.iconColor = widget.iconColor;
    widget.fontSize == null
        ? this.fontSize = 16
        : this.fontSize = widget.fontSize;
    widget.iconSize == null
        ? this.iconSize = 22
        : this.iconSize = widget.iconSize;
    if (widget.defaultChoice >= 0 &&
        this.tagList.length > widget.defaultChoice) {
      tagList[widget.defaultChoice].isSelected = true;
    }
    this.fillRandomColor = widget.fillRandomColor;
    fillRandomColor
        ? randomColorApplier()
        : fixedColorApplier(widget.fixedColor);
    if (widget.wrapped) {
      return ThemedMaterial(
          child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Wrap(
                spacing: 8,
                children: tagList.map((e) => _buildTag(e)).toList(),
              )));
    } else
      return ThemedMaterial(
          child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tagList.map((e) => _buildTag(e)).toList(),
                ),
              )));
  }

  Widget _buildTag(Tag data) {
    return ChoiceChip(
        label: Text(data.tagTitle),
        selected: data.isSelected,
        avatar: Icon(data.icon),
        // When [widget.enabled] is false, set [onSelected] to null so that this chip will act as disabled.
        onSelected: widget.enabled
            ? (bool newValue) {
                if (!widget.enabled) return;
                if (data.isSelected && widget.singleChoice) return;
                setState(() {
                  data.isSelected = !data.isSelected;
                  if (data.isSelected && widget.singleChoice) {
                    selectedCategories.clear();
                    tagList.forEach((element) => element.isSelected = false);
                    data.isSelected = true;
                  }
                  data.isSelected
                      ? selectedCategories.add(data.tagTitle)
                      : selectedCategories.remove(data.tagTitle);
                });
                if (data.isSelected && widget.onChoice != null) {
                  widget.onChoice(data, selectedCategories);
                }
              }
            : null);
  }

  int generateRandom(int old) {
    int newRandom = new Random().nextInt(_RANDOM_COLORS.length - 1);
    if (old == newRandom) {
      generateRandom(old);
    }
    return newRandom;
  }

  void randomColorApplier() {
    int temp = _RANDOM_COLORS.length + 1;
    for (int i = 0; i <= tagList.length - 1; i++) {
      temp = generateRandom(temp);
      tagList[i].tagColor = (_RANDOM_COLORS[temp]);
    }
  }

  fixedColorApplier(Color fixedColor) {
    // for (int i = 0; i <= tagList.length - 1; i++) {
    //   tagList[i].tagColor = fixedColor;
    // }
    tagList.forEach((element) => element.tagColor = fixedColor);
  }
}
