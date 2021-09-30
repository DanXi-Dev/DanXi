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
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/widget/flutter_tagging/configurations.dart';
import 'package:dan_xi/widget/flutter_tagging/tagging.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class BBSHiddenTagsPreferencePage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _BBSHiddenTagsPreferencePageState createState() =>
      _BBSHiddenTagsPreferencePageState();

  BBSHiddenTagsPreferencePage({Key key, this.arguments});
}

class _BBSHiddenTagsPreferencePageState
    extends State<BBSHiddenTagsPreferencePage> {
  List<PostTag> tags;
  List<PostTag> _allTags;

  @override
  void initState() {
    super.initState();
    tags = SettingsProvider.getInstance().hiddenTags ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).fduhole_hidden_tags_title),
      ),
      body: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        // TODO: it is ugly to copy the logic of [FlutterTagging] from [_BBSEditorWidgetState].
        //  Consider packing it later.
        child: ThemedMaterial(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FlutterTagging<PostTag>(
                initialItems: tags,
                emptyBuilder: (context) => Wrap(
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        Text(S.of(context).no_data),
                      ],
                    ),
                textFieldConfiguration: TextFieldConfiguration(
                  decoration: InputDecoration(
                    labelStyle: TextStyle(fontSize: 12),
                    labelText: S.of(context).select_tags,
                  ),
                ),
                findSuggestions: (String filter) async {
                  if (_allTags == null)
                    _allTags = await PostRepository.getInstance().loadTags();
                  return _allTags
                      .where((value) => value.name
                          .toLowerCase()
                          .contains(filter.toLowerCase()))
                      .toList();
                },
                additionCallback: (value) =>
                    PostTag(value, Constant.randomColor, 0),
                onAdded: (tag) => tag,
                configureSuggestion: (tag) => SuggestionConfiguration(
                      title: Text(
                        tag.name,
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
                            tag.count.toString(),
                            style: TextStyle(
                                fontSize: 13,
                                color: Constant.getColorFromString(tag.color)),
                          ),
                        ],
                      ),
                      additionWidget: Chip(
                        avatar: Icon(
                          Icons.add_circle,
                          color: Colors.white,
                        ),
                        label: Text(S.of(context).add_new_tag),
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w300,
                        ),
                        backgroundColor: Theme.of(context).accentColor,
                      ),
                    ),
                configureChip: (tag) => ChipConfiguration(
                      label: Text(tag.name),
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
