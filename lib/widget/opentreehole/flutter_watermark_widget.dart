import 'package:flutter/material.dart';
import 'dart:math';

class DisableScreenshotsWatermark extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final String text;
  final TextStyle textStyle;

  const DisableScreenshotsWatermark({
    Key? key,
    required this.rowCount,
    required this.columnCount,
    required this.text,
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
                  angle: pi / 10, child: Text(text, style: textStyle))));
      list.add(widget);
    }
    return list;
  }
}