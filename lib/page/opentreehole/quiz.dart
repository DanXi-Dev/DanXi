import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/quiz_answer.dart';
import 'package:dan_xi/model/opentreehole/quiz_question.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
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
  int questionIndex = 0;
  late List<QuizQuestion>? questions;
  late List<int>? indexes;
  List<QuizAnswer>? answers;
  OTQuizDisplayTypes displayType = OTQuizDisplayTypes.WELCOME_PAGE;

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
                        "https://www.fduhole.com/#/licence", context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PlatformElevatedButton(
                padding: const EdgeInsets.all(20.0),
                onPressed: () async {
                  questions = await OpenTreeHoleRepository.getInstance()
                      .getPostRegisterQuestions();
                  if (questions != null) {
                    indexes =
                        List.generate(questions!.length, (index) => index);
                    answers =
                        questions!.map((e) => QuizAnswer(null, e.id)).toList();
                    setState(() {
                      questionIndex = 0;
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
                questionIndex = 0;
                displayType = OTQuizDisplayTypes.ONGOING;
              });
            },
            child: const Text("重做错题"),
          )
        : PlatformElevatedButton(
            padding: const EdgeInsets.all(20.0),
            onPressed: () {
              widget.successCallback();
            },
            child: const Text("进入树洞"),
          );

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
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("恭喜完成测试", textAlign: TextAlign.center)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: button,
            ),
          ],
        ),
      ),
    );
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
            answerCallback: (ans) async {
              answers![questionIndex].answer = ans;

              do {
                questionIndex++;
              } while (questionIndex < questions!.length &&
                  questions![questionIndex].correct);

              // If all questions are answered
              if (questionIndex < questions!.length) {
                setState(() {});
                return;
              } else {
                final errorList = await OpenTreeHoleRepository.getInstance()
                    .submitAnswers(answers!);

                // Have trouble submitting
                if (errorList == null) {
                  return;
                }

                if (errorList.isEmpty) {
                  setState(() {
                    displayType = OTQuizDisplayTypes.FINISHED;
                  });
                } else {
                  for (var ques in questions!) {
                    ques.correct = !errorList.contains(ques.id);
                  }

                  setState(() {
                    displayType = OTQuizDisplayTypes.FINISHED_WITH_ERRORS;
                  });
                }
              }
            });

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
                    position: inAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: child,
                    ),
                  ),
                );
              } else {
                return ClipRect(
                  child: SlideTransition(
                    position: outAnimation,
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
  final void Function(List<String>) answerCallback;

  const QuestionWidget(
      {super.key, required this.question, required this.answerCallback});

  @override
  QuestionWidgetState createState() => QuestionWidgetState();
}

class QuestionWidgetState extends State<QuestionWidget> {
  List<bool> selectionState = [];
  bool multiSelect = false;
  static const labelChars = "ABCDEFGH";

  void resetState() {
    selectionState = List.filled(widget.question.options!.length, false);
    // TODO: handle more possible types
    multiSelect = widget.question.type == "multi-selection";
  }

  @override
  void initState() {
    // TODO: implement initState
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
    // Since the questions don't have locales, it isn't necessary to have a locale here
    final typeField = multiSelect ? "多选" : "单选";

    return Center(
        child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  Column(children: [
                    ...Iterable<int>.generate(options.length)
                        .map((index) => OptionWidget(
                            active: selectionState[index],
                            label: labelChars[index],
                            content: options[index],
                            tapCallback: () {
                              setState(() {
                                if (!multiSelect) {
                                  selectionState =
                                      List.filled(options.length, false);
                                  selectionState[index] = true;
                                } else {
                                  // Revert if multi-selection
                                  selectionState[index] =
                                      !selectionState[index];
                                }
                              });
                            }))
                  ]),
                  PlatformElevatedButton(
                    padding: const EdgeInsets.all(20.0),
                    onPressed: () {
                      final answers = Iterable<int>.generate(options.length)
                          .toList()
                          .filter((e) => selectionState[e])
                          .map((e) => options[e]);
                      if (answers.isNotEmpty) {
                        widget.answerCallback(answers.toList());
                      }
                    },
                    child: Text(S.of(context).next, style: largerText),
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
              color: active ? highlightColor : Theme.of(context).primaryColor,
            ),
            duration: const Duration(milliseconds: 100),
            child: Center(
                child: Text(label, style: const TextStyle(fontSize: 12))),
          ),
          title: Text(content),
        ));
  }
}
