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
import 'dart:ffi';
import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/icon_fonts.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/model/danke/course_grade.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/danxi_care.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/editor_object.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/dialogs/care_dialog.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/widget/libraries/scale_transform.dart';
import 'package:dan_xi/widget/opentreehole/post_render.dart';
import 'package:dan_xi/widget/opentreehole/render/render_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:provider/provider.dart';

typedef PostInterceptor = Future<bool> Function(
    BuildContext context, CourseReviewEditorText? text);

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
  final regularText = text?.content?.toLowerCase();
  var stopWordList = await Constant.stopWords;
  stopWordList = stopWordList.map((e) => e.trim().toLowerCase()).toList();
  try {
    var checkedStopWord = stopWordList.firstWhere((element) =>
        element.isNotEmpty && (regularText?.contains(element) ?? false));
    return await Noticing.showConfirmationDialog(
            context, S.of(context).post_has_stop_words(checkedStopWord.trim()),
            title: S.of(context).post_has_stop_words_title,
            confirmText: S.of(context).continue_sending,
            isConfirmDestructive: true) ??
        false;
  } catch (_) {}
  return true;
};

class ClassRatings with ChangeNotifier {
  int classId;
  CourseGrade grade;

  ClassRatings(this.classId, this.grade);

  void copyValuesFrom(ClassRatings other) {
    classId = other.classId;
    grade=other.grade;
    notifyListeners();
  }

  void notifyChanges() {
    notifyListeners();
  }
}

class CourseReviewEditor {
  static Future<bool> createNewPost(
      BuildContext context, CourseGroup courseGroup,
      {PostInterceptor? interceptor}) async {
    final CourseReviewEditorText? content = await _showEditor(
        context, S.of(context).new_post,
        interceptor: _kStopWordInterceptor.mergeWith(interceptor),
        courseGroup: courseGroup);

    if (content?.content == null) return false;

    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await CurriculumBoardRepository.getInstance().addReview(
        courseGroup.id!, content!
      );
    } catch (e, st) {
      Noticing.showErrorDialog(context, e, trace: st);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context
        .read<FDUHoleProvider>()
        .courseReviewEditorCache
        .remove(courseGroup.code);
    return true;
  }

  static Future<bool> modifyReply(BuildContext context, CourseGroup courseGroup,
      int? floorId, String? originalContent,
      {PostInterceptor? interceptor}) async {
    final String? content = (await _showEditor(
            context, S.of(context).modify_to("?"),
            placeholder: originalContent ?? "",
            interceptor: _kStopWordInterceptor.mergeWith(interceptor),
            courseGroup: courseGroup))
        ?.content;
    if (content == null || content.trim().isEmpty) return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await OpenTreeHoleRepository.getInstance().modifyFloor(content, floorId);
    } catch (e, st) {
      Noticing.showErrorDialog(context, e,
          trace: st, title: S.of(context).reply_failed);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context
        .read<FDUHoleProvider>()
        .courseReviewEditorCache
        .remove(courseGroup.code);
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
      Noticing.showErrorDialog(context, error,
          trace: st, title: S.of(context).report_failed);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    return true;
  }

  static Future<CourseReviewEditorText?> _showEditor(
      BuildContext context, String title,
      {required CourseGroup courseGroup,
      String placeholder = "",
      bool hasTip = true,
      PostInterceptor? interceptor}) async {
    final String randomTip = await Constant.randomFDUHoleTip;

    // Receive the value with **dynamic** variable to prevent automatic type inference
    final dynamic result = await smartNavigatorPush(
        context, '/danke/fullScreenEditor',
        arguments: {
          "title": title,
          "course_group": courseGroup,
          'placeholder': placeholder,
          'tip': randomTip,
          'interceptor': interceptor
        });
    return result;
  }
}

class CourseReviewEditorWidget extends StatefulWidget {
  final TextEditingController contentController, titleController;
  final String? courseCode;
  final bool fullscreen;
  final String? tip;
  final ClassRatings ratings;

  const CourseReviewEditorWidget(
      {Key? key,
      required this.titleController,
      required this.contentController,
      this.courseCode,
      this.fullscreen = false,
      this.tip,
      required this.courseGroup,
      required this.ratings})
      : super(key: key);

  final CourseGroup courseGroup;

  @override
  CourseReviewEditorWidgetState createState() =>
      CourseReviewEditorWidgetState();
}

class CourseReviewEditorWidgetState extends State<CourseReviewEditorWidget> {
  @override
  void initState() {
    super.initState();
  }

  final GlobalKey<DropdownListWidgetState<Course>> _timeSelectorKey =
      GlobalKey<DropdownListWidgetState<Course>>();
  final GlobalKey<DropdownListWidgetState<String>> _teacherSelectorKey =
      GlobalKey<DropdownListWidgetState<String>>();

  ValueNotifier<String> teacherFilterNotifier = ValueNotifier("*");
  Course? currentCourse;

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
      controller: widget.contentController,
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
            Text(widget.courseGroup.code!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    fontSize: 20)),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                    flex: 1,
                    child: DropdownListWidget(
                      key: _teacherSelectorKey,
                      items: widget.courseGroup.courseList!
                          .map((e) => e.teachers!)
                          .toSet()
                          .toList(),
                      hintText: "请选择教师",
                      labelText: "教师",
                      onChanged: (e) {
                        teacherFilterNotifier.value =
                            _teacherSelectorKey.currentState!.selectedItem!;
                      },
                      itemBuilder: (e) =>
                          DropdownMenuItem(value: e, child: Text(e)),
                    )),
                Expanded(
                    flex: 1,
                    child: ValueListenableBuilder(
                      builder: (context, value, child) =>
                          DropdownListWidget<Course>(
                              key: _timeSelectorKey,
                              items: value == "*"
                                  ? []
                                  : widget.courseGroup.courseList!
                                      .filter((e) => e.teachers == value),
                              hintText: "请选择时间",
                              labelText: "上课时间",
                              onChanged: (e) {
                                widget.ratings.classId = e!.subId!;
                                widget.ratings.notifyChanges();
                              },
                              itemBuilder: (e) => DropdownMenuItem(
                                  value: e, child: Text(e.formatTime()))),
                      valueListenable: teacherFilterNotifier,
                    )),
              ]),
            ),
            PlatformTextField(
              hintText: "请输入标题",
              material: (_, __) => MaterialTextFieldData(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(gapPadding: 2.0))),
              controller: widget.titleController,
              keyboardType: TextInputType.multiline,
              maxLines: widget.fullscreen ? null : 5,
              expands: widget.fullscreen,
              autofocus: true,
              textAlignVertical: TextAlignVertical.top,
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
                PlatformTextButton(
                  child: Text(S.of(context).community_convention),
                  onPressed: () => BrowserUtil.openUrl(
                      "https://www.fduhole.com/#/licence", context),
                )
              ],
            ),
            textField,
            const Divider(),
            CourseRatingWidget(
              label: "总体评价",
              words: overallWord,
              onRate: (e) {
                widget.ratings.grade.overall = e;
                widget.ratings.notifyChanges();
              },
            ),
            CourseRatingWidget(
                label: "课程风格",
                words: styleWord,
                onRate: (e) {
                  widget.ratings.grade.style = e;
                  widget.ratings.notifyChanges();
                }),
            CourseRatingWidget(
              label: "工作量",
              words: workloadWord,
              onRate: (e) {
                widget.ratings.grade.workload = e;
                widget.ratings.notifyChanges();
              },
            ),
            CourseRatingWidget(
              label: "考核要求",
              words: assessmentWord,
              onRate: (e) {
                widget.ratings.grade.assessment = e;
                widget.ratings.notifyChanges();
              },
            ),
          ]),
    );
  }
}

class DropdownListWidget<T> extends StatefulWidget {
  const DropdownListWidget(
      {super.key,
      required this.items,
      required this.hintText,
      required this.labelText,
      required this.itemBuilder,
      required this.onChanged});

  final List<T> items;
  final String hintText;
  final String labelText;
  final DropdownMenuItem<T> Function(T) itemBuilder;
  final void Function(T?) onChanged;

  @override
  DropdownListWidgetState<T> createState() => DropdownListWidgetState<T>();
}

class DropdownListWidgetState<T> extends State<DropdownListWidget<T>> {
  T? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.labelText),
          DropdownButton<T>(
            value: selectedItem,
            hint: Text(widget.hintText),
            icon: const Icon(Icons.arrow_drop_down),
            underline: Container(height: 2, color: Colors.grey),
            items: [...widget.items.map((e) => widget.itemBuilder(e))],
            onChanged: (T? value) {
              setState(() {
                selectedItem = value;
              });
              widget.onChanged(value);
            },
          )
        ]));
  }

  @override
  void didUpdateWidget(covariant DropdownListWidget<T> old) {
    super.didUpdateWidget(old);
    selectedItem = null;
  }
}

class CourseRatingWidget extends StatefulWidget {
  final void Function(int) onRate;
  final String label;
  final List<String> words;

  const CourseRatingWidget(
      {super.key,
      required this.label,
      required this.onRate,
      required this.words});

  @override
  CourseRatingWidgetState createState() => CourseRatingWidgetState();
}

class CourseRatingWidgetState extends State<CourseRatingWidget> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    var mainColor = rating > 0 ? wordColor[rating - 1] : Colors.white70;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 80, child: Text(widget.label)),
          Row(
            children: List.generate(
                5,
                (index) => IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                      widget.onRate(rating);
                    },
                    icon: Icon(index < rating ? Icons.star : Icons.star_border,
                        color: mainColor))),
          ),
          const SizedBox(width: 10),
          Text(rating > 0 ? widget.words[rating - 1] : "",
              style: TextStyle(color: mainColor))
        ]));
  }
}

class CourseReviewEditorText {
  String? content, title;
  ClassRatings ratings = ClassRatings(-1, CourseGrade(0, 0, 0, 0));

  CourseReviewEditorText(this.content, this.ratings);

  CourseReviewEditorText.newInstance({withContent = '', withTitle = ''}) {
    content = withContent;
    title = withTitle;
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
class CourseReviewEditorPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CourseReviewEditorPage({Key? key, this.arguments}) : super(key: key);

  @override
  CourseReviewEditorPageState createState() => CourseReviewEditorPageState();
}

class CourseReviewEditorPageState extends State<CourseReviewEditorPage> {
  final _contentController = TextEditingController(),
      _titleController = TextEditingController();
  final ClassRatings ratings = ClassRatings(-1, CourseGrade(0, 0, 0, 0));

  /// Whether the send button is enabled
  final bool _canSend = true;

  bool _isFullscreen = false;
  bool _confirmCareWords = false;

  String? _tip;
  late String _title;
  late String _placeholder;
  late CourseGroup _courseGroup;

  PostInterceptor? _interceptor;

  @override
  void initState() {
    super.initState();

    _contentController.addListener(() {
      context
          .read<FDUHoleProvider>()
          .courseReviewEditorCache[_courseGroup.code]!
          .content = _contentController.text;
    });

    _titleController.addListener(() {
      context
          .read<FDUHoleProvider>()
          .courseReviewEditorCache[_courseGroup.code]!
          .title = _titleController.text;
    });

    ratings.addListener(() {
      context
          .read<FDUHoleProvider>()
          .courseReviewEditorCache[_courseGroup.code]!
          .ratings
          .copyValuesFrom(ratings);
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _interceptor = widget.arguments?['interceptor'];
    _courseGroup = widget.arguments!['course_group'];
    _tip = widget.arguments!['tip'];
    _title =
        widget.arguments!['title'] ?? S.of(context).forum_post_enter_content;
    _placeholder = widget.arguments!['placeholder'];
    if (context
        .read<FDUHoleProvider>()
        .courseReviewEditorCache
        .containsKey(_courseGroup.code)) {
      _titleController.text = context
          .read<FDUHoleProvider>()
          .courseReviewEditorCache[_courseGroup.code]!
          .content!;
      _contentController.text = context
          .read<FDUHoleProvider>()
          .courseReviewEditorCache[_courseGroup.code]!
          .title!;
      ratings.copyValuesFrom(context
          .read<FDUHoleProvider>()
          .courseReviewEditorCache[_courseGroup.code]!
          .ratings);
    } else {
      context
              .read<FDUHoleProvider>()
              .courseReviewEditorCache[_courseGroup.code] =
          CourseReviewEditorText.newInstance(withContent: _placeholder);
      _contentController.text = _placeholder;
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
                ? const Icon(Icons.send)
                : const Icon(CupertinoIcons.paperplane),
            onPressed: _canSend
                ? () async {
                    bool isCareWordsDetected =
                        await detectCareWords(_contentController.text);
                    // only show once
                    if (context.mounted == true &&
                        isCareWordsDetected == true &&
                        _confirmCareWords == false) {
                      await showPlatformDialog(
                          context: context, builder: (_) => const CareDialog());
                      _confirmCareWords = true;
                      return;
                    }
                    _sendDocument(_courseGroup.code);
                  }
                : null,
          ),
        ],
      ),
      body: SafeArea(
          bottom: false,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: CourseReviewEditorWidget(
                contentController: _contentController,
                titleController: _titleController,
                courseCode: _courseGroup.code,
                fullscreen: _isFullscreen,
                tip: _tip,
                courseGroup: _courseGroup,
                ratings: ratings,
              ))),
    );
  }

  Future<void> _sendDocument(String? code) async {
    String text = _contentController.text;
    if (text.isEmpty) return;
    final editorText = CourseReviewEditorText(text, ratings);

    if ((await _interceptor?.call(context, editorText)) ?? true) {
      Navigator.pop<CourseReviewEditorText>(context, editorText);
    }
  }
}
