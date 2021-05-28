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
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Allows user to create custom dashboard widgets that link to certain websites.
class NewShortcutDialog extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  const NewShortcutDialog({
    Key key,
    @required this.sharedPreferences,
  }) : super(key: key);

  @override
  _NewShortcutDialogState createState() => _NewShortcutDialogState();
}

class _NewShortcutDialogState extends State<NewShortcutDialog> {
  TextEditingController _nameTextFieldController = new TextEditingController();
  TextEditingController _linkTextFieldController = new TextEditingController();
  String _errorText = "";

  void _save() {
    if (Uri.tryParse(_linkTextFieldController.text) != null) {
      print(
          "writing ${Uri.tryParse(_linkTextFieldController.text).toString()}");
      SettingsProvider.of(widget.sharedPreferences).dashboardWidgetsSequence =
          SettingsProvider.of(widget.sharedPreferences)
              .dashboardWidgetsSequence
              .followedBy([
        "n:custom_card l:${Uri.tryParse(_linkTextFieldController.text).toString()} t:${_nameTextFieldController.text}"
      ]).toList();
      RefreshHomepageEvent(queueRefresh: true).fire();
      Navigator.of(context).pop();
    } else {
      _errorText = "invalidurl";
      refreshSelf();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).new_shortcut_card),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).new_shortcut_description),
          Text(
            _errorText,
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          if (PlatformX.isCupertino(context))
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 0, 4),
                child: Text(S.of(context).name),
              ),
            ),
          PlatformTextField(
            controller: _nameTextFieldController,
            material: (_, __) => MaterialTextFieldData(
              decoration: InputDecoration(
                labelText: S.of(context).name,
                icon: PlatformX.isAndroid
                    ? Icon(Icons.lock_outline)
                    : Icon(SFSymbols.lock_circle),
              ),
            ),
            cupertino: (_, __) =>
                CupertinoTextFieldData(placeholder: S.of(context).school_bus),
          ),
          if (PlatformX.isCupertino(context))
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 0, 4),
                child: Text(S.of(context).link),
              ),
            ),
          PlatformTextField(
              controller: _linkTextFieldController,
              keyboardType: TextInputType.url,
              material: (_, __) => MaterialTextFieldData(
                    decoration: InputDecoration(
                      labelText: S.of(context).link,
                      icon: PlatformX.isAndroid
                          ? Icon(Icons.lock_outline)
                          : Icon(SFSymbols.lock_circle),
                    ),
                  ),
              cupertino: (_, __) => CupertinoTextFieldData(
                  placeholder: S.of(context).project_url),
              onSubmitted: (_) {
                _save();
              }),
        ],
      ),
      actions: [
        PlatformDialogAction(
            child: Text(S.of(context).cancel),
            onPressed: () {
              Navigator.of(context).pop();
            }),
        PlatformDialogAction(
          child: Text(S.of(context).add),
          onPressed: () {
            _save();
          },
        )
      ],
    );
  }
}
