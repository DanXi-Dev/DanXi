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

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// An implementation of [Banner](https://material.io/components/banners).
class SlimMaterialBanner extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? actionName;
  final VoidCallback? onTapAction;
  final VoidCallback? onDismissed;
  final bool dismissible;

  const SlimMaterialBanner(
      {Key? key,
      this.icon,
      required this.title,
      this.actionName,
      this.onTapAction,
      this.dismissible = false,
      this.onDismissed})
      : assert(!dismissible || key != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget body = Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(width: 32, height: 32, child: icon)),
            Expanded(child: Text(title)),
            if (actionName != null)
              Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: PlatformTextButton(
                      child: Text(actionName!), onPressed: onTapAction))
          ],
        ),
      ),
    );
    if (dismissible) {
      return Dismissible(
        key: key ?? UniqueKey(),
        child: body,
        onDismissed: (_) => onDismissed?.call(),
      );
    } else {
      return body;
    }
  }
}
