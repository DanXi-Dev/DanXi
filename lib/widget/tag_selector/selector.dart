import 'dart:math';

import 'package:dan_xi/widget/tag_selector/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/*
Originally by @hemantkhorwal on Github.
Refactor a lot.
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
      this.fontSize})
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
  void initState() {
    super.initState();
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
        : fixedColorApplyer(widget.fixedColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Wrap(
        children: tagList.map((e) => _buildTag(e)).toList(),
      ),
    );
  }

  Container _buildTag(Tag data) {
    return Container(
        margin: const EdgeInsets.only(right: 8.0, bottom: 15.0),
        decoration: BoxDecoration(
          color: data.tagColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Material(
          borderRadius: BorderRadius.circular(50),
          color: data.tagColor,
          child: InkWell(
            onTap: () {
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
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  padding: const EdgeInsets.all(4.0),
                  duration: Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white60,
                  ),
                  child: new Icon(
                    data.icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0, right: 10.0),
                  child: Text(
                    data.tagTitle,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize),
                  ),
                ),
              ],
            ),
          ),
        ));
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

  fixedColorApplyer(Color fixedColor) {
    // for (int i = 0; i <= tagList.length - 1; i++) {
    //   tagList[i].tagColor = fixedColor;
    // }
    tagList.forEach((element) => element.tagColor = fixedColor);
  }
}
