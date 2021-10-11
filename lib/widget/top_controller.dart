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

import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:flutter/widgets.dart';

/// A widget that listens to the double tap on its child,
/// controlling a [ScrollController] or calling [onDoubleTap] method to scroll to the top.
///
/// Usually wrap a [Text] widget in [PlatformAppBarX].
class TopController extends StatefulWidget {
  final Widget? child;
  final ScrollController? controller;
  final Function? onDoubleTap;

  const TopController({Key? key, this.controller, this.onDoubleTap, this.child})
      : super(key: key);

  static scrollToTop(ScrollController? controller) => controller?.animateTo(0,
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
          widget.onDoubleTap!();
        }
      },
      child: widget.child,
    );
  }
}

/// An event to notify the sub page to scroll its listview.
class ScrollToTopEvent {}
