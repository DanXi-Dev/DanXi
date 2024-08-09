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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/forum/ottag_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page allowing user to configure his/her blocking list of tags.
class BBSHiddenTagsPreferencePage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  BBSHiddenTagsPreferencePageState createState() =>
      BBSHiddenTagsPreferencePageState();

  const BBSHiddenTagsPreferencePage({super.key, this.arguments});
}

class BBSHiddenTagsPreferencePageState
    extends State<BBSHiddenTagsPreferencePage> {
  late List<OTTag> tags;

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
        title: Text(S.of(context).forum_hidden_tags_title),
      ),
      body: SafeArea(
        child: OTTagSelector(
          initialTags: tags,
          onChanged: () => SettingsProvider.getInstance().hiddenTags = tags,
        ),
      ),
    );
  }
}
