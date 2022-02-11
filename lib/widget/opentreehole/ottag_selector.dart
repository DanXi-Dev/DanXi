/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/flutter_tagging/configurations.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/flutter_tagging/tagging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

/// A tag selector for [OTTag].
///
/// Note: Require a [Material] widget to be its ancestor.
class OTTagSelector extends StatefulWidget {
  /// Tag list on display.
  ///
  /// Note: The list itself will be replaced with new selected tags before calling [onChanged].
  final List<OTTag> initialTags;
  final VoidCallback? onChanged;

  const OTTagSelector({Key? key, required this.initialTags, this.onChanged})
      : super(key: key);

  @override
  _OTTagSelectorState createState() => _OTTagSelectorState();
}

class _OTTagSelectorState extends State<OTTagSelector> {
  List<OTTag>? _allTags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FlutterTagging<OTTag>(
          initialItems: widget.initialTags,
          emptyBuilder: (context) => Wrap(
                alignment: WrapAlignment.spaceAround,
                children: [Text(S.of(context).no_data)],
              ),
          textFieldConfiguration: TextFieldConfiguration(
            decoration: InputDecoration(
              labelStyle: const TextStyle(fontSize: 12),
              labelText: S.of(context).select_tags,
            ),
          ),
          findSuggestions: (String filter) async {
            _allTags ??= await OpenTreeHoleRepository.getInstance().loadTags();
            return _allTags!
                .where((value) =>
                    value.name!.toLowerCase().contains(filter.toLowerCase()))
                .toList();
          },
          additionCallback: (value) => OTTag(0, 0, value),
          onAdded: (tag) => tag,
          configureSuggestion: (tag) => SuggestionConfiguration(
                title: Text(tag.name!, style: TextStyle(color: tag.color)),
                subtitle: Row(
                  children: [
                    Icon(CupertinoIcons.flame, color: tag.color, size: 12),
                    const SizedBox(width: 2),
                    Text(tag.temperature.toString(),
                        style: TextStyle(fontSize: 13, color: tag.color)),
                    const Divider(),
                  ],
                ),
                additionWidget: Chip(
                    avatar: const Icon(Icons.add_circle, color: Colors.white),
                    label: Text(S.of(context).add_new_tag),
                    labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300),
                    backgroundColor: Theme.of(context).colorScheme.secondary),
              ),
          customChipBuilder: (tag, onDelete) {
            return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RoundChip(
                    label: tag.name,
                    color: tag.color,
                    onTap: () async {
                      if (await Noticing.showConfirmationDialog(
                              context, tag.name ?? "",
                              title: S.of(context).delete_this_tag) ==
                          true) {
                        onDelete.call();
                      }
                    }));
          },
          configureChip: (tag) => ChipConfiguration(
              label: Text(tag.name!),
              backgroundColor: tag.color,
              labelStyle: TextStyle(
                  color: tag.color.computeLuminance() >= 0.5
                      ? Colors.black
                      : Colors.white),
              deleteIconColor: tag.color.computeLuminance() >= 0.5
                  ? Colors.black
                  : Colors.white),
          onChanged: widget.onChanged),
    );
  }
}
