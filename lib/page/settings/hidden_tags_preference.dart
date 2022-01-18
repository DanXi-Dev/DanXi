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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/flutter_tagging/configurations.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/flutter_tagging/tagging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

/// A list page allowing user to configure his/her blocking list of tags.
class BBSHiddenTagsPreferencePage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  _BBSHiddenTagsPreferencePageState createState() =>
      _BBSHiddenTagsPreferencePageState();

  const BBSHiddenTagsPreferencePage({Key? key, this.arguments})
      : super(key: key);
}

class _BBSHiddenTagsPreferencePageState
    extends State<BBSHiddenTagsPreferencePage> {
  List<OTTag>? tags;
  List<OTTag>? _allTags;

  @override
  void initState() {
    super.initState();
    tags = SettingsProvider.getInstance().hiddenTags ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).fduhole_hidden_tags_title),
      ),
      body: SafeArea(
        child:
            // TODO: it is ugly to copy the logic of [FlutterTagging] from [_BBSEditorWidgetState].
            //  Consider packing it later.
            ThemedMaterial(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FlutterTagging<OTTag>(
                initialItems: tags ?? [],
                emptyBuilder: (context) => Wrap(
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        Text(S.of(context).no_data),
                      ],
                    ),
                textFieldConfiguration: TextFieldConfiguration(
                  decoration: InputDecoration(
                    labelStyle: const TextStyle(fontSize: 12),
                    labelText: S.of(context).select_tags,
                  ),
                ),
                findSuggestions: (String filter) async {
                  _allTags ??=
                      await OpenTreeHoleRepository.getInstance().loadTags();
                  return _allTags!
                      .where((value) => value.name!
                          .toLowerCase()
                          .contains(filter.toLowerCase()))
                      .toList();
                },
                additionCallback: (value) => OTTag(0, 0, value),
                onAdded: (tag) => tag,
                configureSuggestion: (tag) => SuggestionConfiguration(
                      title: Text(
                        tag.name!,
                        style: TextStyle(
                            color: Constant.getColorFromString(tag.color)),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(
                            CupertinoIcons.flame,
                            color: Constant.getColorFromString(tag.color),
                            size: 12,
                          ),
                          const SizedBox(
                            width: 2,
                          ),
                          Text(
                            tag.temperature.toString(),
                            style: TextStyle(
                                fontSize: 13,
                                color: Constant.getColorFromString(tag.color)),
                          ),
                        ],
                      ),
                      additionWidget: Chip(
                        avatar: const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                        ),
                        label: Text(S.of(context).add_new_tag),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                configureChip: (tag) => ChipConfiguration(
                      label: Text(tag.name!),
                      backgroundColor: Constant.getColorFromString(tag.color),
                      labelStyle: TextStyle(
                          color: Constant.getColorFromString(tag.color)
                                      .computeLuminance() >=
                                  0.5
                              ? Colors.black
                              : Colors.white),
                      deleteIconColor: Constant.getColorFromString(tag.color)
                                  .computeLuminance() >=
                              0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                onChanged: () {
                  SettingsProvider.getInstance().hiddenTags = tags;
                }),
          ),
        ),
      ),
    );
  }
}
