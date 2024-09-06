import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/quiz_answer.dart';
import 'package:dan_xi/model/forum/quiz_question.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter/material.dart';

enum OTQuizDisplayTypes {
  WELCOME_PAGE,
  FINISHED,
  FINISHED_WITH_ERRORS,
  ONGOING
}

class OTQuizWidget extends StatefulWidget {
  final void Function() successCallback;

  @override
  OTQuizWidgetState createState() => OTQuizWidgetState();

  const OTQuizWidget({super.key, required this.successCallback});
}

class OTQuizWidgetState extends State<OTQuizWidget> {
  // Prev question index is for determining the animation direction
  int questionIndex = 0, prevQuestionIndex = 0;
  int displayIndex = 1, displayTotalIndex = 1;
  late List<QuizQuestion>? questions;
  late int version;
  late List<int>? indexes;
  List<QuizAnswer>? answers;
  OTQuizDisplayTypes displayType = OTQuizDisplayTypes.WELCOME_PAGE;

  int _getIncorrectCount() =>
      questions!.map((e) => e.correct ? 0 : 1).reduce((value, e) => value + e);

  Widget _buildWelcomePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 256),
                child: Image.asset("assets/graphics/ot_logo.png"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(S.of(context).quiz_not_answered,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  PlatformTextButton(
                    child: Text(S.of(context).community_convention),
                    onPressed: () => BrowserUtil.openUrl(
                        "https://www.fduhole.com/doc", context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PlatformElevatedButton(
                padding: const EdgeInsets.all(20.0),
                onPressed: () async {
                  final result = await ForumRepository.getInstance()
                      .getPostRegisterQuestions();
                  questions = result.$1;
                  version = result.$2;
                  if (questions != null) {
                    indexes =
                        List.generate(questions!.length, (index) => index);
                    answers =
                        questions!.map((e) => QuizAnswer(null, e.id)).toList();
                    setState(() {
                      questionIndex = 0;
                      displayIndex = 1;
                      displayTotalIndex = questions!.length;
                      displayType = OTQuizDisplayTypes.ONGOING;
                    });
                  }
                },
                child: Text(S.of(context).start_quiz),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedPage(bool hasErrors) {
    final button = hasErrors
        ? PlatformElevatedButton(
            padding: const EdgeInsets.all(20.0),
            onPressed: () {
              setState(() {
                // Find the first incorrect question
                questionIndex = questions!.indexWhere((e) => !e.correct);
                displayIndex = 1;
                displayTotalIndex = _getIncorrectCount();
                displayType = OTQuizDisplayTypes.ONGOING;
              });
            },
            child: Text(S.of(context).redo_incorrect_questions),
          )
        : PlatformElevatedButton(
            padding: const EdgeInsets.all(20.0),
            onPressed: () {
              widget.successCallback();
            },
            child: Text(S.of(context).enter_forum),
          );

    final text = hasErrors
        ? S.of(context).quiz_has_errors(_getIncorrectCount())
        : S.of(context).quiz_completed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 256),
                child: Image.asset("assets/graphics/ot_logo.png"),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(text, textAlign: TextAlign.center)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: button,
            ),
          ],
        ),
      ),
    );
  }

  void submitAnswer(bool advanceForward, List<String>? ans) async {
    if (ans != null) {
      answers![questionIndex].answer = ans;
    }

    if (advanceForward) {
      // Find next incorrect question
      do {
        questionIndex++;
      } while (questionIndex < questions!.length &&
          questions![questionIndex].correct);

      displayIndex++;
    } else {
      // Back to previous
      final questionIndexTmp = questionIndex;
      do {
        questionIndex--;
      } while (questionIndex >= 0 && questions![questionIndex].correct);

      // No previous, then go back to the original question
      if (questionIndex < 0) {
        questionIndex = questionIndexTmp;
      } else {
        displayIndex--;
      }
    }

    // If all questions are answered
    if (questionIndex < questions!.length) {
      setState(() {});
      return;
    } else {
      final errorList =
          await ForumRepository.getInstance().submitAnswers(answers!, version);

      // Have trouble submitting
      if (errorList == null) {
        return;
      }

      if (errorList.isEmpty) {
        setState(() {
          displayType = OTQuizDisplayTypes.FINISHED;
        });
      } else {
        for (var elem in questions!) {
          elem.correct = !errorList.contains(elem.id);
        }

        // Clear wrong answers
        for (var elem in answers!) {
          if (errorList.contains(elem.id)) {
            elem.answer = null;
          }
        }

        setState(() {
          displayType = OTQuizDisplayTypes.FINISHED_WITH_ERRORS;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (displayType) {
      case OTQuizDisplayTypes.WELCOME_PAGE:
        return _buildWelcomePage();
      case OTQuizDisplayTypes.FINISHED:
        return _buildFinishedPage(false);
      case OTQuizDisplayTypes.FINISHED_WITH_ERRORS:
        return _buildFinishedPage(true);
      case OTQuizDisplayTypes.ONGOING:
        final questionWidget = QuestionWidget(
            key: ValueKey(questionIndex),
            question: questions![questionIndex],
            answerCallback: submitAnswer,
            initialSelection: answers![questionIndex].answer,
            progressHint: "$displayIndex / $displayTotalIndex");

        bool isForward = questionIndex > prevQuestionIndex;
        prevQuestionIndex = questionIndex;
        return AnimatedSwitcher(
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              final inAnimation =
                  Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .animate(animation);
              final outAnimation = Tween<Offset>(
                      begin: const Offset(-1.0, 0.0), end: Offset.zero)
                  .animate(animation);

              if (child.key == ValueKey(questionIndex)) {
                return ClipRect(
                  child: SlideTransition(
                    position: isForward ? inAnimation : outAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: child,
                    ),
                  ),
                );
              } else {
                return ClipRect(
                  child: SlideTransition(
                    position: isForward ? outAnimation : inAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: child,
                    ),
                  ),
                );
              }
            },
            child: questionWidget);
    }
  }
}

class QuestionWidget extends StatefulWidget {
  final QuizQuestion question;
  final String? progressHint;
  final List<String>? initialSelection;

  // True to jump to next question, false to return to previous
  final void Function(bool, List<String>?) answerCallback;

  const QuestionWidget(
      {super.key,
      required this.question,
      required this.answerCallback,
      this.initialSelection,
      this.progressHint});

  @override
  QuestionWidgetState createState() => QuestionWidgetState();
}

class QuestionWidgetState extends State<QuestionWidget> {
  ScrollController optionsScrollController = ScrollController();

  List<bool> selectionState = [];
  bool multiSelect = false;
  static const labelChars = "ABCDEFGH";

  void resetState() {
    if (widget.initialSelection == null) {
      selectionState = List.filled(widget.question.options!.length, false);
    } else {
      // This isn't a performant approach, but since the length is small, it's OK
      selectionState = widget.question.options!
          .map((e) => widget.initialSelection!.contains(e))
          .toList();
    }
    // TODO: handle more possible types
    multiSelect = widget.question.type == "multi-selection";
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  @override
  void didUpdateWidget(covariant QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    resetState();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options!;
    const largerText = TextStyle(fontSize: 16);
    // Since the questions don't have i18n, I believe it isn't necessary to have a i18n here
    final typeField = multiSelect ? "多选" : "单选";

    return Center(
        child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.progressHint != null) Text(widget.progressHint!),
                  Text.rich(TextSpan(
                    children: <InlineSpan>[
                      WidgetSpan(
                          child: RoundChip(
                              label: typeField,
                              color: Color(SettingsProvider.getInstance()
                                  .primarySwatch))),
                      const TextSpan(text: "  "),
                      TextSpan(
                          text: widget.question.question!, style: largerText),
                    ],
                  )),
                  // Take up all remaining space in the middle
                  Expanded(
                      child: ListView.builder(
                          addAutomaticKeepAlives: true,
                          itemCount: options.length,
                          controller: optionsScrollController,
                          itemBuilder: (ctx, index) => OptionWidget(
                              active: selectionState[index],
                              label: labelChars[index],
                              content: options[index],
                              tapCallback: () {
                                setState(() {
                                  if (multiSelect) {
                                    // Revert if multi-selection
                                    selectionState[index] =
                                        !selectionState[index];
                                  } else {
                                    // We still have to set this to make the animation play
                                    selectionState =
                                        List.filled(options.length, false);
                                    selectionState[index] = true;
                                    // Submit answer and advance to next
                                    widget
                                        .answerCallback(true, [options[index]]);
                                  }
                                });
                              }))),
                  if (multiSelect)
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          PlatformElevatedButton(
                            padding: const EdgeInsets.all(20.0),
                            onPressed: () {
                              // Discard and return to previous
                              widget.answerCallback(false, null);
                            },
                            child: Text(S.of(context).prev_question,
                                style: largerText),
                          ),
                          PlatformElevatedButton(
                            padding: const EdgeInsets.all(20.0),
                            onPressed: () {
                              // Submit answer and advance to next
                              final answers =
                                  Iterable<int>.generate(options.length)
                                      .toList()
                                      .filter((e) => selectionState[e])
                                      .map((e) => options[e]);
                              if (answers.isNotEmpty) {
                                widget.answerCallback(true, answers.toList());
                              }
                            },
                            child: Text(S.of(context).next_question,
                                style: largerText),
                          )
                        ])
                  else
                    // We only need a discard if not multi-select
                    PlatformElevatedButton(
                      padding: const EdgeInsets.all(20.0),
                      onPressed: () {
                        // Discard and return to previous
                        widget.answerCallback(false, null);
                      },
                      child:
                          Text(S.of(context).prev_question, style: largerText),
                    )
                ])));
  }
}

class OptionWidget extends StatelessWidget {
  final bool active;
  final String label;
  final String content;
  final void Function() tapCallback;

  const OptionWidget(
      {super.key,
      required this.active,
      required this.label,
      required this.tapCallback,
      required this.content});

  @override
  Widget build(BuildContext context) {
    final highlightColor = Color(SettingsProvider.getInstance().primarySwatch);

    return GestureDetector(
        onTap: tapCallback,
        child: ListTile(
          leading: AnimatedContainer(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border:
                  Border.all(color: Theme.of(context).highlightColor, width: 2),
              shape: BoxShape.circle,
              color: active ? highlightColor : Colors.transparent,
            ),
            duration: const Duration(milliseconds: 100),
            child: Center(
                child: Text(label, style: const TextStyle(fontSize: 12))),
          ),
          title: Text(content),
        ));
  }
}
