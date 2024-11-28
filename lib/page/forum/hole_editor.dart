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
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/forum/hole_detail.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/danxi_care.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/forum/editor_object.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stickers.dart';
import 'package:dan_xi/widget/dialogs/care_dialog.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/image_picker_proxy.dart';
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:dan_xi/widget/libraries/scale_transform.dart';
import 'package:dan_xi/widget/forum/ottag_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:provider/provider.dart';

enum OTEditorType { DIALOG, PAGE }

typedef PostInterceptor = Future<bool> Function(
    BuildContext context, PostEditorText? text);

extension PostInterceptorEx on PostInterceptor {
  PostInterceptor mergeWith(PostInterceptor? interceptor) {
    if (interceptor == null) return this;
    return (context, text) async {
      if (await this.call(context, text)) {
        return interceptor.call(context, text);
      } else {
        return false;
      }
    };
  }
}

final PostInterceptor _kStopWordInterceptor = (context, text) async {
  final regularText = text?.text?.toLowerCase();
  var stopWordList = await Constant.stopWords;
  stopWordList = stopWordList.map((e) => e.trim().toLowerCase()).toList();
  try {
    var checkedStopWord = stopWordList.firstWhere((element) =>
        element.isNotEmpty && (regularText?.contains(element) ?? false));
    return await Noticing.showConfirmationDialog(
            context, S.of(context).has_stop_words(checkedStopWord.trim()),
            title: S.of(context).has_stop_words_title,
            confirmText: S.of(context).continue_sending,
            isConfirmDestructive: true) ??
        false;
  } catch (_) {}
  return true;
};

class OTEditor {
  static Future<bool> createNewPost(BuildContext context, int divisionId,
      {OTEditorType? editorType, PostInterceptor? interceptor}) async {
    final object = EditorObject(0, EditorObjectType.NEW_POST);
    final PostEditorText? content = await _showEditor(
        context, S.of(context).new_post,
        allowTags: true,
        editorType: editorType,
        object: object,
        interceptor: _kStopWordInterceptor.mergeWith(interceptor));

    if (content?.text == null) {
      return false;
    }

    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await ForumRepository.getInstance()
          .newHole(divisionId, content!.text, tags: content.tags);
    } catch (e, st) {
      Noticing.showErrorDialog(context, e, trace: st);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context.read<ForumProvider>().editorCache.remove(object);
    return true;
  }

  static Future<bool> createNewReply(
      BuildContext context, int? discussionId, int? floorId,
      {OTEditorType? editorType, PostInterceptor? interceptor}) async {
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
            placeholder: floorId == null ? "" : "##$floorId\n",
            interceptor: _kStopWordInterceptor.mergeWith(interceptor)))
        ?.text;
    if (content == null || content.trim() == "") return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await ForumRepository.getInstance().newFloor(discussionId, content);
    } catch (e, st) {
      Noticing.showErrorDialog(context, e, trace: st);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context.read<ForumProvider>().editorCache.remove(object);
    return true;
  }

  static Future<bool> modifyReply(BuildContext context, int? discussionId,
      int? floorId, String? originalContent,
      {OTEditorType? editorType, PostInterceptor? interceptor}) async {
    final object = EditorObject(floorId, EditorObjectType.MODIFY_FLOOR);
    final String? content = (await _showEditor(
            context,
            floorId == null
                ? S.of(context).modify_to(discussionId ?? "?")
                : S.of(context).modify_to_floor(floorId),
            editorType: editorType,
            object: object,
            placeholder: originalContent ?? "",
            interceptor: _kStopWordInterceptor.mergeWith(interceptor)))
        ?.text;
    if (content == null || content.trim().isEmpty) return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await ForumRepository.getInstance().modifyFloor(content, floorId);
    } catch (e, st) {
      Noticing.showErrorDialog(context, e,
          trace: st, title: S.of(context).reply_failed);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context.read<ForumProvider>().editorCache.remove(object);
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
      await ForumRepository.getInstance().reportPost(floorId, content);
    } catch (error, st) {
      Noticing.showErrorDialog(context, error,
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
      bool hasTip = true,
      PostInterceptor? interceptor}) async {
    final String randomTip = await Constant.randomForumTip;

    switch (editorType ?? OTEditorType.PAGE) {
      case OTEditorType.DIALOG:
        if (!context.read<ForumProvider>().editorCache.containsKey(object)) {
          context.read<ForumProvider>().editorCache[object] =
              PostEditorText.newInstance(withText: placeholder);
        }
        final textController = TextEditingController(
            text: context.read<ForumProvider>().editorCache[object]!.text);
        textController.addListener(() => context
            .read<ForumProvider>()
            .editorCache[object]!
            .text = textController.text);
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
                          context
                              .read<ForumProvider>()
                              .editorCache[object]!
                              .text = textController.text;
                          Navigator.of(context).pop<PostEditorText>(null);
                        }),
                    /*PlatformDialogAction(
                        child: Text(S.of(context).add_image),
                        onPressed: () => uploadImage(context, textController)),*/
                    PlatformDialogAction(
                        child: Text(S.of(context).submit),
                        onPressed: () async {
                          Navigator.of(context).pop<PostEditorText>(
                              PostEditorText(
                                  textController.text,
                                  context
                                      .read<ForumProvider>()
                                      .editorCache[object]!
                                      .tags));
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
              'tip': randomTip,
              'interceptor': interceptor
            });
        return result;
    }
  }

  @protected
  static Future<void> uploadImage(
      BuildContext context, TextEditingController controller) async {
    final ImagePickerProxy picker = ImagePickerProxy.createPicker();
    final String? file = await picker.pickImage();
    if (file == null) return;

    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).uploading_image, context: context);
    try {
      String? url = await ForumRepository.getInstance().uploadImage(File(file));
      if (url != null) controller.text += "![]($url)";
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
      {super.key,
      required this.controller,
      this.allowTags,
      this.editorObject,
      this.fullscreen = false,
      this.tip});

  @override
  BBSEditorWidgetState createState() => BBSEditorWidgetState();
}

class BBSEditorWidgetState extends State<BBSEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  final GlobalKey<OTTagSelectorState> _tagSelectorKey =
      GlobalKey<OTTagSelectorState>();

  Future<T?> _buildStickersSheet<T>(BuildContext context) {
    int stickerSheetColumns = 5;
    int stickerSheetRows =
        (Stickers.values.length / stickerSheetColumns).ceil();

    return showPlatformModalSheet(
        context: context,
        builder: (BuildContext context) {
          final Widget body = Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                      leading: const Icon(Icons.emoji_emotions),
                      title: Text(S.of(context).sticker)),
                  // const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LayoutGrid(
                          columnSizes: List.filled(stickerSheetColumns, 1.fr),
                          rowSizes: List.filled(stickerSheetRows, auto),
                          rowGap: 8,
                          columnGap: 8,
                          children: Stickers.values.map((e) {
                            return Container(
                              alignment: Alignment.center,
                              child: InkWell(
                                onTap: () {
                                  var cursorPosition =
                                      widget.controller.selection.base.offset;
                                  cursorPosition = cursorPosition == -1
                                      ? widget.controller.text.length
                                      : cursorPosition;
                                  widget.controller.text =
                                      "${widget.controller.text.substring(0, cursorPosition)}![](${e.name})${widget.controller.text.substring(cursorPosition)}";
                                  Navigator.of(context).pop();
                                },
                                child: Image.asset(
                                  getStickerAssetPath(e.name)!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ]),
          );
          return PlatformX.isCupertino(context)
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: 0.66 * MediaQuery.of(context).size.height),
                  child: Card(child: body))
              : body;
        });
  }

  Widget _buildIntroButton(BuildContext context, IconData iconData,
          String title, String description) =>
      PlatformIconButton(
          icon: Icon(iconData, color: Theme.of(context).colorScheme.secondary),
          onPressed: () => showPlatformModalSheet(
              context: context,
              builder: (BuildContext context) {
                final Widget body = SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(leading: Icon(iconData), title: Text(title)),
                          const Divider(),
                          Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: LinkifyX(
                                text: description,
                                onOpen: (element) =>
                                    BrowserUtil.openUrl(element.url, context),
                              )),
                        ]),
                  ),
                );
                return PlatformX.isCupertino(context)
                    ? Card(child: body)
                    : body;
              }));

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
                padding: const EdgeInsets.only(bottom: 8),
                child: OTTagSelector(
                    key: _tagSelectorKey,
                    initialTags: context
                        .read<ForumProvider>()
                        .editorCache[widget.editorObject]!
                        .tags),
              ),
            if (widget.allowTags! &&
                SettingsProvider.getInstance().tagSuggestionAvailable) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Row(
                  children: [
                    Text(S.of(context).recommended_tags),
                    ScaleTransform(
                      scale: 0.75,
                      child: PlatformIconButton(
                        padding: const EdgeInsets.only(left: 0),
                        icon: const Icon(CupertinoIcons.info_circle),
                        onPressed: () {
                          Noticing.showModalNotice(context,
                              message:
                                  S.of(context).recommended_tags_description,
                              title: S.of(context).recommended_tags);
                        },
                      ),
                    ),
                    Selector<SettingsProvider, bool>(
                        builder: (_, bool value, __) {
                          if (!value) {
                            return PlatformTextButton(
                              padding: EdgeInsets.zero,
                              child: Text(S.of(context).enable),
                              onPressed: () async {
                                if (await Noticing.showConfirmationDialog(
                                        context,
                                        S
                                            .of(context)
                                            .recommended_tags_description,
                                        title:
                                            S.of(context).recommended_tags) ==
                                    true) {
                                  SettingsProvider.getInstance()
                                      .isTagSuggestionEnabled = true;
                                }
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        selector: (_, model) => model.isTagSuggestionEnabled),
                  ],
                ),
              ),
              Selector<SettingsProvider, bool>(
                  builder: (_, bool value, __) {
                    if (value) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                        child: ValueListenableBuilder<TextEditingValue>(
                          builder: (context, value, child) =>
                              TagSuggestionWidget(
                            content: value.text,
                            tagSelectorKey: _tagSelectorKey,
                          ),
                          valueListenable: widget.controller,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  selector: (_, model) => model.isTagSuggestionEnabled),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                  PlatformTextButton(
                    child: Text(S.of(context).community_convention),
                    onPressed: () => BrowserUtil.openUrl(
                        "https://www.fduhole.com/doc", context),
                  ),
                  PlatformTextButton(
                    child: Text(S.of(context).sticker),
                    onPressed: () => _buildStickersSheet(context),
                  ),
                ],
              ),
            ),
            textField,
            const Divider(),
            Text(S.of(context).preview,
                style: TextStyle(color: Theme.of(context).hintColor)),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: ValueListenableBuilder<TextEditingValue>(
                builder: (context, value, child) => smartRender(
                    context, value.text, null, null, false,
                    preview: true),
                valueListenable: widget.controller,
              ),
            ),
          ]),
    );
  }
}

class TagSuggestionWidget extends StatefulWidget {
  const TagSuggestionWidget(
      {super.key, required this.content, required this.tagSelectorKey});

  final String content;
  final GlobalKey<OTTagSelectorState> tagSelectorKey;

  @override
  TagSuggestionWidgetState createState() => TagSuggestionWidgetState();
}

Future<List<String>?> getTagSuggestions(String content) async {
  try {
    return await forumChannel.invokeListMethod("get_tag_suggestions", content);
  } on PlatformException catch (_) {
    return null;
  } on MissingPluginException catch (_) {
    return null;
  }
}

class TagSuggestionWidgetState extends State<TagSuggestionWidget> {
  List<String>? _suggestions;

  void updateTagSuggestions() {
    getTagSuggestions(widget.content).then((value) {
      setState(() {
        _suggestions = value;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    updateTagSuggestions();
  }

  @override
  void didUpdateWidget(covariant TagSuggestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateTagSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Wrap(
          children: _suggestions
                  ?.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        child: RoundChip(
                            label: e,
                            color: (e.hashColor()),
                            onTap: () {
                              widget.tagSelectorKey.currentState?.setState(() {
                                if (widget.tagSelectorKey.currentState?.widget
                                        .initialTags
                                        .any((element) => element.name == e) ==
                                    true) {
                                } else {
                                  widget.tagSelectorKey.currentState!.widget
                                      .initialTags
                                      .add(OTTag(0, 0, e));
                                }
                              });
                            }),
                      ))
                  .toList() ??
              []),
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

  const BBSEditorPage({super.key, this.arguments});

  @override
  BBSEditorPageState createState() => BBSEditorPageState();
}

class BBSEditorPageState extends State<BBSEditorPage> {
  final _controller = TextEditingController();

  /// Whether the send button is enabled
  final bool _canSend = true;

  bool _isFullscreen = false;
  bool? _supportTags;
  bool _confirmCareWords = false;

  String? _tip;
  late EditorObject _object;
  late String _title;
  late String _placeholder;

  PostInterceptor? _interceptor;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      context.read<ForumProvider>().editorCache[_object]!.text =
          _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _interceptor = widget.arguments?['interceptor'];
    _tip = widget.arguments!['tip'];
    _supportTags = widget.arguments!['tags'] ?? false;
    _title =
        widget.arguments!['title'] ?? S.of(context).forum_post_enter_content;
    _object = widget.arguments!['object'];
    _placeholder = widget.arguments!['placeholder'];
    if (context.read<ForumProvider>().editorCache.containsKey(_object)) {
      _controller.text =
          context.read<ForumProvider>().editorCache[_object]!.text!;
    } else {
      context.read<ForumProvider>().editorCache[_object] =
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
            onPressed: _canSend
                ? () async {
                    bool isCareWordsDetected =
                        await detectCareWords(_controller.text);
                    // only show once
                    if (context.mounted == true &&
                        isCareWordsDetected == true &&
                        _confirmCareWords == false) {
                      await showPlatformDialog(
                          context: context, builder: (_) => const CareDialog());
                      _confirmCareWords = true;
                      return;
                    }
                    _sendDocument(_object);
                  }
                : null,
          ),
        ],
      ),
      body: SafeArea(
          bottom: false,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: BBSEditorWidget(
                controller: _controller,
                allowTags: _supportTags,
                editorObject: _object,
                fullscreen: _isFullscreen,
                tip: _tip,
              ))),
    );
  }

  Future<void> _sendDocument(EditorObject? object) async {
    String text = _controller.text;
    if (text.isEmpty) return;
    final editorText = PostEditorText(
        text, context.read<ForumProvider>().editorCache[object]!.tags);

    if ((await _interceptor?.call(context, editorText)) ?? true) {
      Navigator.pop<PostEditorText>(context, editorText);
    }
  }
}
