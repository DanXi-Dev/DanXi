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

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

class TopController extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Function onDoubleTap;

  const TopController({Key key, this.controller, this.onDoubleTap, this.child})
      : super(key: key);

  static scrollToTop(ScrollController controller) => controller?.animateTo(0,
      duration: Duration(milliseconds: 300), curve: Curves.easeInOut);

  @override
  _TopControllerState createState() => _TopControllerState();
}

class _TopControllerState extends State<TopController> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        TopController.scrollToTop(widget.controller);
        if (widget.onDoubleTap != null) {
          widget.onDoubleTap();
        }
      },
      child: widget.child,
    );
  }
}

/// An event to notify the sub page to scroll its listview.
class ScrollToTopEvent {}
