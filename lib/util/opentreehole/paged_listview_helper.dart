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

import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:flutter/cupertino.dart';

class PagedListViewHelper {
  static StopScrollJudge _defaultStopDecider<T>(
          PagedListViewController<T> pagedListViewController,
          ScrollDirection direction,
          int firstPageItemCount) =>
      () {
        switch (direction) {
          case ScrollDirection.UP:
            return pagedListViewController.getScrollController()!.offset <
                firstPageItemCount;
          case ScrollDirection.DOWN:
            return (pagedListViewController
                            .getScrollController()
                            ?.position
                            .extentAfter ??
                        0) <
                    10 &&
                pagedListViewController.isEnded;
        }
      };

  static Future<bool> scrollToItem<T>(
      BuildContext context,
      PagedListViewController<T> pagedListViewController,
      T objectItem,
      ScrollDirection direction,
      {int firstPageItemCount = 1,
      StopScrollJudge? stopScrollJudge}) async {
    stopScrollJudge ??= _defaultStopDecider(
        pagedListViewController, direction, firstPageItemCount);

    final scrollHeight = ViewportUtils.getViewportHeight(context);
    while (!(await pagedListViewController.scrollToItem(objectItem))) {
      if (stopScrollJudge.call()) {
        return false;
      }
      await pagedListViewController.scrollDelta(
          direction == ScrollDirection.UP ? -scrollHeight : scrollHeight,
          const Duration(milliseconds: 1),
          Curves.linear);
    }
    return true;
  }
}

typedef StopScrollJudge = bool Function();
enum ScrollDirection { UP, DOWN }
