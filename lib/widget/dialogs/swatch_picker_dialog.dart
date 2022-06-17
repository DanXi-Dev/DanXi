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

/// A dialog allowing user to choose a swatch color from the list [Constant.TAG_COLOR_LIST].
class SwatchPickerDialog extends StatefulWidget {
  final String initialSelectedColor;

  const SwatchPickerDialog({Key? key, required this.initialSelectedColor})
      : super(key: key);

  @override
  State<SwatchPickerDialog> createState() => _SwatchPickerDialogState();
}

class _SwatchPickerDialogState extends State<SwatchPickerDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      actions: [
        PlatformDialogAction(
            child: Text(S.of(context).ok),
            onPressed: () => Navigator.pop(context, _selected)),
        PlatformDialogAction(
            child: Text(S.of(context).cancel),
            onPressed: () => Navigator.pop(context, null))
      ],
      content: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: Constant.TAG_COLOR_LIST
            .map((e) => GestureDetector(
                  onTap: () => setState(() => _selected = e),
                  child: CircleAvatar(
                    backgroundColor: Constant.getColorFromString(e),
                    child: _selected == e ? const Icon(Icons.done) : null,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
