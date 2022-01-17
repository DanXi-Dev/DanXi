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

/// A container of [Material] that applies the app's theme settings on it.
///
/// Use it anywhere you need a [Material].
class ThemedMaterial extends StatefulWidget {
  final Widget child;

  const ThemedMaterial({Key key, this.child}) : super(key: key);

  @override
  _ThemedMaterialState createState() => _ThemedMaterialState();
}

class _ThemedMaterialState extends State<ThemedMaterial> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: widget.child,
    );
  }
}
