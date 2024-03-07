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

import 'package:flutter/widgets.dart';

/// A widget that will scale its child at specific scale.
class ScaleTransform extends StatelessWidget {
  final Widget? child;
  final double? scale;

  const ScaleTransform({super.key, this.scale, this.child});

  @override
  Widget build(BuildContext context) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(scale, scale, 1.0),
      child: child);
}
