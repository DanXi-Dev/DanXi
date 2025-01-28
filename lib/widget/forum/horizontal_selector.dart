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

const kDuration = Duration(milliseconds: 300);
const kCurve = Curves.fastLinearToSlowEaseIn;

class HorizontalSelector<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedOption;
  final void Function(T)? onSelect;

  const HorizontalSelector(
      {super.key,
      required this.options,
      this.onSelect,
      required this.selectedOption});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: options.map((e) {
          return Builder(builder: (context) {
            if (selectedOption == e) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                Scrollable.ensureVisible(context,
                    duration: kDuration,
                    curve: kCurve,
                    alignment: 0.0,
                    alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
              });
            }
            return GestureDetector(
              child: Padding(
                // Note: place [Padding] inside [GestureDetector] to improve user's chance of hitting the option
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  e.toString(),
                  textScaler:
                      TextScaler.linear(selectedOption == e ? 1.25 : 1.0),
                  style: TextStyle(
                      color: selectedOption == e
                          ? null
                          : Theme.of(context).hintColor),
                ),
              ),
              onTap: () {
                onSelect?.call(e);
              },
            );
          });
        }).toList(),
      ),
    );
  }
}
