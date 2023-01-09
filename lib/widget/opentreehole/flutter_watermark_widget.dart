import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:provider/provider.dart';

class FullScreenWatermark extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final TextStyle textStyle;

  const FullScreenWatermark({
    Key? key,
    required this.rowCount,
    required this.columnCount,
    required this.textStyle,
  }) : super(key: key);

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
              child: Transform.rotate(
                  angle: pi / 10, child: Consumer<FDUHoleProvider>(
                builder: (context, holeProvider, _) => Text(holeProvider.userInfo?.user_id.toString() ?? " ", style: textStyle),
              ))));
      list.add(widget);
    }
    return list;
  }
}