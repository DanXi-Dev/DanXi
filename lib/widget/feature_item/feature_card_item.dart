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
import 'package:dan_xi/main.dart';
import 'package:flutter/material.dart';
import 'package:dan_xi/public_extension_methods.dart';

/// A simple implementation of [FeatureContainer] to show the feature as a [Card].
class FeatureCardItem extends StatefulWidget {
  final Feature feature;
  final Map<String, dynamic> arguments;
  final Function onDismissed;

  @override
  _FeatureCardItemState createState() => _FeatureCardItemState();

  FeatureCardItem({@required this.feature, this.arguments, this.onDismissed});
}

class _FeatureCardItemState extends State<FeatureCardItem>
    with FeatureContainer {
  Key _key;

  @override
  void initState() {
    super.initState();
    _key = Key(runtimeType.toString());
  }

  @override
  Widget build(BuildContext context) {
    widget.feature
      ..context = context
      ..container = this
      ..buildFeature(widget.arguments);

    List<String> summary = [];
    summary.add(widget.feature.subTitle ?? "");
    if (widget.feature.tertiaryTitle != null)
      summary.add(widget.feature.tertiaryTitle);
    Widget card = Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                widget.feature.icon,
                SizedBox(
                  width: 8,
                ),
                Text(
                  widget.feature.mainTitle,
                  style: TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              ].takeWhile((value) => value != null).toList(),
            ),
            SizedBox(
              height: 8,
            ),
            widget.feature.customSubtitle == null
                ? Text(
                    summary.join("\n"),
                    style: getTheme(context)
                        .textTheme
                        .headline1
                        .copyWith(fontSize: 12),
                  )
                : widget.feature.customSubtitle,
            widget.feature.trailing
          ].takeWhile((value) => value != null).toList(),
        ),
      ),
    );
    widget.feature.onEvent(FeatureEvent.CREATE);
    if (widget.feature.removable) {
      return Dismissible(
        key: _key,
        child: card,
        onDismissed: (_) {
          widget.onDismissed?.call();
          widget.feature.onEvent(FeatureEvent.REMOVE);
        },
      );
    }
    return card;
  }

  @override
  void doUpdate() => refreshSelf();
}
