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

import 'dart:convert';
import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:delta_markdown/delta_markdown.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:flutter_progress_dialog/src/progress_dialog.dart';
import 'package:flutter_quill/widgets/controller.dart';
import 'package:flutter_quill/widgets/editor.dart';
import 'package:flutter_quill/widgets/toolbar.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:flutter_tagging/flutter_tagging.dart';
import 'package:markdown/markdown.dart' as markdown;

class BBSEditorPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSEditorPage({Key key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  QuillController _controller = QuillController.basic();

  /// Whether the send button is enabled
  bool _canSend = true;
  List<PostTag> _tags = [];
  List<PostTag> _allTags;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).forum_post_enter_content),
          trailingActions: [
            PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: PlatformX.isAndroid
                    ? const Icon(Icons.send)
                    : const Icon(SFSymbols.paperplane),
                onPressed: _canSend ? _sendDocument : null)
          ],
        ),
        body: Padding(
            padding: EdgeInsets.all(4),
            child: Column(
              children: [
                ThemedMaterial(
                  child: FlutterTagging<PostTag>(
                      initialItems: _tags,
                      textFieldConfiguration: TextFieldConfiguration(
                        decoration: InputDecoration(
                          hintText: 'Search Tags',
                          labelText: 'Select Tags',
                        ),
                      ),
                      findSuggestions: (String filter) async {
                        if (_allTags == null)
                          _allTags =
                              await PostRepository.getInstance().loadTags();
                        return _allTags
                            .takeWhile((value) => value.name.contains(filter))
                            .toList();
                      },
                      additionCallback: (value) =>
                          PostTag(value, Constant.randomColor, 0),
                      onAdded: (tag) => tag,
                      configureSuggestion: (tag) => SuggestionConfiguration(
                            title: Text(tag.name),
                            subtitle: Text(tag.count.toString()),
                            additionWidget: Chip(
                              avatar: Icon(
                                Icons.add_circle,
                                color: Colors.white,
                              ),
                              label: Text('Add New Tag'),
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w300,
                              ),
                              backgroundColor: Colors.green,
                            ),
                          ),
                      configureChip: (lang) => ChipConfiguration(
                            label: Text(lang.name),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                            deleteIconColor: Colors.white,
                          ),
                      onChanged: () {}),
                ),
                Expanded(
                    child: BBSEditorWidget(
                      controller: _controller,
                    ),
                )
              ],
            )));
  }

  Future<void> _sendDocument() async {
    if (BBSEditorWidget.isEmpty(_controller)) {
    } else {
      Navigator.pop<PostEditorText>(
          context, PostEditorText(BBSEditorWidget.getText(_controller), _tags));
    }
  }
}

class BBSEditorWidget extends StatefulWidget {
  final QuillController controller;

  const BBSEditorWidget({Key key, this.controller}) : super(key: key);

  @override
  _BBSEditorWidgetState createState() => _BBSEditorWidgetState();

  static getText(QuillController controller) {
    String html = markdown.markdownToHtml(
        deltaToMarkdown(jsonEncode(controller.document.toDelta().toJson())));
    return html;
  }

  static isEmpty(QuillController controller) {
    return controller == null || controller.document.isEmpty();
  }
}

class _BBSEditorWidgetState extends State<BBSEditorWidget> {
  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        QuillToolbar.basic(
          controller: widget.controller,
          showBackgroundColorButton: false,
          showColorButton: false,
          showStrikeThrough: false,
          showUnderLineButton: false,
          showListCheck: false,
          onImagePickCallback: (File file) async {
            ProgressFuture progressDialog = showProgressDialog(
                loadingText: S.of(context).uploading_image, context: context);
            return await PostRepository.getInstance().uploadImage(file).then(
                (value) {
              progressDialog.dismiss(showAnim: false);
              return value;
            }, onError: (e) {
              progressDialog.dismiss(showAnim: false);
              Noticing.showNotice(
                  context, S.of(context).uploading_image_failed);
              return null;
            });
          },
        ),
        Expanded(
          child: Container(
            child: QuillEditor.basic(
              controller: widget.controller,
              readOnly: false, // true for view only mode
            ),
          ),
        )
      ],
    );
  }
}

class PostEditorText {
  final String content;
  final List<PostTag> tags;

  PostEditorText(this.content, this.tags);
}
