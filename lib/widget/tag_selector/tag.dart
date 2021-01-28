import 'package:flutter/material.dart';

class Tag {
  final String tagTitle;
  final IconData developerDefinedIcon;
  IconData checkedIcon;
  bool isSelected = false;
  Color tagColor;

  IconData get icon => isSelected ? checkedIcon : developerDefinedIcon;

  Tag(this.tagTitle, this.developerDefinedIcon,
      {this.checkedIcon = Icons.check})
      : assert(tagTitle != null && developerDefinedIcon != null);
}
