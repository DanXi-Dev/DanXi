/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A simple implementation of [FeatureContainer] to show the feature as a [ListTile].
class FeatureListItem extends StatefulWidget {
  final Feature feature;

  @override
  _FeatureListItemState createState() => _FeatureListItemState();

  FeatureListItem({this.feature});
}

class _FeatureListItemState extends State<FeatureListItem>
    with FeatureContainer {
  @override
  Widget build(BuildContext context) {
    widget.feature
      ..context = context
      ..container = this
      ..buildFeature();

    List<String> summary = [];
    summary.add(widget.feature.subTitle ?? "");
    if (widget.feature.tertiaryTitle != null)
      summary.add(widget.feature.tertiaryTitle);

    return ListTile(
      isThreeLine: widget.feature.tertiaryTitle != null,
      leading: widget.feature.icon,
      title: Text(widget.feature.mainTitle),
      subtitle: Text(summary.join("\n")),
      onTap: widget.feature.clickable ? widget.feature.onTap : null,
    );
  }

  @override
  void doUpdate() => refreshSelf();
}
