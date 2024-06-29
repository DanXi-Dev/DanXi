import 'package:json_annotation/json_annotation.dart';

part 'quiz_question.g.dart';

// Represents a question in the quiz popped out after register
@JsonSerializable()
class QuizQuestion {
  String? analysis;
  List<String>? answer;
  String? group;
  int? id;
  List<String>? options;
  String? question;
  String? type;

  // Client-side info, disable serialization
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool correct = false;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);

  QuizQuestion(this.analysis, this.answer, this.group, this.id, this.options,
      this.question, this.type);
}
