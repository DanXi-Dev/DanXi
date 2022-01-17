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

import 'package:dan_xi/util/scroller_fix/mirror_scroll_controller.dart';
import 'package:flutter/cupertino.dart';

mixin PageWithPrimaryScrollController {
  MirrorScrollController? _thisPrimaryScrollController;

  String? get debugTag => null;

  bool shown = true;

  MirrorScrollController primaryScrollController(BuildContext context) {
    if (_thisPrimaryScrollController == null) {
      _thisPrimaryScrollController = MirrorScrollController(
          PrimaryScrollController.of(context), context,
          debugTag: debugTag);
      _thisPrimaryScrollController!.addInterceptor(() => shown);
    }
    return _thisPrimaryScrollController!;
  }

  void detachItself() {
    shown = false;
    _thisPrimaryScrollController?.detachPosition.call();
  }

  void reattachItself() {
    shown = true;
    _thisPrimaryScrollController?.reattachPosition.call();
  }
}
