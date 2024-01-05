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

import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/widgets.dart';

/// A widget that listens to the double tap on its child,
/// controlling a [ScrollController] or calling [onDoubleTap] method to scroll to the top.
///
/// Usually wrap a [Text] widget in [PlatformAppBarX].
class TopController extends StatelessWidget {
  final Widget? child;
  final ScrollController? controller;
  final Function? onDoubleTap;

  const TopController(
      {super.key, this.controller, this.onDoubleTap, this.child});

  static scrollToTop(ScrollController? controller) =>
      controller?.animateTo(-controller.initialScrollOffset,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        final currentController =
            controller ?? PrimaryScrollController.of(context);
        TopController.scrollToTop(currentController);
        if (onDoubleTap != null) {
          onDoubleTap!.call();
        }
      },
      child: child,
    );
  }
}
