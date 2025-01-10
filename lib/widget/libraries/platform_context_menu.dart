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
      {super.key, this.cancelButton, required this.actions});

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
      {super.key,
      required this.menuContext,
      this.onPressed,
      required this.child,
      this.isDestructive = false});

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

class PlatformPopupMenuX extends StatelessWidget {
  final List<PopupMenuOption> options;
  final Widget icon;

  final PlatformBuilder<CupertinoPopupMenuData>? cupertino;
  final PlatformBuilder<MaterialPopupMenuData>? material;

  const PlatformPopupMenuX({
    required this.options,
    required this.icon,
    this.cupertino,
    this.material,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (context, _) => _materialPopupMenuButton(context),
      cupertino: (context, _) => _cupertinoPopupBottomSheet(context),
    );
  }

  Widget _cupertinoPopupBottomSheet(BuildContext context) {
    return PlatformIconButton(
      onPressed: () {
        showPlatformModalSheet(
          context: context,
          builder: (context) => _cupertinoSheetContent(context),
        );
      },
      padding: EdgeInsets.zero,
      icon: icon,
    );
  }

  Widget _cupertinoSheetContent(BuildContext context) {
    final data = cupertino?.call(context, platform(context));
    final cancelData = data?.cancelButtonData;

    return CupertinoActionSheet(
      key: data?.key ?? key,
      title: data?.title,
      message: data?.message,
      actionScrollController: data?.actionScrollController,
      messageScrollController: data?.messageScrollController,
      actions: data?.actions ??
          options.map(
            (option) {
              final data = option.cupertino?.call(context, platform(context));
              return CupertinoActionSheetAction(
                key: data?.key,
                isDefaultAction: data?.isDefaultAction ?? false,
                isDestructiveAction: data?.isDestructiveAction ?? false,
                onPressed: data?.onPressed ??
                    () {
                      Navigator.pop(context);
                      option.onTap?.call(option);
                    },
                child: data?.child ?? Text(option.label ?? ""),
              );
            },
          ).toList(),
      cancelButton: cancelData == null
          ? null
          : CupertinoActionSheetAction(
              key: cancelData.key,
              isDefaultAction: cancelData.isDefaultAction ?? false,
              isDestructiveAction: cancelData.isDestructiveAction ?? false,
              onPressed: cancelData.onPressed ?? () => Navigator.pop(context),
              child: cancelData.child,
            ),
    );
  }

  Widget _materialPopupMenuButton(BuildContext context) {
    final data = material?.call(context, platform(context));

    return PopupMenuButton<PopupMenuOption>(
      onSelected: (option) {
        option.onTap?.call(option);
      },
      icon: data?.icon ?? icon,
      itemBuilder: data?.itemBuilder ??
          (context) => options.map(
                (option) {
                  final data =
                      option.material?.call(context, platform(context));
                  return PopupMenuItem(
                    value: option,
                    enabled: data?.enabled ?? true,
                    height: data?.height ?? kMinInteractiveDimension,
                    key: data?.key,
                    mouseCursor: data?.mouseCursor,
                    onTap: data?.onTap,
                    padding: data?.padding,
                    textStyle: data?.textStyle,
                    child: data?.child ?? Text(option.label ?? ""),
                  );
                },
              ).toList(),
      color: data?.color,
      elevation: data?.elevation,
      enableFeedback: data?.enableFeedback,
      enabled: data?.enabled ?? true,
      iconSize: data?.iconSize,
      initialValue: data?.initialValue,
      key: data?.key ?? key,
      offset: data?.offset ?? Offset.zero,
      onCanceled: data?.onCanceled,
      padding: data?.padding ?? const EdgeInsets.all(8.0),
      shape: data?.shape,
      child: data?.child,
    );
  }
}
