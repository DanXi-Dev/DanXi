import 'package:json_annotation/json_annotation.dart';

part 'quiz_answer.g.dart';

// Represents a question in the quiz popped out after register
@JsonSerializable()
class QuizAnswer {
  List<String>? answer;
  int? id;

  factory QuizAnswer.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAnswerToJson(this);

  QuizAnswer(this.answer, this.id);
}
