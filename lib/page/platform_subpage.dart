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

import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/util/scroller_fix/primary_scroll_page.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// The base class of subpages showing in [HomePage].
///
/// It is equipped with a callback to help the implementation know when its state changes.
abstract class PlatformSubpage extends StatefulWidget {
  @deprecated
  final bool needPadding = false;
  @deprecated
  final bool needBottomPadding = false;

  Create<Widget> get title;

  Create<List<AppBarButtonItem>> get leading => (_) => [];

  Create<List<AppBarButtonItem>> get trailing => (_) => [];

  @mustCallSuper
  void onViewStateChanged(SubpageViewState state) {
    if (this is PageWithPrimaryScrollController) {
      switch (state) {
        case SubpageViewState.VISIBLE:
          (this as PageWithPrimaryScrollController).reattachItself();
          break;
        case SubpageViewState.INVISIBLE:
          (this as PageWithPrimaryScrollController).detachItself();
          break;
      }
    }
  }
}

class AppBarButtonItem {
  final String caption;
  final Widget widget;
  final VoidCallback onPressed;

  AppBarButtonItem(this.caption, this.widget, this.onPressed);
}

enum SubpageViewState { VISIBLE, INVISIBLE }
