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

import 'dart:math';

import 'package:dan_xi/provider/forum_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FullScreenWatermark extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final TextStyle textStyle;

  const FullScreenWatermark({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: _createColumnWidgets(),
      ),
    );
  }

  List<Widget> _createColumnWidgets() {
    List<Widget> list = [];
    for (var i = 0; i < columnCount; i++) {
      final widget = Expanded(
          child: Row(
        children: _createRowWidgets(),
      ));
      list.add(widget);
    }
    return list;
  }

  List<Widget> _createRowWidgets() {
    List<Widget> list = [];
    for (var i = 0; i < rowCount; i++) {
      final widget = Expanded(
          child: Center(
              child: Transform.translate(
        offset: Offset(_getPositionNoise(), _getPositionNoise()),
        child: Transform.rotate(
            angle: pi / 10,
            child: Consumer<ForumProvider>(
              builder: (context, holeProvider, _) => Text(
                  holeProvider.userInfo?.user_id.toString() ?? " ",
                  style: textStyle),
            )),
      )));
      list.add(widget);
    }
    return list;
  }

  double _getPositionNoise() {
    Random rand = Random();
    return rand.nextDouble() * 4 * (rand.nextBool() ? 1 : -1);
  }
}
