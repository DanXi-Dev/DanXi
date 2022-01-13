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

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A simple error page, usually shown as full-screen.
class ErrorPageWidget extends StatefulWidget {
  final Widget? icon;
  final String buttonText;
  final String errorMessage;
  final VoidCallback? onTap;

  const ErrorPageWidget(
      {Key? key,
      this.icon,
      required this.buttonText,
      required this.errorMessage,
      this.onTap})
      : super(key: key);

  @override
  _ErrorPageWidgetState createState() => _ErrorPageWidgetState();
}

class _ErrorPageWidgetState extends State<ErrorPageWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) widget.icon!,
          if (widget.icon != null)
            const SizedBox(
              height: 8,
            ),
          Text(widget.errorMessage),
          const SizedBox(
            height: 8,
          ),
          PlatformElevatedButton(
            child: Text(widget.buttonText),
            onPressed: widget.onTap,
          )
        ],
      ),
    );
  }
}
