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

/// A round chip, usually used as a tag, to match the tag widget of fduhole's web style.
class RoundChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const RoundChip({Key key, this.label, this.onTap, this.color})
      : super(key: key);

  @override
  _RoundChipState createState() => _RoundChipState();
}

class _RoundChipState extends State<RoundChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.color,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          widget.label,
          style: TextStyle(fontSize: 14, color: widget.color),
        ),
      ),
    );
  }
}
