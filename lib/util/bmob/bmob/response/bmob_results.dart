import 'package:json_annotation/json_annotation.dart';

//此处与类名一致，由指令自动生成代码
part 'bmob_results.g.dart';

@JsonSerializable()
class BmobResults {
  List<dynamic>? results;
  int? count;

  BmobResults();

  //此处与类名一致，由指令自动生成代码
  factory BmobResults.fromJson(Map<String, dynamic> json) =>
      _$BmobResultsFromJson(json);

  //此处与类名一致，由指令自动生成代码
  Map<String, dynamic> toJson() => _$BmobResultsToJson(this);
}
