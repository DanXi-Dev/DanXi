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
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/material.dart';

// A chip widget, usually used as a tag
abstract class ChipWidget extends StatelessWidget {
  final String? label;
  final VoidCallback? onTap;
  final Color? color;

  const ChipWidget({super.key, this.label, this.onTap, this.color});
}

// Clip for the leading tags in the forum, ignores `onTap`
class LeadingChip extends ChipWidget {
  const LeadingChip(
      {super.key, super.label = "LZ", super.onTap, required super.color});

  @override
  Widget build(BuildContext context) {
    final container = Container(
      //height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: color!.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.all(Radius.circular(2.0))),
      child: Text(
        label!,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color!.withValues(alpha: 0.8).computeLuminance() <= 0.5
                ? Colors.white
                : Colors.black,
            fontSize: 12),
      ),
    );

    if (onTap == null) {
      return container;
    } else {
      return GestureDetector(onTap: onTap, child: container);
    }
  }
}

/// A rectangular chip to match the style of the swift version of the forum.
class RectangularChip extends ChipWidget {
  /// Is the chip highlighted?
  ///
  /// If true, the chip will have a gradient background and [color] will be ignored.
  final bool highlighted;

  const RectangularChip({super.key, super.label, super.onTap, super.color, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final lightness = HSLColor.fromColor(effectiveColor).lightness;
    BoxDecoration backgroundDecor;
    Color textColor;
    if (highlighted) {
      backgroundDecor = BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.9),
            Colors.purple.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(2),
      );
      textColor = Colors.white;
    } else {
      backgroundDecor = BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      );
      // Make text brighter under dark mode, and darker under light mode
      textColor = PlatformX.isDarkMode
          ? effectiveColor
          .withLightness((lightness + 0.2).clamp(0, 1))
          : effectiveColor
          .withLightness((lightness - 0.2).clamp(0, 1));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: backgroundDecor,
              child: Center(
                child: Text(
                  label ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    leadingDistribution: TextLeadingDistribution.even,

                    color: textColor,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

/// A round chip to match the style of the website version of the forum.
class RoundChip extends ChipWidget {
  const RoundChip({super.key, super.label, super.onTap, super.color});

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
                  PlatformX.isDarkMode ? effectiveColor.withValues(alpha: 0.3) : null,
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
