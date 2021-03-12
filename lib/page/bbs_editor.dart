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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class BBSEditorPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSEditorPage({Key key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  BBSPost _post;

  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        appBar: PlatformAppBar(
          title: Text("写点什么"),
          trailingActions: [
            PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.send),
                onPressed: _sendDocument)
          ],
        ),
        body: Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  child: PlatformTextField(
                    material: (_, __) => MaterialTextFieldData(
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: _post.replyTo == "0"
                              ? null
                              : S.of(context).reply_to(_post.author)),
                    ),
                    cupertino: (_, __) => CupertinoTextFieldData(
                        placeholder: _post.replyTo == "0"
                            ? null
                            : S.of(context).reply_to(_post.author)),
                    style: TextStyle(fontSize: 18),
                    expands: true,
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.top,
                    controller: _controller,
                    maxLines: null,
                    autofocus: true,
                  ),
                )
              ],
            )));
  }

  Future<void> _sendDocument() async {
    if (_controller.text.trim().isEmpty) {
    } else {
      _post.content = _controller.text;
      await _post.save();
      Navigator.pop(context);
      RetrieveNewPostEvent().fire();
    }
  }
}
