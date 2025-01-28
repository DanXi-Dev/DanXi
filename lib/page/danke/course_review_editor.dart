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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/icon_fonts.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/model/danke/course_grade.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/page/forum/hole_detail.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
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
            context, S.of(context).has_stop_words(checkedStopWord.trim()),
            title: S.of(context).has_stop_words_title,
            confirmText: S.of(context).continue_sending,
            isConfirmDestructive: true) ??
        false;
  } catch (_) {}
  return true;
};

class CourseReviewEditorText with ChangeNotifier {
  int _courseId = -1;
  CourseGrade _grade = CourseGrade(0, 0, 0, 0);
  String? _content, _title;

  int get courseId => _courseId;

  set courseId(int val) {
    _courseId = val;
    notifyListeners();
  }

  CourseGrade get grade => _grade;

  set grade(CourseGrade val) {
    _grade = val;
    notifyListeners();
  }

  String? get content => _content;

  set content(String? val) {
    _content = val;
    notifyListeners();
  }

  String? get title => _title;

  set title(String? val) {
    _title = val;
    notifyListeners();
  }

  CourseReviewEditorText(
      this._content, this._title, this._courseId, this._grade);

  void copyValuesFrom(CourseReviewEditorText other) {
    _courseId = other._courseId;
    _grade = other._grade;
    _content = other._content;
    _title = other._title;
    notifyListeners();
  }

  bool isValid() {
    return (_content ?? "").isNotEmpty &&
        (_title ?? "").isNotEmpty &&
        _courseId >= 0 &&
        _inRange(_grade.overall ?? 0) &&
        _inRange(_grade.content ?? 0) &&
        _inRange(_grade.workload ?? 0) &&
        _inRange(_grade.assessment ?? 0);
  }

  static bool _inRange(int val, [int min = 1, int max = 5]) {
    return val >= min && val <= max;
  }

  CourseReviewEditorText.newInstance({withContent = '', withTitle = ''}) {
    _content = withContent;
    _title = withTitle;
  }
}

class CourseReviewEditor {
  static Future<bool> createNewPost(
      BuildContext context, CourseGroup courseGroup,
      {PostInterceptor? interceptor}) async {
    final CourseReviewEditorText? post = await _showEditor(
        context, S.of(context).new_post,
        interceptor: _kStopWordInterceptor.mergeWith(interceptor),
        courseGroup: courseGroup,
        isModify: false);

    if (post == null) {
      return false;
    }

    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await CurriculumBoardRepository.getInstance().addReview(post);
    } catch (e, st) {
      Noticing.showErrorDialog(context, e, trace: st);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context
        .read<ForumProvider>()
        .courseReviewEditorCache
        .remove(courseGroup.code);
    return true;
  }

  static Future<bool> modifyReply(BuildContext context, CourseGroup courseGroup,
      CourseReview originalContent,
      {PostInterceptor? interceptor}) async {
    var initialContent = CourseReviewEditorText(
        originalContent.content!,
        originalContent.title!,
        originalContent.courseInfo.id,
        originalContent.rank!);
    final CourseReviewEditorText? content = await _showEditor(
        context, S.of(context).modify_to(originalContent.reviewId!),
        initialContent: initialContent,
        interceptor: _kStopWordInterceptor.mergeWith(interceptor),
        courseGroup: courseGroup,
        isModify: true);
    if (content == null) return false;
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).posting, context: context);
    try {
      await CurriculumBoardRepository.getInstance()
          .modifyReview(originalContent.reviewId!, content);
    } catch (e, st) {
      Noticing.showErrorDialog(context, e,
          trace: st, title: S.of(context).reply_failed);
      return false;
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
    context
        .read<ForumProvider>()
        .courseReviewEditorCache
        .remove(courseGroup.code);
    return true;
  }

  static Future<CourseReviewEditorText?> _showEditor(
      BuildContext context, String title,
      {required CourseGroup courseGroup,
      CourseReviewEditorText? initialContent,
      PostInterceptor? interceptor,
      bool isModify = false}) async {
    // Receive the value with **dynamic** variable to prevent automatic type inference
    final dynamic result = await smartNavigatorPush(
        context, '/danke/fullScreenEditor',
        arguments: {
          "title": title,
          "course_group": courseGroup,
          'initial_content': initialContent,
          'interceptor': interceptor,
          'modify': isModify
        });
    return result;
  }
}

class CourseReviewEditorWidget extends StatefulWidget {
  final bool fullscreen;
  final bool focusContent;
  final CourseReviewEditorText review;

  const CourseReviewEditorWidget(
      {super.key,
      this.fullscreen = false,
      required this.courseGroup,
      required this.review,
      this.focusContent = false});

  final CourseGroup courseGroup;

  @override
  CourseReviewEditorWidgetState createState() =>
      CourseReviewEditorWidgetState();
}

class CourseReviewEditorWidgetState extends State<CourseReviewEditorWidget> {
  late CourseReviewEditorText review;
  late TextEditingController contentController, titleController;

  @override
  void initState() {
    super.initState();
    review = widget.review;
    contentController = TextEditingController(text: review.content);
    titleController = TextEditingController(text: review.title);
  }

  @override
  void didUpdateWidget(covariant CourseReviewEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    review = widget.review;
  }

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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget textField = PlatformTextField(
      hintText: S.of(context).curriculum_enter_content,
      material: (_, __) => MaterialTextFieldData(
          decoration: widget.fullscreen
              ? const InputDecoration(border: InputBorder.none)
              : const InputDecoration(
                  border: OutlineInputBorder(gapPadding: 2.0))),
      keyboardType: TextInputType.multiline,
      maxLines: widget.fullscreen ? null : 5,
      expands: widget.fullscreen,
      autofocus: widget.focusContent || widget.fullscreen,
      textAlignVertical: TextAlignVertical.top,
      controller: contentController,
      onChanged: (text) {
        review.content = text;
      },
    );

    if (widget.fullscreen) {
      return textField;
    }

    int index = widget.courseGroup.courseList!
        .indexWhere((element) => element.id == review.courseId);
    Course? selectedCourse =
        index >= 0 ? widget.courseGroup.courseList![index] : null;
    if (selectedCourse != null) {
      teacherFilterNotifier.value = selectedCourse.teachers!;
    }

    final overallWord =
        S.of(context).curriculum_ratings_overall_words.split(';');
    final contentWord =
        S.of(context).curriculum_ratings_content_words.split(';');
    final workloadWord =
        S.of(context).curriculum_ratings_workload_words.split(';');
    final assessmentWord =
        S.of(context).curriculum_ratings_assessment_words.split(';');

    // Reduce the line height to fit into the dropdown list
    final listItemStyle = const TextStyle(height: 1.0);

    return ChangeNotifierProvider(
        create: (_) => review.grade.clone(),
        child: SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.courseGroup.code!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 20)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                        flex: 1,
                        child: DropdownListWidget(
                          initialSelection: selectedCourse?.teachers,
                          items: widget.courseGroup.courseList!
                              .map((e) => e.teachers!)
                              .toSet()
                              .toList(),
                          hintText: S.of(context).curriculum_select_teacher,
                          labelText: S.of(context).course_teacher_name,
                          onChanged: (e) {
                            teacherFilterNotifier.value = e!;
                          },
                          itemBuilder: (e) => DropdownMenuItem(
                              value: e,
                              child: AutoSizeText(
                                e,
                                style: listItemStyle,
                              )),
                        )),
                    Expanded(
                        flex: 1,
                        child: ValueListenableBuilder(
                          builder: (context, value, child) =>
                              DropdownListWidget<Course>(
                                  initialSelection: selectedCourse,
                                  items: value == "*"
                                      ? []
                                      : widget.courseGroup.courseList!
                                          .filter((e) => e.teachers == value),
                                  hintText:
                                      S.of(context).curriculum_select_time,
                                  labelText: S.of(context).course_schedule,
                                  onChanged: (e) {
                                    review.courseId = e!.id!;
                                  },
                                  itemBuilder: (e) => DropdownMenuItem(
                                      value: e,
                                      child: AutoSizeText(
                                        e.formatTime(),
                                        style: listItemStyle,
                                      ))),
                          valueListenable: teacherFilterNotifier,
                        )),
                  ]),
                ),
                PlatformTextField(
                  hintText: S.of(context).curriculum_enter_title,
                  material: (_, __) => MaterialTextFieldData(
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(gapPadding: 2.0))),
                  keyboardType: TextInputType.multiline,
                  maxLines: 1,
                  expands: false,
                  autofocus: !widget.focusContent,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (text) {
                    review.title = text;
                  },
                  controller: titleController,
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
                          "https://www.fduhole.com/doc", context),
                    )
                  ],
                ),
                textField,
                const Divider(),
                LayoutGrid(
                  columnSizes: [1.fr, auto, 1.fr],
                  rowSizes: const [auto, auto, auto, auto],
                  children: [
                    Center(
                        child: Text(S.of(context).curriculum_ratings_overall)),
                    Builder(
                        builder: (ctx) => RatingStarWidget(
                              initialRating: review.grade.overall,
                              onRate: (e) {
                                final grade = Provider.of<CourseGrade>(ctx,
                                    listen: false);
                                grade.overall = e;
                                // Notify cache update
                                review.grade = grade.clone();
                              },
                            )),
                    Consumer<CourseGrade>(
                        builder: (ctx, grade, _) => RatingTextWidget(
                            words: overallWord, rating: grade.overall ?? 0)),
                    Center(
                        child: Text(S.of(context).curriculum_ratings_content)),
                    Builder(
                        builder: (ctx) => RatingStarWidget(
                            initialRating: review.grade.content,
                            onRate: (e) {
                              final grade =
                                  Provider.of<CourseGrade>(ctx, listen: false);
                              grade.content = e;
                              // Notify cache update
                              review.grade = grade.clone();
                            })),
                    Consumer<CourseGrade>(
                        builder: (ctx, grade, _) => RatingTextWidget(
                            words: contentWord, rating: grade.content ?? 0)),
                    Center(
                        child: Text(S.of(context).curriculum_ratings_workload)),
                    Builder(
                        builder: (ctx) => RatingStarWidget(
                              initialRating: review.grade.workload,
                              onRate: (e) {
                                final grade = Provider.of<CourseGrade>(ctx,
                                    listen: false);
                                grade.workload = e;
                                // Notify cache update
                                review.grade = grade.clone();
                              },
                            )),
                    Consumer<CourseGrade>(
                        builder: (ctx, grade, _) => RatingTextWidget(
                            words: workloadWord, rating: grade.workload ?? 0)),
                    Center(
                        child:
                            Text(S.of(context).curriculum_ratings_assessment)),
                    Builder(
                        builder: (ctx) => RatingStarWidget(
                              initialRating: review.grade.assessment,
                              onRate: (e) {
                                final grade = Provider.of<CourseGrade>(ctx,
                                    listen: false);
                                grade.assessment = e;
                                // Notify cache update
                                review.grade = grade.clone();
                              },
                            )),
                    Consumer<CourseGrade>(
                        builder: (ctx, grade, _) => RatingTextWidget(
                            words: assessmentWord,
                            rating: grade.assessment ?? 0)),
                  ],
                ),
                const Divider(),
                Text(S.of(context).preview,
                    style: TextStyle(color: Theme.of(context).hintColor)),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: ValueListenableBuilder<TextEditingValue>(
                    builder: (context, value, child) => smartRender(
                        context, value.text, null, null, false,
                        preview: true),
                    valueListenable: contentController,
                  ),
                ),
              ]),
        ));
  }
}

class DropdownListWidget<T> extends StatefulWidget {
  const DropdownListWidget(
      {super.key,
      required this.items,
      required this.hintText,
      required this.labelText,
      required this.itemBuilder,
      required this.onChanged,
      this.initialSelection});

  final List<T> items;
  final String hintText;
  final String labelText;
  final T? initialSelection;
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
            isExpanded: true,
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
  void didUpdateWidget(covariant DropdownListWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _initializeSelection();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    if (widget.initialSelection != null) {
      var index = widget.items.indexOf(widget.initialSelection as T);
      selectedItem = index >= 0 ? widget.items[index] : null;
    } else {
      selectedItem = null;
    }
  }
}

class RatingStarWidget extends StatefulWidget {
  final void Function(int) onRate;
  final int? initialRating;

  const RatingStarWidget({super.key, required this.onRate, this.initialRating});

  @override
  RatingStarWidgetState createState() => RatingStarWidgetState();
}

class RatingStarWidgetState extends State<RatingStarWidget> {
  int rating = 0;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating ?? 0;
  }

  @override
  void didUpdateWidget(covariant RatingStarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    rating = widget.initialRating ?? rating;
  }

  @override
  Widget build(BuildContext context) {
    var mainColor = rating > 0
        ? wordColor[rating - 1]
        : Theme.of(context).textTheme.bodyLarge!.color;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
                5,
                (index) => IconButton(
                    constraints: BoxConstraints.loose(const Size(32, 32)),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                      widget.onRate(rating);
                    },
                    icon: Icon(index < rating ? Icons.star : Icons.star_border,
                        color: mainColor))),
          ),
          const SizedBox(width: 8),
        ]));
  }
}

class RatingTextWidget extends StatelessWidget {
  final List<String> words;
  final int rating;

  const RatingTextWidget(
      {super.key, required this.words, required this.rating});

  @override
  Widget build(BuildContext context) {
    var mainColor = rating > 0
        ? wordColor[rating - 1]
        : Theme.of(context).textTheme.bodyLarge!.color;
    return Center(
        child: Text(rating > 0 ? words[rating - 1] : "",
            style: TextStyle(color: mainColor)));
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

  const CourseReviewEditorPage({super.key, this.arguments});

  @override
  CourseReviewEditorPageState createState() => CourseReviewEditorPageState();
}

class CourseReviewEditorPageState extends State<CourseReviewEditorPage> {
  final CourseReviewEditorText review = CourseReviewEditorText.newInstance();

  /// Whether the send button is enabled
  final bool _canSend = true;

  bool _isFullscreen = false;
  bool _isModify = false;
  bool _justExitedFullscreen = false;

  late String _title;
  late CourseGroup _courseGroup;

  PostInterceptor? _interceptor;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _interceptor = widget.arguments?['interceptor'];
    _courseGroup = widget.arguments!['course_group'];
    _title =
        widget.arguments!['title'] ?? S.of(context).forum_post_enter_content;
    _isModify = widget.arguments!['modify'] ?? false;

    // When modifying, do not copy
    if (_isModify) {
      if (widget.arguments!.containsKey('initial_content') &&
          widget.arguments!['initial_content'] is CourseReviewEditorText) {
        review.copyValuesFrom(
            widget.arguments!['initial_content'] as CourseReviewEditorText);
      }
    } else {
      review.addListener(() {
        context
            .read<ForumProvider>()
            .courseReviewEditorCache[_courseGroup.code]!
            .copyValuesFrom(review);
      });
      if (context
          .read<ForumProvider>()
          .courseReviewEditorCache
          .containsKey(_courseGroup.code)) {
        review.copyValuesFrom(context
            .read<ForumProvider>()
            .courseReviewEditorCache[_courseGroup.code]!);
      } else {
        context
                .read<ForumProvider>()
                .courseReviewEditorCache[_courseGroup.code] =
            CourseReviewEditorText.newInstance();
      }
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

    bool focusContentFlag = false;
    if (_justExitedFullscreen) {
      _justExitedFullscreen = false;
      focusContentFlag = true;
    }
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
              onPressed: () => setState(() {
                    _isFullscreen = !_isFullscreen;
                    if (!_isFullscreen) {
                      // Set flag to auto focus the content instead of the title
                      _justExitedFullscreen = true;
                    }
                  })),
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: PlatformX.isMaterial(context)
                ? const Icon(Icons.send)
                : const Icon(CupertinoIcons.paperplane),
            onPressed: _canSend ? () async => _sendDocument() : null,
          ),
        ],
      ),
      body: SafeArea(
          bottom: false,
          child: Padding(
              padding: const EdgeInsets.all(8),
              child: CourseReviewEditorWidget(
                  fullscreen: _isFullscreen,
                  focusContent: focusContentFlag,
                  courseGroup: _courseGroup,
                  review: review))),
    );
  }

  Future<void> _sendDocument() async {
    if (!review.isValid()) return;

    if ((await _interceptor?.call(context, review)) ?? true) {
      Navigator.pop<CourseReviewEditorText>(context, review);
    }
  }
}
