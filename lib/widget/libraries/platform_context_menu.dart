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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformContextMenu extends StatelessWidget {
  final Widget? cancelButton;
  final List<Widget> actions;

  const PlatformContextMenu(
      {Key? key, this.cancelButton, required this.actions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
        cupertino: (_, __) => CupertinoActionSheet(
              actions: actions,
              cancelButton: cancelButton,
            ),
        material: (_, __) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: actions,
              ),
            ));
  }
}

class PlatformContextMenuItem extends StatelessWidget {
  final BuildContext? menuContext;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final Widget child;

  const PlatformContextMenuItem(
      {Key? key,
      this.menuContext,
      this.onPressed,
      required this.child,
      this.isDestructive = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      cupertino: (_, __) => CupertinoActionSheetAction(
        onPressed: () {
          if (menuContext != null) Navigator.of(menuContext!).pop();
          onPressed?.call();
        },
        isDestructiveAction: isDestructive,
        child: child,
      ),
      material: (_, __) => ListTile(
        textColor: isDestructive ? Colors.red : null,
        title: child,
        onTap: () async {
          if (menuContext != null) Navigator.of(menuContext!).pop();
          onPressed?.call();
        },
      ),
    );
  }
}
