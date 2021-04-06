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
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

class BBSEditorPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSEditorPage({Key key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  BBSPost _post;
  String _replyTo;

  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];
    _replyTo = widget.arguments['replyTo'];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        appBar: PlatformAppBar(
          title: Text(S.of(context).forum_post_enter_content),
          trailingActions: [
            PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: PlatformX.isAndroid ? const Icon(Icons.send): const Icon(SFSymbols.paperplane),
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
                              : S.of(context).reply_to(_replyTo)),
                    ),
                    cupertino: (_, __) => CupertinoTextFieldData(
                        placeholder: _post.replyTo == "0"
                            ? null
                            : S.of(context).reply_to(_replyTo)),
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
