import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/quiz_answer.dart';
import 'package:dan_xi/model/opentreehole/quiz_question.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OTQuizWidget extends StatefulWidget {
  @override
  OTQuizWidgetState createState() => OTQuizWidgetState();

  const OTQuizWidget({super.key});
}

class OTQuizWidgetState extends State<OTQuizWidget> {
  int questionIndex = -1;
  late List<QuizQuestion>? questions;
  List<QuizAnswer> answers = [];

  @override
  Widget build(BuildContext context) {
    if (questionIndex >= 0 && questions != null) {
      final elapsed = UniqueKey();
      final questionWidget = QuestionWidget(
          key: elapsed,
          question: questions![questionIndex],
          answerCallback: (ans) {
            answers.add(QuizAnswer(ans, questions![questionIndex].id!));
            setState(() {
              questionIndex++;
            });
          });

      return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) {
            final inAnimation =
            Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
                .animate(animation);
            final outAnimation =
            Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0))
                .animate(animation);

            if (child.key == ValueKey(elapsed)) {
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
            };
          },
          child: questionWidget);
    }

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
                  setState(() {
                    questionIndex = 0;
                  });
                },
                child: Text(S.of(context).start_quiz),
              ),
            ),
          ],
        ),
      ),
    );
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

    return Center(
        child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(children: [
                    RoundChip(
                        label: "单选",
                        color: Color(
                            SettingsProvider.getInstance().primarySwatch)),
                    Text(widget.question.question!, style: largerText),
                  ]),
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
