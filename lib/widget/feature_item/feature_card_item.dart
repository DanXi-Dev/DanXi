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
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/material.dart';

/// A simple implementation of [FeatureContainerState] to show the feature as a [Card].
class FeatureCardItem extends StatefulWidget implements FeatureContainer {
  final Feature feature;
  final Map<String, dynamic>? arguments;
  final Function? onDismissed;

  @override
  _FeatureCardItemState createState() => _FeatureCardItemState();

  const FeatureCardItem(
      {required this.feature, this.arguments, this.onDismissed, Key? key})
      : super(key: key);

  @override
  Feature get childFeature => feature;
}

class _FeatureCardItemState extends State<FeatureCardItem>
    with FeatureContainerState {
  late Key _key;

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

    List<String?> summary = [];
    summary.add(widget.feature.subTitle ?? "");
    if (widget.feature.tertiaryTitle != null) {
      summary.add(widget.feature.tertiaryTitle);
    }
    Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                widget.feature.icon,
                const SizedBox(width: 8),
                Text(
                  widget.feature.mainTitle!,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              ]
                  .takeWhile((value) => value != null)
                  .map((e) => e!)
                  .toList(growable: false),
            ),
            const SizedBox(
              height: 8,
            ),
            widget.feature.customSubtitle ??
                Text(
                  summary.join("\n"),
                  style: PlatformX.getTheme(context)
                      .textTheme
                      .headline1!
                      .copyWith(fontSize: 12),
                ),
            widget.feature.trailing
          ]
              .takeWhile((value) => value != null)
              .map((e) => e!)
              .toList(growable: false),
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
