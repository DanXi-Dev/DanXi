/*
 *     Copyright (C) 2021 kavinzhao
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

import 'dart:async';
import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/icon_fonts.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/master_detail/editor_object.dart';
import 'package:dan_xi/master_detail/master_detail_utils.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/flutter_tagging/configurations.dart';
import 'package:dan_xi/widget/image_picker_proxy.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:flutter_progress_dialog/src/progress_dialog.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'flutter_tagging/tagging.dart';

enum BBSEditorType { DIALOG, PAGE }

class BBSEditor {
  static Future<bool> createNewPost(BuildContext context,
      {BBSEditorType? editorType}) async {
    final object = EditorObject(0, EditorObjectType.NEW_POST);
    final PostEditorText? content = await _showEditor(
        context, S.of(context)!.new_post,
        allowTags: true, editorType: editorType, object: object);
    if (content?.text == null) return false;
    final success = await (PostRepository.getInstance()
        .newPost(content!.text, tags: content.tags)
        .onError((dynamic error, stackTrace) {
      if (error is DioError)
        error = error.message + '\n' + (error.response?.data?.toString() ?? "");
      Noticing.showNotice(context, error.toString(),
          title: S.of(context)!.post_failed, useSnackBar: false);
      return -1;
    }) as FutureOr<int>);
    if (success == -1) return false;
    StateProvider.editorCache.remove(object);
    return true;
  }

  static Future<void> createNewReply(
      BuildContext context, int? discussionId, int? postId,
      {BBSEditorType? editorType}) async {
    final object = (discussionId == null
        ? EditorObject(discussionId, EditorObjectType.REPLY_TO_DISCUSSION)
        : EditorObject(postId, EditorObjectType.REPLY_TO_REPLY));
    final String? content = (await _showEditor(
            context,
            postId == null
                ? S.of(context)!.reply_to(discussionId ?? "?")
                : S.of(context)!.reply_to(postId),
            editorType: editorType,
            object: object))
        ?.text;
    if (content == null || content.trim() == "") return;
    final success = await (PostRepository.getInstance()
        .newReply(discussionId, postId, content)
        .onError((dynamic error, stackTrace) {
      if (error is DioError) {
        Noticing.showNotice(context,
            error.message + '\n' + (error.response?.data?.toString() ?? ""),
            title: S.of(context)!.reply_failed(error.type), useSnackBar: false);
      } else {
        Noticing.showNotice(context, S.of(context)!.reply_failed(error),
            title: S.of(context)!.fatal_error, useSnackBar: false);
      }
      return -1;
    }) as FutureOr<int>);
    if (success == -1) return;
    StateProvider.editorCache.remove(object);
  }

  static Future<void> adminModifyReply(BuildContext context, int? discussionId,
      int? postId, String? originalContent,
      {BBSEditorType? editorType}) async {
    // TODO: Show original content in the editor
    final object = (discussionId == null
        ? EditorObject(discussionId, EditorObjectType.REPLY_TO_DISCUSSION)
        : EditorObject(postId, EditorObjectType.REPLY_TO_REPLY));
    final String? content = (await _showEditor(
            context,
            postId == null
                ? S.of(context)!.reply_to(discussionId ?? "?")
                : S.of(context)!.reply_to(postId),
            editorType: editorType,
            object: object))
        ?.text;
    if (content == null || content.trim() == "") return;
    await PostRepository.getInstance()
        .adminModifyPost(content, discussionId, postId)
        .onError((dynamic error, stackTrace) {
      if (error is DioError) {
        Noticing.showNotice(context,
            error.message + '\n' + (error.response?.data?.toString() ?? ""),
            title: S.of(context)!.reply_failed(error.type), useSnackBar: false);
      } else
        Noticing.showNotice(context, S.of(context)!.reply_failed(error),
            title: S.of(context)!.fatal_error, useSnackBar: false);
      return -1;
    });
    StateProvider.editorCache.remove(object);
  }

  static Future<void> reportPost(BuildContext context, int? postId) async {
    final object = EditorObject(postId, EditorObjectType.REPORT_REPLY);
    final String? content = (await _showEditor(
            context, S.of(context)!.reason_report_post(postId ?? "?"),
            editorType: BBSEditorType.DIALOG, object: object))
        ?.text;
    if (content == null || content.trim() == "") return;

    int? responseCode =
        await PostRepository.getInstance().reportPost(postId, content);
    if (responseCode != 200) {
      Noticing.showNotice(
          context, S.of(context)!.report_failed(responseCode ?? "?"),
          title: S.of(context)!.fatal_error, useSnackBar: false);
    } else {
      StateProvider.editorCache.remove(object);
      Noticing.showNotice(context, S.of(context)!.report_success);
    }
  }

  static Future<PostEditorText?> _showEditor(BuildContext context, String title,
      {bool allowTags = false,
      required BBSEditorType? editorType,
      required EditorObject object}) async {
    final BBSEditorType defaultType =
        isTablet(context) ? BBSEditorType.DIALOG : BBSEditorType.PAGE;
    switch (editorType ?? defaultType) {
      case BBSEditorType.DIALOG:
        if (!StateProvider.editorCache.containsKey(object))
          StateProvider.editorCache[object] = PostEditorText.newInstance();
        final textController = TextEditingController(
            text: StateProvider.editorCache[object]!.text);
        textController.addListener(() =>
            StateProvider.editorCache[object]!.text = textController.text);
        return await showPlatformDialog<PostEditorText>(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => PlatformAlertDialog(
                  title: Text(title),
                  content: BBSEditorWidget(
                    controller: textController,
                    allowTags: allowTags,
                    editorObject: object,
                  ),
                  actions: [
                    PlatformDialogAction(
                        child: Text(S.of(context)!.cancel),
                        onPressed: () {
                          StateProvider.editorCache[object]!.text =
                              textController.text;
                          Navigator.of(context).pop<PostEditorText>(null);
                        }),
                    PlatformDialogAction(
                        child: Text(S.of(context)!.add_image),
                        onPressed: () => uploadImage(context, textController)),
                    PlatformDialogAction(
                        child: Text(S.of(context)!.submit),
                        onPressed: () async {
                          Navigator.of(context).pop<PostEditorText>(
                              PostEditorText(textController.text,
                                  StateProvider.editorCache[object]!.tags!));
                        }),
                  ],
                )).then((value) {
          textController.dispose();
          return value;
        });
        break;
      case BBSEditorType.PAGE:
        // Receive the value with **dynamic** variable to prevent automatic type inference
        dynamic result = await smartNavigatorPush(
            context, '/bbs/fullScreenEditor',
            arguments: {"title": title, "tags": allowTags, 'object': object});
        return result;
    }
    return null;
  }

  @protected
  static Future<void> uploadImage(
      BuildContext context, TextEditingController _controller) async {
    final ImagePickerProxy _picker = ImagePickerProxy.createPicker();
    final String? _file = await _picker.pickImage();
    if (_file == null) return;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context)!.uploading_image, context: context);
    try {
      await PostRepository.getInstance().uploadImage(File(_file)).then((value) {
        if (value != null) _controller.text += "![]($value)";
        //"showAnim: true" makes it crash. Don't know the reason.
        progressDialog.dismiss(showAnim: false);
        return value;
      }, onError: (e) {
        progressDialog.dismiss(showAnim: false);
        Noticing.showNotice(context, S.of(context)!.uploading_image_failed);
        throw e;
      });
    } catch (ignored) {}
  }
}

class BBSEditorWidget extends StatefulWidget {
  final TextEditingController? controller;
  final EditorObject? editorObject;
  final bool? allowTags;

  const BBSEditorWidget(
      {Key? key, this.controller, this.allowTags, this.editorObject})
      : super(key: key);

  @override
  _BBSEditorWidgetState createState() => _BBSEditorWidgetState();
}

class _BBSEditorWidgetState extends State<BBSEditorWidget> {
  List<PostTag>? _allTags;

  @override
  void initState() {
    super.initState();
    widget.controller!.addListener(() {
      refreshSelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    StateProvider.editorCache[widget.editorObject]!.tags ??= [];
    return SingleChildScrollView(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.allowTags!)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ThemedMaterial(
                  child: FlutterTagging<PostTag>(
                      initialItems: StateProvider
                              .editorCache[widget.editorObject]!.tags ??
                          [],
                      emptyBuilder: (context) => Wrap(
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              Text(S.of(context)!.failed),
                              TextButton(
                                onPressed: () {
                                  setState(() {});
                                },
                                child: Text(S.of(context)!.retry),
                              ),
                            ],
                          ),
                      textFieldConfiguration: TextFieldConfiguration(
                        decoration: InputDecoration(
                          labelStyle: TextStyle(fontSize: 12),
                          labelText: S.of(context)!.select_tags,
                        ),
                      ),
                      findSuggestions: (String filter) async {
                        if (_allTags == null)
                          _allTags =
                              await PostRepository.getInstance().loadTags();
                        return _allTags!
                            .where((value) => value.name!
                                .toLowerCase()
                                .contains(filter.toLowerCase()))
                            .toList();
                      },
                      additionCallback: (value) =>
                          PostTag(value, Constant.randomColor, 0),
                      onAdded: (tag) => tag,
                      configureSuggestion: (tag) => SuggestionConfiguration(
                            title: Text(
                              tag.name!,
                              style: TextStyle(
                                  color:
                                      Constant.getColorFromString(tag.color)),
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
                              label: Text(S.of(context)!.add_new_tag),
                              labelStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w300,
                              ),
                              backgroundColor: Theme.of(context).accentColor,
                            ),
                          ),
                      configureChip: (tag) => ChipConfiguration(
                            label: Text(tag.name!),
                            backgroundColor:
                                Constant.getColorFromString(tag.color),
                            labelStyle: TextStyle(
                                color: Constant.getColorFromString(tag.color)
                                            .computeLuminance() >=
                                        0.5
                                    ? Colors.black
                                    : Colors.white),
                            deleteIconColor:
                                Constant.getColorFromString(tag.color)
                                            .computeLuminance() >=
                                        0.5
                                    ? Colors.black
                                    : Colors.white,
                          ),
                      onChanged: () {}),
                ),
              ),
            PlatformIconButton(
              icon: Icon(
                IconFont.markdown,
                color: Theme.of(context).accentColor,
              ),
              onPressed: () {
                showPlatformModalSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Material(
                      color: PlatformX.backgroundColor(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(
                              IconFont.markdown,
                            ),
                            title: Text(S.of(context)!.markdown_enabled),
                          ),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Linkify(
                              text: S.of(context)!.markdown_description,
                              onOpen: (element) =>
                                  BrowserUtil.openUrl(element.url, context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            PlatformTextField(
              material: (_, __) => MaterialTextFieldData(
                  decoration: InputDecoration(
                      border: OutlineInputBorder(gapPadding: 2.0))),
              controller: widget.controller,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 5,
              autofocus: true,
            ),
            Divider(),
            Text(S.of(context)!.preview,
                style: TextStyle(color: Theme.of(context).hintColor)),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: smartRender(widget.controller!.text, null, null),
            ),
          ]),
    );
  }
}

class PostEditorText {
  String? text;

  /// Non-nullable
  List<PostTag>? tags;

  PostEditorText(this.text, List<PostTag> this.tags) : assert(tags != null);

  PostEditorText.newInstance() {
    text = '';
    tags = [];
  }
}

/// An full-screen editor page.
///
/// Arguments:
/// [bool] tags: whether to show a tag selector, default false
/// [String] title: the page's title, default "Post"
///
/// Callback:
/// [PostEditorText] The editor text.
class BBSEditorPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSEditorPage({Key? key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  final _controller = TextEditingController();

  /// Whether the send button is enabled
  bool _canSend = true;
  bool? _supportTags;
  EditorObject? _object;
  late String _title;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      StateProvider.editorCache[_object]!.text = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _supportTags = widget.arguments!['tags'] ?? false;
    _title =
        widget.arguments!['title'] ?? S.of(context)!.forum_post_enter_content;
    _object = widget.arguments!['object'];
    if (StateProvider.editorCache.containsKey(_object))
      _controller.text = StateProvider.editorCache[_object]!.text!;
    else
      StateProvider.editorCache[_object] = PostEditorText.newInstance();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(_title),
        trailingActions: [
          PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isAndroid
                  ? const Icon(Icons.photo)
                  : const Icon(CupertinoIcons.photo),
              onPressed: () => BBSEditor.uploadImage(context, _controller)),
          PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isAndroid
                  ? const Icon(Icons.send)
                  : const Icon(CupertinoIcons.paperplane),
              onPressed: _canSend ? () => _sendDocument(_object) : null),
        ],
      ),
      body: SafeArea(
          bottom: false,
          child: Material(
              child: Padding(
                  padding: EdgeInsets.all(8),
                  child: BBSEditorWidget(
                    controller: _controller,
                    allowTags: _supportTags,
                    editorObject: _object,
                  )))),
    );
  }

  Future<void> _sendDocument(EditorObject? object) async {
    String text = _controller.text;
    if (text.isEmpty) return;
    Navigator.pop<PostEditorText>(context,
        PostEditorText(text, StateProvider.editorCache[object]!.tags!));
  }
}
