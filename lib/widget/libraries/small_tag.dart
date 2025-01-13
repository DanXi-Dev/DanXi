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

/// SmallTag is a small tag, usually showing on the home page to visualize different data items.
/// Such as "Next course", "Last transaction", etc.
///
/// It uses [Theme.of(context).hintColor] as its background color, and
/// self-adaptive text color by default.
class SmallTag extends StatelessWidget {
  final String? label;

  const SmallTag({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha: 0.25),
          borderRadius: const BorderRadius.all(Radius.circular(4.0))),
      child: Text(
        label!,
        style: TextStyle(
            color: Theme.of(context).hintColor.computeLuminance() >= 0.5
                ? Colors.black
                : Colors.white,
            fontSize: 12),
      ),
    );
  }
}
