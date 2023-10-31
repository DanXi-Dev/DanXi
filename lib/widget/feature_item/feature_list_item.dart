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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/material.dart';

/// A simple implementation of [FeatureContainerState] to show the feature as a [ListTile].
class FeatureListItem extends StatefulWidget implements FeatureContainer {
  final Feature feature;
  final Map<String, dynamic>? arguments;

  @override
  FeatureListItemState createState() => FeatureListItemState();

  const FeatureListItem({required this.feature, this.arguments, super.key});

  @override
  Feature get childFeature => feature;
}

class FeatureListItemState extends State<FeatureListItem>
    with FeatureContainerState {
  /// Control whether this feature is going to be loaded when the container is built
  late bool loadWidget;

  @override
  void didUpdateWidget(covariant FeatureListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadWidget = !widget.feature.loadOnTap;
  }

  @override
  Widget build(BuildContext context) {
    if (loadWidget) {
      widget.feature
        ..context = context
        ..container = this
        ..buildFeature(widget.arguments);

      List<String?> summary = [];
      summary.add(widget.feature.subTitle ?? "");
      if (widget.feature.tertiaryTitle != null) {
        summary.add(widget.feature.tertiaryTitle);
      }

      final tile = ListTile(
        trailing: widget.feature.trailing,
        isThreeLine: widget.feature.tertiaryTitle != null,
        leading: widget.feature.icon,
        title: Text(
          widget.feature.mainTitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: widget.feature.customSubtitle ?? Text(summary.join("\n")),
        onTap: widget.feature.clickable ? widget.feature.onTap : null,
      );
      widget.feature.onEvent(FeatureEvent.CREATE);
      return tile;
    } else {
      widget.feature
        ..context = context
        ..container = this;

      return ListTile(
        isThreeLine: widget.feature.tertiaryTitle != null,
        leading: widget.feature.icon,
        title: Text(
          widget.feature.mainTitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(S.of(context).tap_to_view),
        onTap: () => setState(() {
          loadWidget = true;
        }),
      );
    }
  }

  @override
  void doUpdate() => refreshSelf();

  @override
  void initState() {
    super.initState();
    widget.feature.initFeature();
    loadWidget = !widget.feature.loadOnTap;
  }
}
