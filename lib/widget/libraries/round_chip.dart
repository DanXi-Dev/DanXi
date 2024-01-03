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

import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';

/// A round chip, usually used as a tag, to match the tag widget of fduhole's web style.
class RoundChip extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;
  final Color? color;

  const RoundChip({super.key, this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(
                color: effectiveColor,
                width: 1,
              ),
              color:
                  PlatformX.isDarkMode ? effectiveColor.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                label ?? "",
                style: TextStyle(
                    fontSize: 14,
                    leadingDistribution: TextLeadingDistribution.even,
                    color:
                        PlatformX.isDarkMode ? Colors.white : effectiveColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
