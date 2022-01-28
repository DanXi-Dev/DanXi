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
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

/// The base class of subpages showing in [HomePage].
///
/// It is equipped with a callback to help the implementation know when its state changes.
abstract class PlatformSubpage extends StatefulWidget {
  const PlatformSubpage({Key? key}) : super(key: key);

  @deprecated
  final bool needPadding = false;
  @deprecated
  final bool needBottomPadding = false;

  Create<Widget> get title;

  Create<List<AppBarButtonItem>> get leading => (_) => [];

  Create<List<AppBarButtonItem>> get trailing => (_) => [];

  void onDoubleTapOnTab() {}

  @mustCallSuper
  void onViewStateChanged(SubpageViewState state) {}
}

abstract class PlatformSubpageState<T extends PlatformSubpage>
    extends State<T> {
  Widget buildPage(BuildContext context);

  @override
  Widget build(BuildContext context) {
    // Build action buttons.
    PlatformIconButton? leadingButton;
    List<PlatformIconButton> trailingButtons = [];
    List<AppBarButtonItem> leadingItems = widget.leading.call(context);
    List<AppBarButtonItem> trailingItems = widget.trailing.call(context);

    if (leadingItems.isNotEmpty) {
      leadingButton = PlatformIconButton(
        material: (_, __) =>
            MaterialIconButtonData(tooltip: leadingItems.first.caption),
        padding: EdgeInsets.zero,
        icon: leadingItems.first.widget,
        onPressed: leadingItems.first.onPressed,
      );
    }

    if (trailingItems.isNotEmpty) {
      trailingButtons = trailingItems
          .map((e) => PlatformIconButton(
              material: (_, __) => MaterialIconButtonData(tooltip: e.caption),
              padding: EdgeInsets.zero,
              icon: e.widget,
              onPressed: e.onPressed))
          .toList();
    }
    return PlatformScaffold(
        iosContentBottomPadding: widget.needBottomPadding,
        iosContentPadding: widget.needPadding,
        appBar: PlatformAppBar(
          cupertino: (_, __) => CupertinoNavigationBarData(
            title: MediaQuery(
                data: MediaQueryData(
                    textScaleFactor: MediaQuery.textScaleFactorOf(context)),
                child: TopController(child: widget.title(context))),
          ),
          material: (_, __) => MaterialAppBarData(
              title: TopController(child: widget.title(context))),
          leading: leadingButton,
          trailingActions: trailingButtons,
        ),
        body: Builder(builder: buildPage));
  }
}

class AppBarButtonItem {
  final String caption;
  final Widget widget;
  final VoidCallback onPressed;

  AppBarButtonItem(this.caption, this.widget, this.onPressed);
}

enum SubpageViewState { VISIBLE, INVISIBLE }
