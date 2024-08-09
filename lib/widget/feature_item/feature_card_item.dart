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
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A simple implementation of [FeatureContainerState] to show the feature as a [Card].
class FeatureCardItem extends StatefulWidget implements FeatureContainer {
  final Feature feature;
  final Map<String, dynamic>? arguments;
  final Function? onDismissed;

  @override
  FeatureCardItemState createState() => FeatureCardItemState();

  const FeatureCardItem(
      {required this.feature, this.arguments, this.onDismissed, super.key});

  @override
  Feature get childFeature => feature;
}

class FeatureCardItemState extends State<FeatureCardItem>
    with FeatureContainerState {
  late Key _key;

  @override
  void initState() {
    super.initState();
    _key = Key(runtimeType.toString());
    widget.feature.initFeature();
  }

  @override
  Widget build(BuildContext context) {
    widget.feature
      ..context = context
      ..container = this
      ..buildFeature(widget.arguments);

    List<String?> summary = [];
    if (widget.feature.subTitle != null) {
      summary.add(widget.feature.subTitle);
    }
    if (widget.feature.tertiaryTitle != null) {
      summary.add(widget.feature.tertiaryTitle);
    }
    Widget card = Card(
      child: Padding(
        padding:
            widget.feature.padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(children: [
              if (widget.feature.icon != null) ...[
                PlatformWidget(
                  cupertino: (_, __) => widget.feature.icon,
                  material: (context, __) => IconTheme(
                      data: IconThemeData(color: Theme.of(context).hintColor),
                      child: widget.feature.icon!),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                widget.feature.mainTitle!,
                style: const TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ]),
            if (widget.feature.customSubtitle != null ||
                summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              widget.feature.customSubtitle ??
                  Text(
                    summary.join("\n"),
                    style: PlatformX.getTheme(context)
                        .textTheme
                        .displayLarge!
                        .copyWith(fontSize: 12),
                  )
            ],
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
