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

import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/danke/danke_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

// search bar widget

class CourseSearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const CourseSearchBar({Key? key, required this.onSearch}) : super(key: key);

  @override
  _CourseSearchBarState createState() => _CourseSearchBarState();
}

class _CourseSearchBarState extends State<CourseSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  // increase the height of the search bar
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 35,
              child: PlatformWidget(
                // fixme material usage
                // material: (_, __) => Material(
                //   elevation: 4,
                //   borderRadius: BorderRadius.circular(20),
                //   child: TextField(
                //     controller: _controller,
                //     decoration: InputDecoration(
                //       // contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                //       border: InputBorder.none,
                //       hintText: S.of(context).search,
                //     ),
                //     onSubmitted: (value) {
                //       widget.onSearch(value);
                //     },
                //   ),
                // ),
                cupertino: (_, __) => CupertinoTextField(
                  controller: _controller,
                  placeholder: S.of(context).search,
                  // increase text size and hint text size
                  style: const TextStyle(fontSize: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                        CupertinoColors.secondarySystemGroupedBackground,
                        context),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onSubmitted: (value) {
                    widget.onSearch(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}