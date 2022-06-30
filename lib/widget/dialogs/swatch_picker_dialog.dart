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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

/// A dialog allowing user to choose a swatch color from the list [Constant.TAG_COLOR_LIST].
class SwatchPickerDialog extends StatefulWidget {
  final int initialSelectedColor;

  const SwatchPickerDialog({Key? key, required this.initialSelectedColor})
      : super(key: key);

  @override
  State<SwatchPickerDialog> createState() => _SwatchPickerDialogState();
}

class _SwatchPickerDialogState extends State<SwatchPickerDialog> {
  //To create [currentSelected] and [finalSelected] is a temporary solution to a curious bug.
  late MaterialColor _currentSelected;
  late MaterialColor _finalSelected;

  @override
  void initState() {
    super.initState();
    _currentSelected = _intToMaterialColor(widget.initialSelectedColor);
    _finalSelected = _currentSelected;
  }

  //shared_preferences cannot store [Color] or [MaterialColor], so we have to do a
  //transformation here.
  MaterialColor _intToMaterialColor(int color) {
    return MaterialColor(
      color,
      <int, Color>{
        50: Color(color),
        100: Color(color),
        200: Color(color),
        300: Color(color),
        400: Color(color),
        500: Color(color),
        600: Color(color),
        700: Color(color),
        800: Color(color),
        900: Color(color),
      },
    );
  }

  void materialColorGenerator(Color color) {
    _currentSelected = MaterialColor(
      color.value,
      <int, Color>{
        50: Color(color.value),
        100: Color(color.value),
        200: Color(color.value),
        300: Color(color.value),
        400: Color(color.value),
        500: Color(color.value),
        600: Color(color.value),
        700: Color(color.value),
        800: Color(color.value),
        900: Color(color.value),
      },
    );
  }

  void onWheel(bool oprated) {
    _finalSelected = _currentSelected;
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: ListTile(
        title: Text(S.of(context).theme_color),
        subtitle: Text(S.of(context).theme_color_description_detail),
      ),
      actions: [
        PlatformDialogAction(
            child: Text(S.of(context).ok),
            onPressed: () => Navigator.pop(context, _finalSelected)),
        PlatformDialogAction(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.pop(context, null))
      ],
      content: Column(
        children: [
          Expanded(
            flex: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: Constant.TAG_COLOR_LIST
                      .map((e) => GestureDetector(
                            onTap: () => setState(() =>
                                _finalSelected = Constant.getColorFromString(e)),
                            child: CircleAvatar(
                              backgroundColor: Constant.getColorFromString(e),
                              child:
                                  _finalSelected == Constant.getColorFromString(e)
                                      ? const Icon(Icons.done)
                                      : null,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ColorWheelPicker(
              color: _currentSelected,
              onChanged: materialColorGenerator,
              onWheel: onWheel,
            ),
          )
        ],
      ),
    );
  }
}
