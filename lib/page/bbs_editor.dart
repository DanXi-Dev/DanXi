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

import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:flutter_progress_dialog/src/progress_dialog.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:flutter_tagging/flutter_tagging.dart';
import 'package:image_picker/image_picker.dart';

/// An full-screen editor page.
///
/// Arguments:
/// [bool] tags: to show a tag selector, default false
/// [String] title: the page's title, default "Post"
///
/// Callback:
/// [PostEditorText] The editor text.
class BBSEditorPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSEditorPage({Key key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  //var _controller =
  //    PlatformX.isMobile ? HtmlEditorController() : QuillController.basic();
  var _controller = TextEditingController();

  /// Whether the send button is enabled
  bool _canSend = true;
  bool _supportTags;
  List<PostTag> _tags = [];
  List<PostTag> _allTags;

  String _title;

  @override
  void didChangeDependencies() {
    _supportTags = widget.arguments['tags'] ?? false;
    _title =
        widget.arguments['title'] ?? S.of(context).forum_post_enter_content;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        appBar: PlatformAppBarX(
          title: Text(_title),
          trailingActions: [
            PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: PlatformX.isAndroid
                    ? const Icon(Icons.photo)
                    : const Icon(SFSymbols.photo),
                onPressed: _uploadImage),
            PlatformIconButton(
                padding: EdgeInsets.zero,
                icon: PlatformX.isAndroid
                    ? const Icon(Icons.send)
                    : const Icon(SFSymbols.paperplane),
                onPressed: _canSend ? _sendDocument : null),
          ],
        ),
        body: Material(
            child: Padding(
                padding: EdgeInsets.all(4),
                child: Column(
                  children: [
                    if (_supportTags)
                      ThemedMaterial(
                        child: FlutterTagging<PostTag>(
                            initialItems: _tags,
                            textFieldConfiguration: TextFieldConfiguration(
                              decoration: InputDecoration(
                                hintText: '',
                                labelText: S.of(context).select_tags,
                              ),
                            ),
                            findSuggestions: (String filter) async {
                              if (_allTags == null)
                                _allTags = await PostRepository.getInstance()
                                    .loadTags();
                              return _allTags
                                  .where((value) => value.name
                                      .toLowerCase()
                                      .contains(filter.toLowerCase()))
                                  .toList();
                            },
                            additionCallback: (value) =>
                                PostTag(value, Constant.randomColor, 0),
                            onAdded: (tag) => tag,
                            configureSuggestion: (tag) =>
                                SuggestionConfiguration(
                                  title: Text(
                                    tag.name,
                                    style: TextStyle(
                                        color: Constant.getColorFromString(
                                            tag.color)),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Icon(
                                        SFSymbols.flame,
                                        color: Constant.getColorFromString(
                                            tag.color),
                                        size: 12,
                                      ),
                                      const SizedBox(
                                        width: 2,
                                      ),
                                      Text(
                                        tag.count.toString(),
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Constant.getColorFromString(
                                                tag.color)),
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
                                    backgroundColor:
                                        Theme.of(context).accentColor,
                                  ),
                                ),
                            configureChip: (lang) => ChipConfiguration(
                                  label: Text(lang.name),
                                  backgroundColor:
                                      Constant.getColorFromString(lang.color),
                                  labelStyle: TextStyle(
                                      color: Constant.getColorFromString(
                                                      lang.color)
                                                  .computeLuminance() >=
                                              0.5
                                          ? Colors.black
                                          : Colors.white),
                                  deleteIconColor:
                                      Constant.getColorFromString(lang.color)
                                                  .computeLuminance() >=
                                              0.5
                                          ? Colors.black
                                          : Colors.white,
                                ),
                            onChanged: () {}),
                      ),
                    Expanded(
                      child: PlatformTextField(
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        controller: _controller,
                      ),
                    ),
                  ],
                ))));
  }

  Future<void> _sendDocument() async {
    String text = _controller.text;
    if (text.isEmpty) return;
    Navigator.pop<PostEditorText>(context, PostEditorText(text, _tags));
  }

  Future<void> _uploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final PickedFile _file =
        await _picker.getImage(source: ImageSource.gallery);
    if (_file == null) return;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).uploading_image, context: context);
    try {
      await PostRepository.getInstance().uploadImage(File(_file.path)).then(
          (value) {
        if (value != null) _controller.text += "![]($value)";
        //"showAnim: true" makes it crash. Don't know the reason.
        progressDialog.dismiss(showAnim: false);
        return value;
      }, onError: (e) {
        progressDialog.dismiss(showAnim: false);
        Noticing.showNotice(context, S.of(context).uploading_image_failed);
        throw e;
      });
    } catch (ignored) {}
  }
}

class PostEditorText {
  final String content;
  final List<PostTag> tags;

  PostEditorText(this.content, this.tags);
}
