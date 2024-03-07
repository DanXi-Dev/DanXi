/*
 *     Copyright (C) 2023  DanXi-Dev
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

import 'package:dan_xi/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class CourseSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final void Function(bool)? onFocusChanged;

  const CourseSearchBar(
      {super.key, required this.onSearch, this.onFocusChanged});

  @override
  _CourseSearchBarState createState() => _CourseSearchBarState();
}

class _CourseSearchBarState extends State<CourseSearchBar> {
  final TextEditingController _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  // @override
  // void initState() {
  //   super.initState();
  // }

  void _onFocusChange() {
    if (widget.onFocusChanged != null) {
      widget.onFocusChanged!(_focusNode.hasFocus);
    }
    if (_focusNode.hasFocus) widget.onSearch(_controller.text);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  // increase the height of the search bar
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
      child: Row(
        children: [
          PlatformIconButton(
            icon: Icon(
              PlatformIcons(context).search,
              color: Theme.of(context).iconTheme.color,
            ),
            // color: Colors.blue,
          ),
          Expanded(
            child: SizedBox(
              child: PlatformTextField(
                autofocus: false,
                keyboardType: TextInputType.text,
                // press enter key to search
                textInputAction: TextInputAction.search,
                controller: _controller,
                // todo placeholder language
                hintText: S.of(context).curriculum_search_hint,
                // increase text size and hint text size
                style: const TextStyle(fontSize: 16),
                /*
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                      CupertinoColors.secondarySystemGroupedBackground,
                      context),
                  borderRadius: BorderRadius.circular(20),
                ),
                 */
                onSubmitted: (value) {
                  widget.onSearch(value);
                },
                focusNode: _focusNode,
                onTapOutside: (e) {
                  _focusNode.unfocus();
                  _onFocusChange();
                },
                onTap: () {
                  _onFocusChange();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
