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
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/editor_object.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/image_picker_proxy.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/opentreehole/ottag_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';

enum OTEditorType { DIALOG, PAGE }

class OTEditor {
  static Future<bool> createNewPost(BuildContext context, int divisionId,
      {OTEditorType? editorType}) async {
    final object = EditorObject(0, EditorObjectType.NEW_POST);
    final PostEditorText? content = await _showEditor(
        context, S.of(context).new_post,
        allowTags: true, editorType: editorType, object: object);
    if (content?.text == null) return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await OpenTreeHoleRepository.getInstance()
          .newHole(divisionId, content!.text, tags: content.tags);
    } catch (e, st) {
      Noticing.showModalError(context, e, trace: st);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    StateProvider.editorCache.remove(object);
    return true;
  }

  static Future<bool> createNewReply(
      BuildContext context, int? discussionId, int? floorId,
      {OTEditorType? editorType}) async {
    final object = (floorId == null
        ? EditorObject(discussionId, EditorObjectType.REPLY_TO_HOLE)
        : EditorObject(floorId, EditorObjectType.REPLY_TO_FLOOR));
    final String? content = (await _showEditor(
            context,
            floorId == null
                ? S.of(context).reply_to(discussionId ?? "?")
                : S.of(context).reply_to_floor(floorId),
            editorType: editorType,
            object: object,
            placeholder: floorId == null ? "" : "##$floorId\n"))
        ?.text;
    if (content == null || content.trim() == "") return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await OpenTreeHoleRepository.getInstance()
          .newFloor(discussionId, content);
    } catch (e, st) {
      Noticing.showModalError(context, e, trace: st);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    StateProvider.editorCache.remove(object);
    return true;
  }

  static Future<bool> modifyReply(BuildContext context, int? discussionId,
      int? floorId, String? originalContent,
      {OTEditorType? editorType}) async {
    final object = EditorObject(floorId, EditorObjectType.MODIFY_FLOOR);
    final String? content = (await _showEditor(
            context,
            floorId == null
                ? S.of(context).modify_to(discussionId ?? "?")
                : S.of(context).modify_to_floor(floorId),
            editorType: editorType,
            object: object,
            placeholder: originalContent ?? ""))
        ?.text;
    if (content == null || content.trim().isEmpty) return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await OpenTreeHoleRepository.getInstance().modifyFloor(content, floorId);
    } catch (e, st) {
      Noticing.showModalError(context, e,
          trace: st, title: S.of(context).reply_failed);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    StateProvider.editorCache.remove(object);
    return true;
  }

  static Future<bool> reportPost(BuildContext context, int? floorId) async {
    final String? content = (await Noticing.showInputDialog(
        context, S.of(context).reason_report_post(floorId ?? "?"),
        isConfirmDestructive: true));
    if (content == null || content.trim() == "") return false;

    ProgressFuture progressDialog =
        showProgressDialog(loadingText: S.of(context).report, context: context);
    try {
      await OpenTreeHoleRepository.getInstance().reportPost(floorId, content);
    } catch (error, st) {
      Noticing.showModalError(context, error,
          trace: st, title: S.of(context).report_failed);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    return true;
  }

  static Future<PostEditorText?> _showEditor(BuildContext context, String title,
      {bool allowTags = false,
      required OTEditorType? editorType,
      required EditorObject object,
      String placeholder = "",
      bool hasTip = true}) async {
    final String randomTip = await Constant.randomFduholeTip;

    switch (editorType ?? OTEditorType.PAGE) {
      case OTEditorType.DIALOG:
        if (!StateProvider.editorCache.containsKey(object)) {
          StateProvider.editorCache[object] =
              PostEditorText.newInstance(withText: placeholder);
        }
        final textController = TextEditingController(
            text: StateProvider.editorCache[object]!.text);
        textController.addListener(() =>
            StateProvider.editorCache[object]!.text = textController.text);
        final value = await showPlatformDialog<PostEditorText>(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => PlatformAlertDialog(
                  title: Text(title),
                  content: BBSEditorWidget(
                    controller: textController,
                    allowTags: allowTags,
                    editorObject: object,
                    tip: hasTip ? randomTip : null,
                  ),
                  actions: [
                    PlatformDialogAction(
                        child: Text(S.of(context).cancel),
                        onPressed: () {
                          StateProvider.editorCache[object]!.text =
                              textController.text;
                          Navigator.of(context).pop<PostEditorText>(null);
                        }),
                    /*PlatformDialogAction(
                        child: Text(S.of(context).add_image),
                        onPressed: () => uploadImage(context, textController)),*/
                    PlatformDialogAction(
                        child: Text(S.of(context).submit),
                        onPressed: () async {
                          Navigator.of(context).pop<PostEditorText>(
                              PostEditorText(textController.text,
                                  StateProvider.editorCache[object]!.tags));
                        }),
                  ],
                ));
        textController.dispose();
        return value;
      case OTEditorType.PAGE:
        // Receive the value with **dynamic** variable to prevent automatic type inference
        final dynamic result = await smartNavigatorPush(
            context, '/bbs/fullScreenEditor',
            arguments: {
              "title": title,
              "tags": allowTags,
              'object': object,
              'placeholder': placeholder,
              'tip': randomTip
            });
        return result;
    }
  }

  @protected
  static Future<void> uploadImage(
      BuildContext context, TextEditingController _controller) async {
    final ImagePickerProxy _picker = ImagePickerProxy.createPicker();
    final String? _file = await _picker.pickImage();
    if (_file == null) return;

    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).uploading_image, context: context);
    try {
      String? url =
          await OpenTreeHoleRepository.getInstance().uploadImage(File(_file));
      if (url != null) _controller.text += "![]($url)";
      // "showAnim: true" makes it crash. Don't know the reason.
      progressDialog.dismiss(showAnim: false);
    } catch (error) {
      Noticing.showNotice(context,
          ErrorPageWidget.generateUserFriendlyDescription(S.of(context), error),
          title: S.of(context).uploading_image_failed);
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
  }
}

class BBSEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final EditorObject? editorObject;
  final bool? allowTags;
  final bool fullscreen;
  final String? tip;

  const BBSEditorWidget(
      {Key? key,
      required this.controller,
      this.allowTags,
      this.editorObject,
      this.fullscreen = false,
      this.tip})
      : super(key: key);

  @override
  _BBSEditorWidgetState createState() => _BBSEditorWidgetState();
}

class _BBSEditorWidgetState extends State<BBSEditorWidget> {
  List<OTTag>? _allTags;

  late ValueNotifier<String> previewText;

  @override
  void initState() {
    super.initState();
    // TODO: We don't need [TextEditingController] if we use [ValueNotifier]
    previewText = ValueNotifier(widget.controller.text);
    widget.controller.addListener(() {
      previewText.value = widget.controller.text;
    });
  }

  Widget _buildIntroButton(BuildContext context, IconData iconData,
      String title, String description) {
    return PlatformIconButton(
        icon: Icon(iconData, color: Theme.of(context).colorScheme.secondary),
        onPressed: () {
          showPlatformModalSheet(
              context: context,
              builder: (BuildContext context) {
                final Widget body = SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(iconData),
                            title: Text(title),
                          ),
                          const Divider(),
                          Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Linkify(
                                text: description,
                                onOpen: (element) =>
                                    BrowserUtil.openUrl(element.url, context),
                              )),
                        ]),
                  ),
                );
                if (PlatformX.isCupertino(context)) {
                  return Card(child: body);
                } else {
                  return body;
                }
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    final Widget textField = PlatformTextField(
      hintText: widget.tip,
      material: (_, __) => MaterialTextFieldData(
          decoration: widget.fullscreen
              ? const InputDecoration(border: InputBorder.none)
              : const InputDecoration(
                  border: OutlineInputBorder(gapPadding: 2.0))),
      controller: widget.controller,
      keyboardType: TextInputType.multiline,
      maxLines: widget.fullscreen ? null : 5,
      expands: widget.fullscreen,
      autofocus: true,
      textAlignVertical: TextAlignVertical.top,
    );
    if (widget.fullscreen) {
      return textField;
    }
    return SingleChildScrollView(
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.allowTags!)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ThemedMaterial(
                  child: OTTagSelector(
                      initialTags:
                          StateProvider.editorCache[widget.editorObject]!.tags),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIntroButton(
                    context,
                    IconFont.markdown,
                    S.of(context).markdown_enabled,
                    S.of(context).markdown_description),
                _buildIntroButton(
                    context,
                    IconFont.tex,
                    S.of(context).latex_enabled,
                    S.of(context).latex_description),
              ],
            ),
            textField,
            const Divider(),
            Text(S.of(context).preview,
                style: TextStyle(color: Theme.of(context).hintColor)),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: ValueListenableBuilder<String>(
                builder: (context, value, child) => smartRender(
                    context, value, null, null, false,
                    preview: true),
                valueListenable: previewText,
              ),
            ),
          ]),
    );
  }
}

class PostEditorText {
  String? text;
  List<OTTag> tags = List<OTTag>.empty(growable: true);

  PostEditorText(this.text, this.tags);

  PostEditorText.newInstance({withText = ''}) {
    text = withText;
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

  const BBSEditorPage({Key? key, this.arguments}) : super(key: key);

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  final _controller = TextEditingController();

  /// Whether the send button is enabled
  final bool _canSend = true;

  bool _isFullscreen = false;
  bool? _supportTags;

  String? _tip;
  late EditorObject _object;
  late String _title;
  late String _placeholder;

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
    _tip = widget.arguments!['tip'];
    _supportTags = widget.arguments!['tags'] ?? false;
    _title =
        widget.arguments!['title'] ?? S.of(context).forum_post_enter_content;
    _object = widget.arguments!['object'];
    _placeholder = widget.arguments!['placeholder'];
    if (StateProvider.editorCache.containsKey(_object)) {
      _controller.text = StateProvider.editorCache[_object]!.text!;
    } else {
      StateProvider.editorCache[_object] =
          PostEditorText.newInstance(withText: _placeholder);
      _controller.text = _placeholder;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    Icon fullScreenIcon = _isFullscreen
        ? (PlatformX.isMaterial(context)
            ? const Icon(Icons.close_fullscreen)
            : const Icon(CupertinoIcons.fullscreen_exit))
        : (PlatformX.isMaterial(context)
            ? const Icon(Icons.fullscreen)
            : const Icon(CupertinoIcons.fullscreen));
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(_title),
        trailingActions: [
          PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: fullScreenIcon,
              onPressed: () => setState(() => _isFullscreen = !_isFullscreen)),
          PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.photo)
                  : const Icon(CupertinoIcons.photo),
              onPressed: () => OTEditor.uploadImage(context, _controller)),
          PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.send)
                  : const Icon(CupertinoIcons.paperplane),
              onPressed: _canSend ? () => _sendDocument(_object) : null),
        ],
      ),
      body: SafeArea(
          bottom: false,
          child: Material(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BBSEditorWidget(
                    controller: _controller,
                    allowTags: _supportTags,
                    editorObject: _object,
                    fullscreen: _isFullscreen,
                    tip: _tip,
                  )))),
    );
  }

  Future<void> _sendDocument(EditorObject? object) async {
    String text = _controller.text;
    if (text.isEmpty) return;
    Navigator.pop<PostEditorText>(
        context, PostEditorText(text, StateProvider.editorCache[object]!.tags));
  }
}
